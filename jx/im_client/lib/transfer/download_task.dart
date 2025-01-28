import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/transfer/donwload_injected.dart';
import 'package:jxim_client/transfer/download_common.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_queue.dart';
import 'package:jxim_client/transfer/log_util.dart';
import 'package:jxim_client/transfer/progress_callback_factory.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class _DownloadTaskContext {
  String? _decryptKey;
  final Completer<DownloadResult> _completer = Completer();
  int _retries = 0;
  bool _hasRedirect = false;
  TaskStatus _status = TaskStatus.waiting;
  final Lock _statusLock = Lock();
  final StreamController<TaskStatus> _statusChangedStreamController =
      StreamController();
  bool _isWeakNet = false;
  final List<int> _downloadStartTimes = [];
  final List<int> _downloadEndTimes = [];
  final List<int> _tryCosts = [];
  String? _channelName;
  int _receivedDataLen = 0;
  String? _lastErr;
  IOSink? _tempFileSink;
}

class DownloadTask {
  static const REDIRECT_STATUS_CODES = [
    HttpStatus.found,
    HttpStatus.notFound,
    HttpStatus.forbidden
  ];
  static const DOWNLOAD_SUCCESS_CODES = [
    HttpStatus.ok,
    HttpStatus.partialContent
  ];

  static final LogUtil _log = LogUtil.module(LogModule.download);
  static final Dio _dio = Dio();

  final String _id;
  final String _path;
  final String? _origin;
  late final CancelToken _cancelToken;
  final bool _allowRedirect;
  bool _grab;
  final int _createTime;
  final ProgressCallback? _onReceiveProgress;
  final String _localPath;
  final DownloadQueue _queue;
  final Duration? _timeout;
  DownloadType downloadType;
  late final int seq;
  final bool _allowRangeDownload;

  final _DownloadTaskContext _context = _DownloadTaskContext();

  String get id => _id;

  Completer<DownloadResult> get completer => _context._completer;

  TaskStatus get status => _context._status;

  String? get localPath => _localPath;

  bool get grab => _grab;

  bool get isWeakNet => _context._isWeakNet;

  int get createTime => _createTime;

  List<int> get downloadStartTimes => _context._downloadStartTimes;

  set channelName(String? name) => _context._channelName = name;

  String? get channelName => _context._channelName;

  int get fileLen => _context._receivedDataLen;

  String get simpleID => id.substring(id.lastIndexOf("/") + 1);

  int get retries => _context._retries;

  bool get hasRedirect => _context._hasRedirect;

  String? get lastErr => _context._lastErr;

  set retries(int r) => _context._retries = r;

  Duration? get timeout => _timeout;

  set cancelToken(CancelToken cancelToken) => _cancelToken = cancelToken;

  List<int> get tryCosts => _context._tryCosts;

  bool get allowRangeDownload => _allowRangeDownload;

  DownloadTask(
      this._id,
      this._path,
      this._origin,
      this._allowRedirect,
      this._grab,
      this._createTime,
      this._onReceiveProgress,
      this._localPath,
      this.downloadType,
      this._queue,
      this._timeout,
      this._allowRangeDownload);

