import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

final CacheMediaMgr cacheMediaMgr = CacheMediaMgr();

class CacheMediaMgr {
  /// 下载文件
  Future<String?> downloadMedia(
    String downloadUrl, {
    int? mini,
    CancelToken? cancelToken,
    Duration timeout = const Duration(seconds: 60),
    Function(int bytes, int totalBytes)? onReceiveProgress,
    int priority = 0, // 任务优先级
  }) async {
    return await downloadMgr.downloadFile(
      downloadUrl,
      priority: 10,
      mini: mini,
      cancelToken: cancelToken,
      timeout: timeout,
      onReceiveProgress: onReceiveProgress,
    );
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
          final path = await downloadMedia(
            msgImg.gausPath,
            priority: 2,
          );

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

          fileExist = downloadMgr.checkLocalFile(filePath ?? '') != null;
        }
        break;
      case messageTypeVideo:
      case messageTypeReel:
        MessageVideo msgVideo = message.decodeContent(cl: MessageVideo.creator);

        if (msgVideo.gausPath.contains('Image/')) {
          final path = await downloadMedia(
            msgVideo.gausPath,
            priority: 2,
          );

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

          fileExist = downloadMgr.checkLocalFile(filePath ?? '') != null;
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

          fileExist = downloadMgr.checkLocalFile(filePath ?? '') != null;
        }
        break;
      case messageTypeFile:
        MessageFile msgFile = message.decodeContent(cl: MessageFile.creator);

        if (msgFile.gausPath.contains('Image/')) {
          final path = await downloadMedia(
            msgFile.gausPath,
            priority: 2,
          );

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

          fileExist = downloadMgr.checkLocalFile(filePath ?? '') != null;
        }
      default:
        break;
    }

    return fileExist;
  }

  Future<bool> getAlbumGausImage(Message message) async {
    bool fileExist = false;
    if (message.typ == messageTypeNewAlbum) {
      final msgMedia = message.decodeContent(cl: NewMessageMedia.creator);
      final List<AlbumDetailBean> beans = msgMedia.albumList ?? [];
      if (beans.isEmpty) return false;

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

        fileExist = downloadMgr.checkLocalFile(filePath ?? '') != null;
      }
    }

    return fileExist;
  }
}
