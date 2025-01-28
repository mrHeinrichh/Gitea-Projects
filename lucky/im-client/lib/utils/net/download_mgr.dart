import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/task/download_queue.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path_provider/path_provider.dart';

import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/fileUtils.dart';
import 'package:path/path.dart' as p;

final DownloadMgr downloadMgr = DownloadMgr();
final DesktopDownloadMgr desktopDownloadMgr = DesktopDownloadMgr();
final DownLoadQueue _downLoadQueue = DownLoadQueue();

class DownloadMgr {
  final _STICKER_VERSION = "_decode_${Config().sticker_version}";

  final String? savePath;

  DownloadMgr({this.savePath = 'download'});

  /// 本地缓存文件根目录
  String? _appDocumentRootPath;

  String get appDocumentRootPath => _appDocumentRootPath ?? '';

  /// 本地缓存根目录
  String? _appCacheRootPath;

  String get appCacheRootPath => _appCacheRootPath ?? '';
  bool _isInit = false;

  /// 从本地文本取得缓存文件列表
  Future<void> init() async {
    if (_isInit) return;
    int tryTime = 5;
    while (tryTime > 0) {
      _appDocumentRootPath =
          "${(await getApplicationDocumentsDirectory()).path}/$savePath";
      _appCacheRootPath = "${(await getTemporaryDirectory()).path}";
      try {
        final _tempCache = await objectMgr.localStorageMgr
            .read<String>(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
        if (_tempCache != null) {
          _cacheSubMap = jsonDecode(_tempCache).cast<String, String>();
          _cacheSubMap.forEach((key, value) {
            pdebug("TmpCacheFile key: $key value: $value");
          });
        }
        _isInit = true;
        return;
      } catch (e) {
        await objectMgr.localStorageMgr
            .remove<String>(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
        _cacheSubMap.clear();
      } finally {
        Future.delayed(const Duration(milliseconds: 100));
        tryTime--;
      }
    }
  }

  // 下载文件
  Future<String?> downloadFile(
    dynamic downloadUrl, {
    String? savePath,
    int timeoutSeconds = 60,
    int? mini,
    CancelToken? cancelToken,
    int priority = 0, // 任务优先级
    Function(int bytes, int totalBytes)? onReceiveProgress,
  }) async {
    await init();
    return await _downLoadQueue.downloadQueue(downloadUrl,
        priority: priority,
        cancelToken: cancelToken,
        savePath: savePath,
        mini: mini,
        timeoutSeconds: timeoutSeconds,
        onReceiveProgress: onReceiveProgress);
  }

  clearTmpCacheFile(String finalDownloadUrl) async {
    List<String> baseNameList = [];
    return;
    // 3->2
    String releativePath = getRelativePath(finalDownloadUrl);
    String findMiddleStr = _cacheSubMap[releativePath]!;
    if (findMiddleStr != null) {
      final File tmpEncFile = File(findMiddleStr);
      bool exist = await tmpEncFile.exists();
      if (exist) {
        await tmpEncFile.delete(recursive: true).catchError((_) => tmpEncFile);
        logMgr.logDownloadMgr.addMetrics(
            LogDownloadMsg(msg: "TmpCacheFile 清理cache路径文件: $findMiddleStr"));
        pdebug("TmpCacheFile 清理cache路径文件: $findMiddleStr");
      }
      baseNameList.add(p.basename(findMiddleStr));
    }
    _cacheSubMap.remove(releativePath);

    String findFirstStr = _cacheSubMap[findMiddleStr]!;
    if (findFirstStr != null) {
      final File tmpEncFile = File(findFirstStr);
      bool exist = await tmpEncFile.exists();
      if (exist) {
        await tmpEncFile.delete(recursive: true).catchError((_) => tmpEncFile);
        logMgr.logDownloadMgr.addMetrics(
            LogDownloadMsg(msg: "TmpCacheFile 清理cache路径文件: $findFirstStr"));
        pdebug("TmpCacheFile 清理cache路径文件: $findFirstStr");
      }

      baseNameList.add(p.basename(findFirstStr));
    }
    _cacheSubMap.remove(findMiddleStr);

    for (var subPath in _subList) {
      String baseName = p.basename(subPath);
      if (baseNameList.indexOf(baseName) != -1) {}
    }

    _subList.removeWhere((subPath) {
      String baseName = p.basename(subPath);
      bool include = baseNameList.indexOf(baseName) != -1;
      if (include) {
        final File tmpEncFile = File(subPath);
        bool exist = tmpEncFile.existsSync();
        if (exist) {
          tmpEncFile.deleteSync(recursive: true);
          logMgr.logDownloadMgr.addMetrics(
              LogDownloadMsg(msg: "TmpCacheFile 清理cache路径文件: $subPath"));
          pdebug("TmpCacheFile 清理cache路径文件: $subPath");
        }
      }
      return include;
    });
  }

  Future<void> updateCacheSubValue(String? key, String? value,
      {bool isfinal = false}) async {
    if (key == null || value == null) return;
    key = getRelativePath(key);
    value = getRelativePath(value);
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

  Map<String, String> _cacheSubMap = Map<String, String>();

  List<String> _subList = [];

  Future<String> getTmpCachePath(String sourceFilePath,
      {String? sub, bool create = true}) async {
    sub = sub ?? '';
    if (sub.isNotEmpty) {
      if (sub.contains('/')) sub = sub.replaceAll('/', '');
    }

    String releativePath = getRelativePath(sourceFilePath);

    String tmpPath = '$_appCacheRootPath/tmp'
            '/$sub' + //这里缓存聊天室id
        "/${releativePath}";
    if (_subList.indexOf(tmpPath) == -1) _subList.add(tmpPath);
    if (create) {
      await File(tmpPath).create(recursive: true);
    }
    return tmpPath;
  }

  // 获取相对路径
  String getRelativePath(String downloadUrl) {
    if (downloadUrl == null || downloadUrl.isEmpty) {
      return '';
    }
    Uri uri = Uri.parse(downloadUrl);
    String uriPath = uri.path;
    uriPath = uriPath.replaceAll('$_appDocumentRootPath/', '');
    uriPath = uriPath.replaceAll('$_appDocumentRootPath', '');
    if (uriPath.startsWith('/')) uriPath = uriPath.substring(1);
    return uriPath;
  }

  // 获取本地保存路径
  String getSavePath(String downloadUrl, {int? mini}) {
    if (downloadUrl == null || downloadUrl.isEmpty) {
      return '';
    }

    // 特殊处理----
    if (downloadUrl.endsWith('.tgs')) {
      if (!downloadUrl.endsWith("${_STICKER_VERSION}.tgs")) {
        downloadUrl = downloadUrl.replaceAll('.tgs', '${_STICKER_VERSION}.tgs');
      }
    }

    if (mini != null) {
      downloadUrl = _getMiniFilePath(downloadUrl, mini);
    }

    return "$_appDocumentRootPath/${getRelativePath(downloadUrl)}";
  }

  String _getMiniFilePath(String src, int mini) {
    if (!src.contains("_$mini")) {
      // 不同画质
      final extIdx = src.lastIndexOf('.');
      if (extIdx != -1) {
        return src.substring(0, extIdx) + '_$mini' + src.substring(extIdx);
      }
    }

    return src;
  }

  // 获取下载地址
  Future<Uri?> getDownloadUrl(String downloadUrl,
      {required bool shouldRedirect, required int? mini}) async {
    if (downloadUrl == null || downloadUrl.isEmpty) return null;
    String originUrl = downloadUrl;
    if (shouldRedirect) {
      if (mini != null && downloadUrl.contains('Image/')) {
        originUrl = "${downloadUrl}?image_size=${mini}";
      }
      final Uri? redirectUri = await serversUriMgr.exChangeKiwiUrl(
          originUrl, serversUriMgr.download2Uri);
      return redirectUri;
    } else {
      if (mini != null && downloadUrl.contains('Image/')) {
        originUrl = _getMiniFilePath(downloadUrl, mini);
      }
      final Uri? uri = await serversUriMgr.exChangeKiwiUrl(
          originUrl, serversUriMgr.download1Uri);
      return uri;
    }
  }

  // 也要判断大小
  bool checkFileExistsSync(String? fullUrl) {
    return fullUrl != null &&
        fullUrl.isNotEmpty &&
        File(fullUrl).existsSync() &&
        File(fullUrl).lengthSync() > 0;
  }

  // ============================= 全局下载工具函数 =============================

  String getCacheFilePath(String fileName, {String? sub}) {
    String path = '$_appCacheRootPath/tmp';
    if (sub != null) {
      path = '$path/$sub';
    }
    return '$path/$fileName';
  }

  Future<bool> checkCacheFile(
    String fileName, {
    String? sub,
  }) async {
    final File file = File(fileName);
    return await file.exists();
  }

// Future<void> clearTmpCacheFile(
//     String fileName, {
//       String? sub,
//     }) async {
//   bool exist = await checkCacheFile(fileName, sub: sub);
//   if (exist) {
//     downloadMgr.clearTmpCacheFile(getCacheFilePath(fileName, sub: sub));
//   }
// }
}

class DesktopDownloadMgr extends DownloadMgr {
  final desktopDownloadsDirectory = Directory(
      '${Directory('/Users/${Platform.environment['USER'] ?? Platform.environment['USERNAME']}').path}/Downloads');

  Future<void> desktopDownload(Message message, BuildContext context) async {
    Toast.showToast(localized(downloadingFile));
    String url = getMediaMessagePath(message);
    var _str = await cacheMediaMgr.downloadMedia(url, timeoutSeconds: 500);

    if (_str == null) {
      Toast.showToast(localized(failedToDownload));
      return;
    }

    final File sourceFile = File(_str);
    List<int> bytes = await sourceFile.readAsBytes();
    String fileName = "";
    if (message.typ == messageTypeFile) {
      MessageFile messageFile =
          message.decodeContent(cl: MessageFile.creator());
      fileName = "${messageFile.file_name}";
    } else {
      fileName =
          "HeyTalk Media ${formatTimestamp(DateTime.now().millisecondsSinceEpoch)}${p.extension(url)}";
    }

    try {
      int counter = 0;

      while (true) {
        String destinationFilePath = addCounterToPath(
            '${desktopDownloadsDirectory.path}/$fileName', counter);

        final File destinationFile = File(destinationFilePath);

        if (!await destinationFile.exists()) {
          await destinationFile.writeAsBytes(bytes);
          break;
        }
        counter++;
      }
      openDownloadDir('$fileName', context);
    } catch (e) {
      pdebug(e);
      throw (e);
    }
    Toast.showToast(
      localized(fileDownloaded),
      duration: const Duration(milliseconds: 2500),
    );
  }

  Future<void> openDownloadDir(String filePath, BuildContext context) async {
    final MethodChannel methodChannel = const MethodChannel('desktopAction');
    final bool fileExist = await methodChannel.invokeMethod(
      'openDownloadDir',
      {'downloadPath': '${desktopDownloadsDirectory.path}/$filePath'},
    );
    if (!fileExist)
      Toast.showToast(
        localized(fileNotExist),
        duration: const Duration(milliseconds: 2500),
      );
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
      String fileName, List<int> bytes, BuildContext context) async {
    int counter = 0;

    while (true) {
      String destinationFilePath = addCounterToPath(
          '${desktopDownloadsDirectory.path}/$fileName', counter);

      final File destinationFile = File(destinationFilePath);

      if (!await destinationFile.exists()) {
        await destinationFile.writeAsBytes(bytes);
        break;
      }
      counter++;
    }
    openDownloadDir('$fileName', context);
  }
}