  Future<void> run(Duration sendTimeout, Duration receiveTimeout) async {
    if (downloadType == DownloadType.smallFile) {
      sendTimeout = Duration(
          milliseconds: DownloadConfig().SMALL_FILE_DIO_SEND_TIMEOUT_MS);
      receiveTimeout = Duration(
          milliseconds: DownloadConfig().SMALL_FILE_DIO_RECEIVE_TIMEOUT_MS);
    }

    var (exists, _) = await DownloadCommon().checkLocalFile(_path);
    if (exists) {
      return;
    }

    _genDecryptKey();

    String downloadUrl = _genDownloadUrl();
    var (tempFile, oriFileLen, tempFileSink) = await _genTempFile();
    _context._tempFileSink = tempFileSink;
    _context._receivedDataLen = oriFileLen;
    _log.info("Start to download, tempFileLen: $oriFileLen");

    final Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    int? fileLen;
    bool rangeDownloadFinished = false;
    while (!rangeDownloadFinished) {
      int receivedDataLenBefore = _context._receivedDataLen;
      ProgressCallback progressCallback =
          ProgressCallbackFactory.newProgressCallback(
              _onReceiveProgress,
              stopwatch,
              _context._receivedDataLen,
              (isWeakNet) => _context._isWeakNet = isWeakNet,
              () => fileLen);

      Response<ResponseBody> response = await _dio.get(downloadUrl,
          options: Options(
              sendTimeout: sendTimeout,
              receiveTimeout: receiveTimeout,
              headers: {
                "Range":
                    'bytes=${_context._receivedDataLen}-${_context._receivedDataLen + DownloadConfig().RANGE_DOWNLOAD_LEN}'
              },
              responseType: ResponseType.stream,
              validateStatus: (status) => [
                    ...DOWNLOAD_SUCCESS_CODES,
                    ...REDIRECT_STATUS_CODES,
                    HttpStatus.requestedRangeNotSatisfiable
                  ].contains(status)),
          cancelToken: _cancelToken,
          onReceiveProgress: progressCallback);
      fileLen = _getFileLen(response);

      if (REDIRECT_STATUS_CODES.contains(response.statusCode) &&
          _allowRedirect &&
          !_context._hasRedirect) {
        _context._hasRedirect = true;
        await clean();
        return run(sendTimeout, receiveTimeout);
      }

      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable &&
          (fileLen == null || fileLen == _context._receivedDataLen)) {
        _log.info(
            "Get requestedRangeNotSatisfiable status code, will not continue download");
        break;
      }

      if (!DOWNLOAD_SUCCESS_CODES.contains(response.statusCode)) {
        _log.error(
            "Unexpected status code, taskID: $_id, statusCode: ${response.statusCode}, hasRedirect: ${_context._hasRedirect}, retries: ${_context._retries}");
        await updateStatuesWhenFail(
            "Unexpected status code(${response.statusCode})",
            allowRetry: !hasRedirect);
        await clean();
        return;
      }

      if (response.data == null) {
        _log.error("Response data is empty, id: $_id");
        await updateStatuesWhenFail("Response data is empty");
        await clean();
        return;
      }

      late StreamSubscription<Uint8List> subscription;
      subscription = response.data!.stream.listen((event) {
        subscription.pause();
        _log.info("Receive date(${event.length}), taskID: $simpleID");
        maybeDecrypt(event, _context._receivedDataLen);
        tempFileSink.add(event);
        _context._receivedDataLen += event.length;
        subscription.resume();
      });

      await subscription.asFuture();
      if (_context._receivedDataLen - receivedDataLenBefore >=
          DownloadConfig().RANGE_DOWNLOAD_LEN) {
        continue;
      }
      break;
    }

