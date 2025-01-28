import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

final CacheMediaMgr cacheMediaMgr = CacheMediaMgr();

class CacheMediaMgr {
  /// 下载文件
  Future<String?> downloadMedia(
    String downloadUrl, {
    String? savePath,
    int? mini,
    CancelToken? cancelToken,
    int timeoutSeconds = 60,
    Function(int bytes, int totalBytes)? onReceiveProgress,
    int priority = 0, // 任务优先级
  }) async {
    return await downloadMgr.downloadFile(
      downloadUrl,
      savePath: savePath,
      priority: 10,
      mini: mini,
      cancelToken: cancelToken,
      timeoutSeconds: timeoutSeconds,
      onReceiveProgress: onReceiveProgress,
    );
  } 

  String? checkLocalFile(String url, {int? mini}) {
    String? savePath = downloadMgr.getSavePath(url, mini: mini);

    if (downloadMgr.checkFileExistsSync(savePath)) return savePath;
    return null;
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
}
