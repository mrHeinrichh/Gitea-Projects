import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';

final CacheMediaMgr cacheMediaMgr = CacheMediaMgr();

class CacheMediaMgr {
  final Map<String, Function(double)?> _latestProgressCallback =
      <String, Function(double)?>{};

  // 'url' = progress percentage
  final Map<String, double> _progress = <String, double>{};

  final Map<String, Completer<String?>> _downloadFutures =
      <String, Completer<String?>>{};

  final Map<String, CancelToken> _downloadCancelToken = <String, CancelToken>{};

  /// 下载文件
  Future<String?> downloadMediaWithCache(
    String downloadUrl, {
    int? mini,
    CancelToken? cancelToken,
    Duration timeout = const Duration(seconds: 60),
    Function(double percentage)? onReceiveProgress,
    int priority = 0, // 任务优先级
  }) async {
    String parsedAddress = Uri.parse(downloadUrl).path.replaceAll('//', '/');
    if (parsedAddress.startsWith('/')) {
      parsedAddress = parsedAddress.substring(1);
    }
    _progress[parsedAddress] ??= 0.0;

    // Replace the previous callback with the new one (if provided)
    if (onReceiveProgress != null) {
      _latestProgressCallback[parsedAddress] = onReceiveProgress;
    }

    if (_downloadFutures[parsedAddress] != null) {
      // Immediately notify the new callback of the current progress
      if (_progress[parsedAddress]! > 0.0 && _progress[parsedAddress]! < 1.0) {
        onReceiveProgress?.call(_progress[parsedAddress]!);
      }
      cancelToken?.whenCancel.then((value) {
        _downloadCancelToken[parsedAddress]?.cancel('Cancel by user');
        _downloadFutures.remove(parsedAddress);
        _progress.remove(parsedAddress);
        _downloadCancelToken.remove(parsedAddress);
        _latestProgressCallback.remove(parsedAddress);
      });
      return _downloadFutures[parsedAddress]!.future;
    }

    _downloadCancelToken[parsedAddress] = cancelToken ?? CancelToken();

    final Completer<String?> c = Completer<String?>();
    _downloadFutures[parsedAddress] = c;

    await downloadMgrV2.download(downloadUrl,
        mini: mini, cancelToken: _downloadCancelToken[parsedAddress],
        onReceiveProgress: (int bytes, int totalBytes) {
      _progress[parsedAddress] = bytes / totalBytes;
      _latestProgressCallback[parsedAddress]?.call(_progress[parsedAddress]!);
      // tempReceiveProgress?.call(_progress[parsedAddress]!);
    }, timeout: timeout).then((v) {
      _progress[parsedAddress] = 1.0;
      c.complete(v.localPath);
    }).catchError((e) {
      _progress.remove(parsedAddress);
      c.complete(null);
    }).whenComplete(() {
      _downloadFutures.remove(parsedAddress);
      _progress.remove(parsedAddress);
      _downloadCancelToken.remove(parsedAddress);
      _latestProgressCallback.remove(parsedAddress);
    });

    // await downloadMgr.downloadFile(
    //   downloadUrl,
    //   priority: 10,
    //   mini: mini,
    //   cancelToken: _downloadCancelToken[parsedAddress],
    //   timeout: timeout,
    //   onReceiveProgress: (int bytes, int totalBytes) {
    //     _progress[parsedAddress] = bytes / totalBytes;
    //     _latestProgressCallback[parsedAddress]?.call(_progress[parsedAddress]!);
    //     // tempReceiveProgress?.call(_progress[parsedAddress]!);
    //   },
    // ).then((v) {
    //   _progress[parsedAddress] = 1.0;
    //   c.complete(v);
    // }).catchError((e) {
    //   _progress.remove(parsedAddress);
    //   c.complete(null);
    // }).whenComplete(() {
    //   _downloadFutures.remove(parsedAddress);
    //   _progress.remove(parsedAddress);
    //   _downloadCancelToken.remove(parsedAddress);
    //   _latestProgressCallback.remove(parsedAddress);
    // });

    return c.future;
  }

  void removeDownloadedMediaCache(String downloadUrl) {
    String parsedAddress = Uri.parse(downloadUrl).path.replaceAll('//', '/');
    if (parsedAddress.startsWith('/')) {
      parsedAddress = parsedAddress.substring(1);
    }

    _downloadFutures.remove(parsedAddress);
    _progress.remove(parsedAddress);
  }

  double? getDownloadPercentage(String url) {
    return _progress[url];
  }

