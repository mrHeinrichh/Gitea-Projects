import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/download_lib/download_util.dart';
import 'package:jxim_client/network/local_http_server.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_utils.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path/path.dart' as p;

final DownloadMgr downloadMgr = DownloadMgr();
final DesktopDownloadMgr desktopDownloadMgr = DesktopDownloadMgr();
final DownLoadQueue _downLoadQueue = DownLoadQueue();

class DownloadMgr {
  String get appDocumentRootPath => AppPath.appDownloadPath;

  String get appCacheRootPath => AppPath.appCacheRootPath;
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
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
    }

    // 如果路径获取失败直接不处理
    if (!_isInit) return;

    // 清理下载缓存目录
    await _clearDownLoadCache();

    // 清理加密过去目录
    await _cleanSecretFolderIfExpired(expirationTimestamp: 1731299106928);
  }

  // 清理下载的缓存目录
  _clearDownLoadCache() async {
    try {
      final tempCache = objectMgr.localStorageMgr
          .read<String>(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
      if (tempCache != null) {
        _cacheSubMap = jsonDecode(tempCache).cast<String, String>();
      }
    } catch (e) {
      await objectMgr.localStorageMgr
          .remove(LocalStorageMgr.DOWNLOAD_CACHE_SUB_VALUE);
      _cacheSubMap.clear();
    }
  }

  // 清理过期的加密目录
  Future<void> _cleanSecretFolderIfExpired(
      {required int expirationTimestamp}) async {
    try {
      // 获取应用程序文档目录

      // 定义 secret 文件夹的路径
      final secretDir = Directory('$appDocumentRootPath/secret');

      // 检查 secret 文件夹是否存在
      if (await secretDir.exists()) {
        // 获取 secret 文件夹的最后修改时间
        final directoryStat = await secretDir.stat();
        final lastModified = directoryStat.modified;

        // 将传入的时间戳转换为 DateTime 对象
        final expirationDate =
            DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);

        // 打印过期时间和文件夹的最后修改时间以便对比
        pdebug('cleanSecretFolderIfExpired 过期时间: $expirationDate');
        pdebug('cleanSecretFolderIfExpired 文件夹最后修改时间: $lastModified');

        // 如果 secret 文件夹最后修改时间早于过期时间，删除整个文件夹
        if (lastModified.isBefore(expirationDate)) {
          await secretDir.delete(recursive: true).then((value) {
            pdebug(
                'cleanSecretFolderIfExpired 已删除过期的 secret 目录：${secretDir.path}');
          }).catchError((onError) {
            pdebug(
                'cleanSecretFolderIfExpired 已删除过期的 secret 目录：${secretDir.path} 失败');
          });
        } else {
          pdebug('cleanSecretFolderIfExpired secret 目录未过期，无需删除');
        }
      } else {
        pdebug('cleanSecretFolderIfExpired secret 目录不存在');
      }
    } catch (e) {
      pdebug('cleanSecretFolderIfExpired 清理 secret 文件夹时出错: $e');
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

    String tmpPath = '$appDocumentRootPath/tmp'
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
    uriPath = uriPath.replaceAll('$appCacheRootPath/', '');
    uriPath = uriPath.replaceAll(appCacheRootPath, '');
    uriPath = uriPath.replaceAll('$appDocumentRootPath/', '');
    uriPath = uriPath.replaceAll(appDocumentRootPath, '');
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

    return "$appDocumentRootPath/${_getRelativePath(downloadUrl)}";
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

    if (uri != null && uri.path.contains('.m3u8')) {
      uri = await LocalHttpServer.getLocalproxy(uri);
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
    if (_checkFileExistsSync(url)) return url;
    String? savePath = getSavePath(url, mini: mini);
    if (_checkFileExistsSync(savePath)) return savePath;
    return null;
  }

  // 清理目录
  clear() {
    Directory directory = Directory(appDocumentRootPath);
    if (directory.existsSync()) {
      directory.delete(recursive: true).catchError((onError) => onError);
    }
  }
}

class DesktopDownloadMgr extends DownloadMgr {
  final desktopDownloadsDirectory = Directory(
    '${Directory('/Users/${Platform.environment['USER'] ?? Platform.environment['USERNAME']}').path}/Downloads',
  );

  Future<void> desktopDownload(Message message, BuildContext context) async {
    Toast.showToast(localized(downloadingFile));
    String url = getMediaMessagePath(message);

    DownloadResult result = await downloadMgrV2.download(url,
        timeout: const Duration(seconds: 500));
    var str = result.localPath;

    // var str = await downloadMgr.downloadFile(url,
    //     timeout: const Duration(seconds: 500));

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
    );
  }

  Future<void> openDownloadDir(String filePath) async {
    const MethodChannel methodChannel = MethodChannel('desktopAction');
    String finalFilePath = filePath
        .replaceAll("${desktopDownloadsDirectory.path}/", '')
        .replaceAll(desktopDownloadsDirectory.path, '');
    if (finalFilePath.startsWith('/')) {
      finalFilePath = finalFilePath.substring(1);
    }
    final bool fileExist = await methodChannel.invokeMethod(
      'openDownloadDir',
      {'downloadPath': '${desktopDownloadsDirectory.path}/$finalFilePath'},
    );
    if (!fileExist) {
      Toast.showToast(
        localized(fileNotExist),
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
