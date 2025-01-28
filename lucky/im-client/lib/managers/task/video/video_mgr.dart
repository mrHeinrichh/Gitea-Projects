// 视频管理器

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';

import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/io.dart';

import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/task/video/video_upload_request.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

final VideoMgr videoMgr = VideoMgr();

class VideoMgr {
  // 上传文件
  Future<(String path, String sourceFile, String fileHash)> upload(
    String path, {
    int accurateWidth = 0,
    int accurateHeight = 0,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    bool showOriginal = false,
    void Function(double progress)? onCompressProgress,
    void Function(String path)? onCompressCallback,
    void Function(int status)? onStatusChange,
  }) async {
    cancelToken ??= CancelToken();
    Handler chain = VideoCompressHandler(FileEncodeHandler(
        VideoCalculateMD5Handler(VideoRequestUploadUrlHandler(
            VideoUploadPartHandler(VideoRequestCompositionHandler(
                VideoPollingCompositionHandler(null)))))));

    VideoUploadRequest videoRequest = VideoUploadRequest(
      path,
      accurateWidth: accurateWidth,
      accurateHeight: accurateHeight,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      showOriginal: showOriginal,
      onCompressProgress: onCompressProgress,
      onCompressCallback: onCompressCallback,
      onStatusChange: onStatusChange,
    );

    try {
      HandleMsg result = await chain.handleRequest(videoRequest);
      logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
        msg:
            'VideoMgr upload 完成 ${result.toJson()}  videoRequest: ${videoRequest.toJson()}',
      ));
      if (result.result) {
        return (
          videoRequest.targetHLSURLs!.uploadedPath ?? '',
          videoRequest.targetHLSURLs!.sourceFile ?? '',
          result.message ?? '',
        );
      }

      return (
        '',
        '',
        result.message.toString(),
      );
    } catch (e) {
      if (cancelToken.isCancelled == false) {
        cancelToken.cancel();
      }

      logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
        msg:
            'VideoMgr upload 出错了 ${e.toString()}  videoRequest: ${videoRequest.toJson()}',
      ));
    } finally {
      downloadMgr.updateCacheSubValue(
        videoRequest.sourceFilePath,
        videoRequest.targetHLSURLs?.hls?.first.path ??
            videoRequest.targetHLSURLs?.sourceFile,
        isfinal: true,
      );
    }
    return (
      '',
      '',
      "error",
    );
  }

  Future<void> preloadVideo(
    String url, {
    CancelToken? cancelToken,
  }) async {
    String localM3u8File = await previewVideoM3u8(
      url,
      cancelToken: cancelToken,
    );
    if (localM3u8File.isEmpty) {
      return;
    }

    downloadTsFile(
      url,
      localM3u8File,
      cancelToken: cancelToken,
    );
    return;
  }

  Future<String> previewVideoM3u8(
    String path, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    return await cacheMediaMgr.downloadMedia(
          path,
          cancelToken: cancelToken,
          timeoutSeconds: 60,
        ) ??
        '';
  }

  /// 下载ts文件
  /// @param
  /// path: m3u8 相对路径
  /// localPath: 本地m3u8文件路径
  ///
  Future<Map<double, Map<String, dynamic>>> downloadTsFile(
    String path,
    String localPath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final tsDirLastIdx = path.lastIndexOf('/');
    final tsDir = path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = await cacheMediaMgr.extractTsUrls(
      tsDir,
      localPath,
    );

    List values = tsMap.values.toList();

    if (values.isEmpty) {
      previewVideoM3u8(
        path,
        cancelToken: cancelToken,
      );
      return {};
    }

    String? ts1Path = await cacheMediaMgr.downloadMedia(
      values[0]['url'],
      cancelToken: cancelToken,
      timeoutSeconds: 60,
    );

    if (ts1Path == null) {
      return {};
    }

    return tsMap;
  }

  Future<String> downloadMp4File(
    String path, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    int tryCount = 0,
  }) async {
    return await cacheMediaMgr.downloadMedia(path, cancelToken: cancelToken) ??
        '';
  }

  Future<List<String>> multipleDownloadTsFiles(
      List<String> downloadUrls) async {
    List<String> cachePaths = [];

    // todo: change to concurrent download
    List<Future<String?>> downloadTask = [];
    for (final url in downloadUrls) {
      downloadTask.add(cacheMediaMgr.downloadMedia(url, timeoutSeconds: 500));
    }

    List<String?> results = await Future.wait(downloadTask);

    for (final res in results) {
      cachePaths.add(res!);
    }

    return cachePaths;
  }

  /// 合并 TS 文件为MP4
  Future<String> combineToMp4(List<String> urlList, {String? dir}) async {
    if (dir != null) await DYio.mkDir(dir);

    final int curTime = DateTime.now().millisecondsSinceEpoch;
    String outputPath = '$dir/video_$curTime.mp4';

    final inputFiles = urlList.join('|');

    final command =
        '-i concat:"$inputFiles" -map_metadata -1 -c copy "$outputPath"';
    await FFmpegKit.execute(command);

    pdebug('Successfully combined to MP4: $outputPath');
    return outputPath;
  }
}

// class VideoDownloadTask extends ScheduleTask {
//   VideoDownloadTask({
//     delay = 1 * 1000,
//     isPeriodic = true,
//   }) : super(delay, isPeriodic);
//
//   List<Handler> handlerChain = [];
//
//   @override
//   execute() {
//     // Todo: 下载心跳
//     throw UnimplementedError();
//   }
//
//   void sortPriority() {}
// }
