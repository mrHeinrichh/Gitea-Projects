import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/transfer/complete_download_task_log.dart';
import 'package:jxim_client/transfer/donwload_injected.dart';
import 'package:jxim_client/transfer/download_channel.dart';
import 'package:jxim_client/transfer/download_channel_policy.dart';
import 'package:jxim_client/transfer/download_common.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/transfer/download_queue.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/transfer/log_util.dart';
import 'package:jxim_client/transfer/reusable_cancel_token.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

final DownloadMgr downloadMgrV2 =
    DownloadMgr(serversUriMgr, objectMgr.localStorageMgr, objectMgr.socketMgr);

class DownloadMgr {
  static const KEYWORD_URL = "//";
  static final LogUtil _log = LogUtil.module(LogModule.download);
  static final Lock initLock = Lock();
  static bool _isInit = false;
  final DownloadQueue _downloadQueue = DownloadQueue();

  final List<DownloadChannel> _allChannels = [];
  final List<DownloadChannel> _smallExclusiveChannels = [];
  final List<DownloadChannel> _sharedChannels = [];
  final List<DownloadChannel> _largeExclusiveChannels = [];
  final List<DownloadChannel> _backgroundChannels = [];
  final List<DownloadChannel> _retryChannels = [];

  final DownloadMgrContext _context = DownloadMgrContext();

  DownloadMgr._internal();

  static final DownloadMgr _instance = DownloadMgr._internal();

  factory DownloadMgr(ServersUriMgr serversUriMgr,
      LocalStorageMgr localStorageMgr, SocketMgr socketMgr) {
    DownloadInjected.init(serversUriMgr, localStorageMgr, socketMgr);
    return _instance;
  }

  void init() {
    if (_isInit) {
      return;
    }

    initLock.synchronized(() async {
      if (_isInit) {
        return;
      }

      DownloadConfig().initConfig();
      await LogUtil.init();
      _initChannelPullPolicy();
      _initChannel();
      _startChannel();

      _isInit = true;
      _log.report(
          "DownloadMgr init success, smallExclusiveChannel: ${_smallExclusiveChannels.length}, "
          "sharedChannel: ${_sharedChannels.length}, largeExclusiveChannel: ${_largeExclusiveChannels.length}, "
          "backgroundChannel: ${_backgroundChannels.length}, retryChannel: ${_retryChannels.length}");
    });
  }

  Future<DownloadResult> download(
    String pathOrUrl, {
    int? mini,
    CancelToken? cancelToken,
    bool allowRedirect = true,
    bool grab = false,
    ProgressCallback? onReceiveProgress,
    int? fileLen,
    DownloadType? downloadType,
    Duration? timeout,
    bool allowRangeDownload = true,
  }) async {
    if (pathOrUrl.isEmpty) {
      return Future.value(DownloadResult.fail(reason: "Path is empty"));
    }

    pathOrUrl = _genMiniImagePath(pathOrUrl, mini);
    var (origin, path, savePath) = _getOriginAndPath(pathOrUrl);

    var (exists, fullLocalPath) =
        await DownloadCommon().checkLocalFile(savePath);
    if (exists) {
      return Future(() => DownloadResult.success(fullLocalPath));
    }

    downloadType ??= _getDownloadType(mini, fileLen);
    DownloadTask task = DownloadTask(
        savePath,
        path,
        origin,
        allowRedirect,
        grab,
        DateTime.now().millisecondsSinceEpoch,
        onReceiveProgress,
        fullLocalPath,
        downloadType,
        _downloadQueue,
        timeout,
        allowRangeDownload);
    CancelToken reusableCancelToken = ReusableCancelToken(cancelToken, task);
    task.cancelToken = reusableCancelToken;

    return _doDownload(task);
  }

  String? getLocalPath(String pathOrUrl, {int? mini}) {
    if (File(pathOrUrl).existsSync()) {
      return pathOrUrl;
    }

    pathOrUrl = _genMiniImagePath(pathOrUrl, mini);
    final (_, __, savePath) = _getOriginAndPath(pathOrUrl);
    String localPath =
        "${AppPath.appDocumentRootPath}/${DownloadConfig().DOWNLOAD_DIR_NAME}/$savePath";
    return File(localPath).existsSync() ? localPath : null;
  }

  void onNetworkChange(bool open) {
    _context.networkOpen = open;
  }

  void onWeakNet(bool weakNet) {
    _context.weakNet = weakNet;
  }

  void onReloadConfig(String config) {
    DownloadConfig().reloadConfig(config);
  }

  void onClearCache() {
    LogUtil.onClearCache();
    DownloadConfig().onClearCache();
  }

  Future<DownloadResult> _doDownload(DownloadTask task) async {
    task = await _downloadQueue.addTask(task);
    _handleGrab(task);
    _log.info(
        "Add Download task success, taskID: ${task.simpleID}, downloadType: ${task.downloadType.name}");

    Future<DownloadResult> future = task.completer.future;
    if (task.timeout != null) {
      future = future.timeout(task.timeout!,
          onTimeout: () => DownloadResult.fail(reason: "Timeout"));
    }

    DownloadResult result = await future;

    _log.report(CompleteDownloadTaskLog.fromDownloadTask(
        task,
        _downloadQueue.length,
        DateTime.now().millisecondsSinceEpoch,
        result.reason));

    return Future.value(result);
  }