  /// 解析 M3U8 文件, 获取ts 文件路径
  Map<double, Map<String, dynamic>> extractTsUrls(
    String tsDir,
    String m3u8Path, {
    String? postFix,
  }) {
    final Map<double, Map<String, dynamic>> tsMap = {};

    final m3u8File = File(m3u8Path);

    if (m3u8File.existsSync()) {
      final fileContent = m3u8File.readAsLinesSync();

      double totalCount = 0.0;
      for (final line in fileContent) {
        Map<String, dynamic> tempMap = {};
        double duration = 0;
        if (line.startsWith('#EXTINF:')) {
          final content = line.substring(8);
          duration = double.parse(content.substring(0, content.length - 1));
          totalCount = totalCount + duration;
        }

        if (tsMap[totalCount] != null) {
          tempMap = tsMap[totalCount]!;
        } else {
          if (duration > 0) {
            tempMap['duration'] = duration;
          }
        }

        if (line.endsWith('ts')) {
          tempMap['url'] = '$tsDir/$line';
          if (postFix != null) {
            tempMap['url'] = tempMap['url'] + postFix;
          }
        }
        if (tempMap.isNotEmpty) {
          tsMap[totalCount] = tempMap;
        }
      }
    }

    return tsMap;
  }

  Future<bool> getMessageGausImage(Message message) async {
    bool fileExist = false;
    switch (message.typ) {
      case messageTypeImage:
        MessageImage msgImg = message.decodeContent(cl: MessageImage.creator);

        if (msgImg.gausPath.contains('Image/')) {
          DownloadResult result = await downloadMgrV2.download(msgImg.gausPath);
          final path = result.localPath;
          // final path = await downloadMgr.downloadFile(
          //   msgImg.gausPath,
          //   priority: 2,
          // );

          fileExist = path != null;
        } else {
          final String hashPath = imageMgr.getBlurHashSavePath(msgImg.url);

          if (File(hashPath).existsSync()) {
            fileExist = true;
            break;
          }

          final filePath = await imageMgr.genBlurHashImage(
            msgImg.gausPath,
            msgImg.url,
          );

          fileExist = downloadMgrV2.getLocalPath(filePath ?? '') != null;
        }
        break;
      case messageTypeVideo:
      case messageTypeReel:
        MessageVideo msgVideo = message.decodeContent(cl: MessageVideo.creator);

        if (msgVideo.gausPath.contains('Image/')) {
          DownloadResult result =
              await downloadMgrV2.download(msgVideo.gausPath);
          final path = result.localPath;
          // final path = await downloadMgr.downloadFile(
          //   msgVideo.gausPath,
          //   priority: 2,
          // );

          fileExist = path != null;
        } else {
          final String hashPath = imageMgr.getBlurHashSavePath(msgVideo.cover);

          if (File(hashPath).existsSync()) {
            fileExist = true;
            break;
          }

          final filePath = await imageMgr.genBlurHashImage(
            msgVideo.gausPath,
            msgVideo.cover,
          );

          fileExist = downloadMgrV2.getLocalPath(filePath ?? '') != null;
        }
        break;
      case messageTypeNewAlbum:
        final msgMedia = message.decodeContent(cl: NewMessageMedia.creator);
        final List<AlbumDetailBean> beans = msgMedia.albumList ?? [];
        if (beans.isEmpty) break;
        for (final bean in beans) {
          final String src = bean.gausPath;
          final String url = bean.isVideo ? bean.cover : bean.url;

          if (src.isEmpty || url.isEmpty) {
            fileExist = false;
            continue;
          }

          final String hashPath = imageMgr.getBlurHashSavePath(url);

          if (File(hashPath).existsSync()) {
            fileExist = true;
            continue;
          }

          final filePath = await imageMgr.genBlurHashImage(src, url);

          fileExist = downloadMgrV2.getLocalPath(filePath ?? '') != null;
        }
        break;
      case messageTypeFile:
        MessageFile msgFile = message.decodeContent(cl: MessageFile.creator);

        if (msgFile.gausPath.contains('Image/')) {
          DownloadResult result =
              await downloadMgrV2.download(msgFile.gausPath);
          final path = result.localPath;
          // final path = await downloadMgr.downloadFile(
          //   msgFile.gausPath,
          //   priority: 2,
          // );

          fileExist = path != null;
        } else {
          final String hashPath = imageMgr.getBlurHashSavePath(msgFile.cover);

          if (File(hashPath).existsSync()) {
            fileExist = true;
            break;
          }

          final filePath = await imageMgr.genBlurHashImage(
            msgFile.gausPath,
            msgFile.cover,
          );

          fileExist = downloadMgrV2.getLocalPath(filePath ?? '') != null;
        }
      case messageTypeLink:
        MessageLink msgLink = message.decodeContent(cl: MessageLink.creator);

        if (msgLink.linkPreviewData == null) return false;

        final String hashPath =
            imageMgr.getBlurHashSavePath(msgLink.linkImageSrc);

        if (File(hashPath).existsSync()) {
          fileExist = true;
          break;
        }

        final filePath = await imageMgr.genBlurHashImage(
          msgLink.linkImageSrcGaussian,
          msgLink.linkImageSrc,
        );

        fileExist = downloadMgrV2.getLocalPath(filePath ?? '') != null;
      default:
        break;
    }

    return fileExist;
  }
}
