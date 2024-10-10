import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/download_lib/download_util.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_utils.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final DownloadMgr downloadMgr = DownloadMgr();
final DesktopDownloadMgr desktopDownloadMgr = DesktopDownloadMgr();
final DownLoadQueue _downLoadQueue = DownLoadQueue();

class DownloadMgr {
  final String? savePath;

  DownloadMgr({this.savePath = 'download'});

  String? _appDocumentRootPath;

  String get appDocumentRootPath => _appDocumentRootPath ?? '';

  String? _appCacheRootPath;

  String get appCacheRootPath => _appCacheRootPath ?? '';
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    int tryTime = 5;
    while (tryTime > 0) {
      _appDocumentRootPath =
          "${(await getApplicationDocumentsDirectory()).path}/$savePath";
      _appCacheRootPath = (await getTemporaryDirectory()).path;
      try {
        final tempCache = objectMgr.localStorageMgr
            .read<String>(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
        if (tempCache != null) {
          _cacheSubMap = jsonDecode(tempCache).cast<String, String>();
        }
        _isInit = true;
        return;
      } catch (e) {
        await objectMgr.localStorageMgr
            .remove(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
        _cacheSubMap.clear();
      } finally {
        Future.delayed(const Duration(milliseconds: 100));
        tryTime--;
      }
    }
  }

  Future<String?> downloadFile(
    String downloadUrl, {
    Duration timeout = const Duration(seconds: 60),
    int? mini,
    CancelToken? cancelToken,
    int priority = 0,
    Function(int bytes, int totalBytes)? onReceiveProgress,
  }) async {
    await init();
    return await _downLoadQueue.downloadQueue(
      downloadUrl,
      priority: priority,
      cancelToken: cancelToken,
      mini: mini,
      timeout: timeout,
      onReceiveProgress: onReceiveProgress,
    );
  }

  clearTmpCacheFile(String finalDownloadUrl) async {}

  Future<void> updateCacheSubValue(
    String? key,
    String? value, {
    bool isfinal = false,
  }) async {
    if (key == null || value == null) return;
    key = _getRelativePath(key);
    value = _getRelativePath(value);
    if (isfinal) {
      _cacheSubMap[value] = key;
      pdebug("TmpCacheFile updateCacheSubValue: 3->$key 2-> $value");
    } else {
      _cacheSubMap[key] = value;
      pdebug("TmpCacheFile updateCacheSubValue: 2->$key 1-> $value");
    }
    await objectMgr.localStorageMgr.write(
      LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE,
      jsonEncode(_cacheSubMap),
    );
  }

  Map<String, String> _cacheSubMap = <String, String>{};

  final List<String> _subList = [];

  Future<String> getTmpCachePath(
    String sourceFilePath, {
    String? sub,
    bool create = true,
  }) async {
    sub = sub ?? 'default';
    if (sub.isNotEmpty) {
      if (sub.startsWith('/')) sub = sub.substring(1);
    }

    String releativePath = _getRelativePath(sourceFilePath);

    String tmpPath = '$_appCacheRootPath/tmp'
        '/$sub'
        "/$releativePath";
    await DYio.mkDir(p.dirname(tmpPath));
    if (create) {
      await File(tmpPath).create(recursive: true);
    }

    if (!_subList.contains(tmpPath)) _subList.add(tmpPath);
    return tmpPath;
  }

  String _getRelativePath(String downloadUrl) {
    if (downloadUrl.isEmpty) {
      return '';
    }
    Uri uri = Uri.parse(downloadUrl);
    String uriPath = uri.path;
    uriPath = uriPath.replaceAll('$_appCacheRootPath/', '');
    uriPath = uriPath.replaceAll('$_appCacheRootPath', '');
    uriPath = uriPath.replaceAll('$_appDocumentRootPath/', '');
    uriPath = uriPath.replaceAll('$_appDocumentRootPath', '');
    if (uriPath.startsWith('/')) uriPath = uriPath.substring(1);
    return uriPath;
  }

  String getSavePath(String downloadUrl, {int? mini}) {
    if (downloadUrl.isEmpty) {
      return '';
    }

    if (mini != null) {
      downloadUrl = _getMiniFilePath(downloadUrl, mini);
    }

    return "$_appDocumentRootPath/${_getRelativePath(downloadUrl)}";
  }

  String _getMiniFilePath(String filePath, int mini) {
    String fileName = p.basenameWithoutExtension(filePath);
    if (!fileName.contains('_$mini')) {
      // 获取文件扩展名
      String extension = p.extension(filePath);
      // 获取文件的目录路径
      String directory = p.dirname(filePath);
      // 重命名文件名（不更改扩展名）
      String newFileName = '${fileName}_$mini';
      // 构造新的完整路径
      String newFilePath = p.join(directory, '$newFileName$extension');
      return newFilePath;
    }

    return filePath;
  }

  Future<Uri?> getDownloadUri(
    String url, {
    int? mini,
    bool shouldRedirect = false,
  }) async {
    if (url.isEmpty ||
        url.contains(appCacheRootPath) ||
        url.contains(appDocumentRootPath)) return null;
    // 如果是图片加工下
    if (url.contains('Image/') && mini != null) {
      url = shouldRedirect
          ? "$url?image_size=$mini"
          : _getMiniFilePath(url, mini);
    }
    Uri? uri = await serversUriMgr.exChangeKiwiUrl(
      url,
      shouldRedirect ? serversUriMgr.download2Uri : serversUriMgr.download1Uri,
    );

    final video_http_server_port = Config().video_http_server_port;
    if (video_http_server_port > 0 &&
        uri != null &&
        uri.path.contains('.m3u8')) {
      uri = uri.replace(port: video_http_server_port);
    }

    return uri;
  }

  bool _checkFileExistsSync(String? fullUrl) {
    return fullUrl != null &&
        fullUrl.isNotEmpty &&
        File(fullUrl).existsSync() &&
        File(fullUrl).lengthSync() > 0;
  }

  String? checkLocalFile(String url, {int? mini}) {
    if (url.isEmpty) return null;
    if (mini == null && _checkFileExistsSync(url)) return url;
    String? savePath = getSavePath(url, mini: mini);
    if (_checkFileExistsSync(savePath)) return savePath;
    return null;
  }
}

class DesktopDownloadMgr extends DownloadMgr {
  final desktopDownloadsDirectory = Directory(
    '${Directory('/Users/${Platform.environment['USER'] ?? Platform.environment['USERNAME']}').path}/Downloads',
  );