  _handleGrab(DownloadTask task) async {
    if (!task.grab) {
      return;
    }
    if (task.status != TaskStatus.waiting) {
      return;
    }

    TaskStatus? status;
    try {
      status = await task.waitStatusChanged().timeout(
            Duration(
                milliseconds: DownloadConfig().GRAB_TASK_WAIT_RUN_TIMEOUT_MS),
          );
    } on TimeoutException {
      // ignore
    }

    if (status != null) {
      return;
    }

    DownloadChannel? kickOutChannel;
    kickOutChannel = _largeExclusiveChannels
        .firstWhere((channel) => channel.canSoftKickOut());
    if (kickOutChannel == null) {
      _sharedChannels.firstWhere((channel) => channel.canSoftKickOut());
    }
    bool grabSuccess = kickOutChannel.grabTask(task, false);
    if (grabSuccess) {
      return;
    }

    DownloadChannel canForceGrabChannel = _allChannels
        .where((channel) =>
            channel.channelType == ChannelType.largeExclusive ||
            channel.channelType == ChannelType.smallFirstShared)
        .reduce((current, next) =>
            current.lastTaskRunTime > next.lastTaskRunTime ? current : next);
    canForceGrabChannel.grabTask(task, true);
  }

  (String?, String, String) _getOriginAndPath(String path) {
    if (path.contains(KEYWORD_URL)) {
      Uri uri = Uri.parse(path);
      return (
        uri.origin,
        uri.path.substring(1),
        "${uri.host.replaceAll(".", "_")}${uri.path}"
      );
    } else {
      return (null, path, path);
    }
  }

  String _genMiniImagePath(String path, int? mini) {
    if (mini == null) {
      return path;
    }

    String fileName = p.basenameWithoutExtension(path);
    String extension = p.extension(path);
    String directory = p.dirname(path);
    String newFileName = '${fileName}_$mini';
    return p.join(directory, '$newFileName$extension');
  }

  DownloadType _getDownloadType(int? mini, int? fileLen) {
    if (mini != null) {
      return DownloadType.smallFile;
    }

    if (fileLen == null) {
      return DownloadType.largeFile;
    }
    return fileLen <= DownloadConfig().MAX_SMALL_FILE_LEN
        ? DownloadType.smallFile
        : DownloadType.largeFile;
  }

  void _initChannel() {
    _doAddChannel(
        ChannelType.smallExclusive,
        DownloadConfig().SMALL_EXCLUSIVE_CHANNEL_COUNT,
        DownloadConfig().SMALL_EXCLUSIVE_CELLULAR_CHANNEL_COUNT,
        _smallExclusiveChannels);

    _doAddChannel(
        ChannelType.smallFirstShared,
        DownloadConfig().SHARED_CHANNEL_COUNT,
        DownloadConfig().SHARED_CELLULAR_CHANNEL_COUNT,
        _sharedChannels);

    _doAddChannel(
        ChannelType.largeExclusive,
        DownloadConfig().LARGE_EXCLUSIVE_CHANNEL_COUNT,
        DownloadConfig().LARGE_EXCLUSIVE_CELLULAR_CHANNEL_COUNT,
        _largeExclusiveChannels);

    _doAddChannel(
        ChannelType.background,
        DownloadConfig().BACKGROUND_CHANNEL_COUNT,
        DownloadConfig().BACKGROUND_CELLULAR_CHANNEL_COUNT,
        _backgroundChannels);

    _doAddChannel(ChannelType.retry, DownloadConfig().RETRY_CHANNEL_COUNT,
        DownloadConfig().RETRY_CELLULAR_CHANNEL_COUNT, _retryChannels);
  }

  void _doAddChannel(ChannelType channelType, int channelCount,
      int cellularChannelCount, List<DownloadChannel> channels) {
    for (int i = 0; i < channelCount; i++) {
      DownloadChannel channel =
          DownloadChannel(i, channelType, i < cellularChannelCount);
      channels.add(channel);
    }
    _allChannels.addAll(channels);
  }

  void _initChannelPullPolicy() {
    DownloadChannel.registerPullPolicy(SmallExclusiveChannelPolicy());
    DownloadChannel.registerPullPolicy(SmallFirstSharedChannelPolicy());
    DownloadChannel.registerPullPolicy(LargeChannelPolicy());
    DownloadChannel.registerPullPolicy(BackgroundChannelPolicy());
    DownloadChannel.registerPullPolicy(RetryChannelPolicy());
  }

  void _startChannel() {
    for (DownloadChannel channel in _allChannels) {
      try {
        channel.pullTaskAndRun(_downloadQueue);
      } catch (e) {
        _log.error("Pull task err, $e");
      }
    }
  }
}

class DownloadMgrContext {
  bool weakNet = false;
  bool networkOpen = false;
  int downloadRate = 0;
  late NetType netType;
}

enum DownloadType { smallFile, largeFile, background }

enum NetType { wifi, cellular }