    await clean();
    await updateStatues(TaskStatus.succeeded);
    await _mvFile(tempFile, _localPath);
    _log.debug("Task complete success, $_id");
    completer.complete(DownloadResult.success(_localPath));
  }

  Future<bool> updateStatues(TaskStatus status) {
    return _context._statusLock.synchronized(() {
      if (_context._status == status) {
        return false;
      }
      _context._status = status;
      _context._statusChangedStreamController.add(_context._status);
      return true;
    }).then((value) => value);
  }

  handleErr(dynamic e) async {
    await clean();
    if (e is DioException && CancelToken.isCancel(e)) {
      _log.info("Download task canceled, taskID: $_id");
      await updateStatues(TaskStatus.pause);
    } else {
      _log.error("Download error, taskID: $_id, e: $e");
      await updateStatuesWhenFail("$e");
    }
  }

  Future<TaskStatus> waitStatusChanged() {
    return _context._statusChangedStreamController.stream.first;
  }

  bool isReady() {
    return TaskStatus.waiting == _context._status ||
        TaskStatus.pause == _context._status;
  }

  Future<void> prepareRetry() async {
    if (_context._status != TaskStatus.waitingRetry) {
      return;
    }

    if (_context._lastErr != null &&
        _context._lastErr!.contains("Connection closed")) {
      _context._retries = 0;
      await updateStatues(TaskStatus.waiting);
      _queue.broadcastTask(this);
      return;
    }

    List delays = DownloadConfig().DOWNLOAD_RETRY_TIME_DELAYS;
    int curDelay = delays[delays.length - 1];
    if (delays.length > _context._retries) {
      curDelay = delays[_context._retries - 1];
    }
    Future.delayed(Duration(milliseconds: curDelay), () async {
      await updateStatues(TaskStatus.waiting);
      _queue.broadcastTask(this);
    });
  }

  void dequeue() {
    _queue.removeTask(this);
  }

  int maybeDecrypt(Uint8List data, int startIndex) {
    if (_context._decryptKey == null) {
      return 0;
    }

    for (int i = 0; i < data.length; i++) {
      data[i] = data[i] ^
          _context._decryptKey!
              .codeUnitAt((i + startIndex) % _context._decryptKey!.length);
    }

    return startIndex + data.length;
  }

  void cancel() {
    _cancelToken.cancel();
  }

  void cancelGrab() {
    _grab = false;
  }

  Future<void> updateStatuesWhenFail(String err,
      {bool allowRetry = true}) async {
    _context._lastErr = err;
    _context._retries++;
    if (allowRetry &&
        (_context._retries <= DownloadConfig().DOWNLOAD_TASK_MAX_RETRIES ||
            DownloadConfig().DOWNLOAD_TASK_MAX_RETRIES == -1)) {
      await updateStatues(TaskStatus.waitingRetry);
    } else {
      await updateStatues(TaskStatus.failed);
      _log.info("Complete fail, $_id, ${_context._retries}");
      completer.complete(
          DownloadResult.fail(reason: "Maximum number of retries reached"));
    }
  }

  void recordDownloadStartTime() {
    _context._downloadStartTimes.add(DateTime.now().millisecondsSinceEpoch);
  }

  void recordDownloadEndTime() {
    _context._downloadEndTimes.add(DateTime.now().millisecondsSinceEpoch);
    if (_context._tryCosts.length <
        DownloadConfig().DOWNLOAD_TRY_COST_MAX_COUNT) {
      _context._tryCosts.add(
          _context._downloadEndTimes.last - _context._downloadStartTimes.last);
    }
  }

  Future<void> clean() async {
    try {
      await _context._tempFileSink?.close();
      _context._tempFileSink = null;
    } catch (e) {
      _log.error("Close file sink err, $e");
    }
  }

  String _genDownloadUrl() {
    if (_origin != null) {
      return "$_origin/$_path";
    }

    Uri? uri1 = DownloadInjected().serversUriMgr.download1Uri;
    if (uri1 == null) {
      throw Exception("download uri1 is null");
    }

    //
    Uri? uri2 = serversUriMgr.download2Uri ?? uri1;
    return _context._hasRedirect
        ? "${uri2.origin}/$_path"
        : "${uri1.origin}/$_path";
  }

  Future<(File, int, IOSink)> _genTempFile() async {
    String tempDirPath = (await getTemporaryDirectory()).path;
    String tempFilePath =
        "$tempDirPath/${DownloadConfig().DOWNLOAD_DIR_NAME}/$_path";
    File file = await DownloadCommon().createFile(tempFilePath);
    IOSink sink;
    bool rangeDownload = false;
    if (_allowRangeDownload &&
        (DownloadConfig().LARGE_FILE_RANGE_DOWNLOAD_ENABLE &&
                downloadType == DownloadType.largeFile ||
            DownloadConfig().BACKGROUND_FILE_RANGE_DOWNLOAD_ENABLE &&
                downloadType == DownloadType.background)) {
      sink = file.openWrite(mode: FileMode.append);
      rangeDownload = true;
    } else {
      sink = file.openWrite(mode: FileMode.write);
    }

    int fileLen = 0;
    if (rangeDownload && await file.exists()) {
      fileLen = await file.length();
    }
    return (file, fileLen, sink);
  }

  void _genDecryptKey() {
    if (_context._decryptKey != null) {
      return;
    }
    if (!_path.startsWith(DownloadConfig().ENCRYPT_FILE_PATH_KEYWORD)) {
      return;
    }

    int secondSlashIndex = _path.indexOf("/", _path.indexOf("/") + 1);
    int thirdSlashIndex = _path.indexOf("/", secondSlashIndex + 1);

    String keyIndexStr = _path.substring(secondSlashIndex + 1, thirdSlashIndex);
    int? keyIndex = int.tryParse(keyIndexStr);
    if (keyIndex == null) {
      pdebug("Not found encrypt key, _path: $_path");
      return;
    }

    List<String> assetList = Config().assert_list;
    if (keyIndex >= assetList.length) {
      pdebug(
          "Not found encrypt key, _path: $_path, asset_list_length: ${assetList.length}");
      return;
    }

    _context._decryptKey = assetList[keyIndex];
  }

  _mvFile(File file, String destPath) async {
    final dirPath = p.dirname(destPath);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.rename(destPath);
  }

  int? _getFileLen(Response response) {
    List<String>? contentRange = response.headers["content-range"];
    if (contentRange == null || contentRange.isEmpty) {
      return null;
    }

    String fileLenStr =
        contentRange[0].substring(contentRange[0].lastIndexOf("/") + 1);
    return int.parse(fileLenStr);
  }
}

class DownloadResult {
  final bool success;
  final String? localPath;
  final String? reason;

  DownloadResult(this.success, this.localPath, this.reason);

  DownloadResult.fail({this.reason})
      : success = false,
        localPath = null;

  DownloadResult.success(this.localPath)
      : success = true,
        reason = null;
}

enum TaskStatus { waiting, downloading, pause, waitingRetry, failed, succeeded }