  Future<void> desktopDownload(Message message, BuildContext context) async {
    Toast.showToast(localized(downloadingFile));
    String url = getMediaMessagePath(message);
    var str = await cacheMediaMgr.downloadMedia(url,
        timeout: const Duration(seconds: 500));

    if (str == null) {
      Toast.showToast(localized(failedToDownload));
      return;
    }

    final File sourceFile = File(str);
    List<int> bytes = await sourceFile.readAsBytes();
    String fileName = "";
    if (message.typ == messageTypeFile) {
      MessageFile messageFile =
          message.decodeContent(cl: MessageFile.creator());
      fileName = messageFile.file_name;
    } else {
      fileName =
          "HeyTalk Media ${formatTimestamp(DateTime.now().millisecondsSinceEpoch)}${p.extension(url)}";
    }

    try {
      int counter = 0;

      while (true) {
        String destinationFilePath = addCounterToPath(
          '${desktopDownloadsDirectory.path}/$fileName',
          counter,
        );

        final File destinationFile = File(destinationFilePath);

        if (!await destinationFile.exists()) {
          await destinationFile.writeAsBytes(bytes);
          break;
        }
        counter++;
      }
      openDownloadDir(fileName);
    } catch (e) {
      pdebug(e);
      rethrow;
    }
    Toast.showToast(
      localized(fileDownloaded),
      duration: const Duration(milliseconds: 2500),
    );
  }

  Future<void> openDownloadDir(String filePath) async {
    const MethodChannel methodChannel = MethodChannel('desktopAction');
    final bool fileExist = await methodChannel.invokeMethod(
      'openDownloadDir',
      {'downloadPath': '${desktopDownloadsDirectory.path}/$filePath'},
    );
    if (!fileExist) {
      Toast.showToast(
        localized(fileNotExist),
        duration: const Duration(milliseconds: 2500),
      );
    }
  }

  String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    String formattedDate =
        "${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} at ${_pad(dateTime.hour)}.${_pad(dateTime.minute)}.${_pad(dateTime.second)}";

    return formattedDate;
  }

  String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  void desktopSaveTo(
    String fileName,
    List<int> bytes,
    BuildContext context,
  ) async {
    int counter = 0;

    while (true) {
      String destinationFilePath = addCounterToPath(
        '${desktopDownloadsDirectory.path}/$fileName',
        counter,
      );

      final File destinationFile = File(destinationFilePath);

      if (!await destinationFile.exists()) {
        await destinationFile.writeAsBytes(bytes);
        break;
      }
      counter++;
    }
    openDownloadDir(fileName);
  }
}
