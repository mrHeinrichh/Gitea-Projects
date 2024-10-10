part of '../upload_util.dart';

final VideoMgr videoMgr = VideoMgr();

class VideoMgr {
  // 上传文件
  Future<(String path, String sourceFile)> upload(
    String path, {
    int accurateWidth = 0,
    int accurateHeight = 0,
    int? firstPostTime,
    ProgressCallback? onSendProgress,
    required CancelToken cancelToken,
    bool showOriginal = false,
    void Function(double progress)? onCompressProgress,
    void Function(String path)? onCompressCallback,
    void Function(int status)? onStatusChange,
    UploadExt fileType = UploadExt.video,
  }) async {
    firstPostTime ??= DateTime.now().millisecondsSinceEpoch;

    Handler chain = VideoCompressHandler(
      CalculateMD5Handler(
        RequestInitHandler<VideoUploadRequest>(
          CalculateMD5Base64Handler(
            VideoRequestUploadUrlHandler(
              VideoUploadPartHandler(VideoRequestCompositionHandler(null)),
            ),
          ),
        ),
      ),
    );

    VideoUploadRequest videoRequest = VideoUploadRequest(
      path,
      accurateWidth: accurateWidth,
      accurateHeight: accurateHeight,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onCompressProgress: onCompressProgress,
      onCompressCallback: onCompressCallback,
      onStatusChange: onStatusChange,
      fileType: fileType,
    );

    try {
      HandleMsg result = await chain.handleRequest(videoRequest);

      final isTimeOut =
          DateTime.now().millisecondsSinceEpoch - firstPostTime >= (10 * 60);
      if (!result.result && isTimeOut) {
        return ('', '');
      }

      if (result.result) {
        return (
          videoRequest.targetHLSURLs!.uploadedPath ?? '',
          videoRequest.targetHLSURLs!.sourceFile ?? '',
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        '"uploadHandleRequest":"Error in $runtimeType", "stackTrace": "$stackTrace","e":"$e"',
        e,
        stackTrace,
      );
      if ((DateTime.now().millisecondsSinceEpoch - firstPostTime) ~/ 1000 <=
          (10 * 60)) {
        return upload(
          path,
          accurateWidth: accurateWidth,
          accurateHeight: accurateHeight,
          firstPostTime: firstPostTime,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
          showOriginal: showOriginal,
          onCompressProgress: onCompressProgress,
          onCompressCallback: onCompressCallback,
          onStatusChange: onStatusChange,
          fileType: fileType,
        );
      } else {
        rethrow;
      }
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
    );
  }

  Future<String?> genVideoCover(
    String path,
    int width,
    int height, {
    AssetEntity? entity,
  }) async {
    File? coverF;
    final String coverPath = await downloadMgr.getTmpCachePath(
      '${path}_cover.jpeg',
      sub: 'cover',
      create: false,
    );

    if (downloadMgr.checkLocalFile(coverPath) != null) {
      return coverPath;
    }

    if (entity != null) {
      File? assetFile = await entity.originFile;
      if (assetFile != null) {
        coverF = File(coverPath);
        if (!coverF.existsSync() || coverF.lengthSync() == 0) {
          coverF.createSync(recursive: true);
          coverF.writeAsBytesSync(
            (await entity.thumbnailDataWithSize(
              ThumbnailSize(width, height),
              format: ThumbnailFormat.jpeg,
              quality: 80,
            ))!,
          );
        }
      }
    }

    if (coverF == null || !coverF.existsSync() || coverF.lengthSync() <= 0) {
      return null;
    }
    return coverPath;
  }

  void preloadVideo(
    String url, {
    double preloadMb = 2,
    int width = 0,
    int height = 0,
  }) async {
    if (objectMgr.loginMgr.isDesktop) {
      return;
    }
    final mp4RelativeFolderIdx = url.lastIndexOf(Platform.pathSeparator);
    final mp4RelativeFolder = url.substring(0, mp4RelativeFolderIdx);
    String? localUrl = downloadMgr.checkLocalFile(
      "$mp4RelativeFolder${Platform.pathSeparator}index.mp4",
    );
    if (localUrl != null) {
      // 有本地文件，不必预加载
      return;
    }

    Uri? u = await downloadMgr.getDownloadUri(url);
    String url1 = u?.toString() ?? "";
    objectMgr.tencentVideoMgr.addPreloadTask(
      url1,
      width: width,
      height: height,
      preloadMb: preloadMb,
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
          timeout: const Duration(seconds: 60),
        ) ??
        '';
  }

  Future<bool> checkM3u8HasFinishedProcessing(String hash,
      {String type = "Video"}) async {
    return await checkM3u8(hash, type: type);
  }

  Map<double, Map<String, dynamic>> checkTsFiles(
    String path,
    String localPath,
  ) {
    final tsDirLastIdx = path.lastIndexOf('/');
    final tsDir = path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = cacheMediaMgr.extractTsUrls(
      tsDir,
      localPath,
    );

    List values = tsMap.values.toList();

    if (values.isEmpty) {
      return {};
    }

    String? p1 = downloadMgr.checkLocalFile(values[0]['url']);
    if (!notBlank(p1)) {
      return {};
    }

    if (values.length > 1) {
      //check second item
      String? p2 = downloadMgr.checkLocalFile(values[1]['url']);
      if (!notBlank(p2)) {
        return {};
      }
    }

    return tsMap;
  }

  /// 下载ts文件
  /// @param
  /// path: m3u8 相对路径
  /// localPath: 本地m3u8文件路径
  Future<Map<double, Map<String, dynamic>>> downloadTsFile(
    String path,
    String localPath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final tsDirLastIdx = path.lastIndexOf('/');
    final tsDir = path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = cacheMediaMgr.extractTsUrls(
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

    List<Future<String?>> tsFuture = [];

    tsFuture.add(
      cacheMediaMgr.downloadMedia(
        values[0]['url'],
        cancelToken: cancelToken,
        timeout: const Duration(seconds: 60),
      ),
    );
    if (values.length > 1) {
      tsFuture.add(
        cacheMediaMgr.downloadMedia(
          values[1]['url'],
          cancelToken: cancelToken,
          timeout: const Duration(seconds: 60),
        ),
      );
    }

    List<String?> tsPaths = await tsFuture.wait;
    if (tsPaths.first == null) return {};

    return tsMap;
  }

  Future<List<String>> multipleDownloadTsFiles(
    List<String> downloadUrls,
  ) async {
    List<String> cachePaths = [];

    List<Future<String?>> downloadTask = [];
    for (final url in downloadUrls) {
      downloadTask.add(cacheMediaMgr.downloadMedia(url,
          timeout: const Duration(seconds: 500)));
    }

    List<String?> results = await Future.wait(downloadTask);

    for (final res in results) {
      cachePaths.add(res!);
    }

    return cachePaths;
  }

  /// 合并 TS 文件为MP4
  Future<String> combineToMp4(
    List<String> urlList, {
    String? dir,
    String? fullUrl,
  }) async {
    if (dir != null) await DYio.mkDir(dir);

    final int curTime = DateTime.now().millisecondsSinceEpoch;
    String outputPath = fullUrl ?? '$dir/video_$curTime.mp4';

    // List<String> tmpFilePaths = [];
    // for (final url in urlList) {
    //   final tmpPath = await copyFile(url);
    //   if (notBlank(tmpPath)) {
    //     tmpFilePaths.add(tmpPath!);
    //   }
    // }

    final tmpInputs = urlList.join("|");

    final command = '-i concat:"$tmpInputs" -c copy "$outputPath"';
    await FFmpegKit.execute(command);
    // delete tmp files
    // for (final tmpPath in tmpFilePaths) {
    //   File tmpFIle = File(tmpPath);
    //   tmpFIle.delete();
    // }

    // if (File(tempPath).existsSync()) {
    //   File tFile = await generateThumbnailWithPath(
    //     tempPath,
    //     savePath: 'video_thumbnail_$curTime.jpeg',
    //     sub: 'tmp',
    //   );
    //
    //   await ImageGallerySaver.saveFile(
    //     tFile.path,
    //     isReturnPathOfIOS: true,
    //   );
    //
    //   if (tFile.existsSync()) {
    //     final session = await FFmpegKit.execute(
    //       '-y -i $tempPath -i ${tFile.path} -map 0 -map 1 -c copy -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v:1 attached_pic $outputPath',
    //     );
    //
    //     await ImageGallerySaver.saveFile(
    //       outputPath,
    //       isReturnPathOfIOS: true,
    //     );
    //
    //     final logs = await session.getAllLogsAsString();
    //     pdebug('logs');
    //   }
    // }

    pdebug('Successfully combined to MP4: $outputPath');
    return outputPath;
  }

  Future<String?> copyFile(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (sourceFile.existsSync()) {
        // Construct the new file path
        final directory = sourceFile.parent.path;
        final newFileName = 'tmp_${sourceFile.uri.pathSegments.last}';
        final newFilePath = '$directory/$newFileName';

        // Copy the file
        final newFile = await sourceFile.copy(newFilePath);
        pdebug('File copied to: ${newFile.path}');
        return newFile.path;
      } else {
        pdebug('Source file does not exist');
      }
    } catch (e) {
      pdebug('Error copying file: $e');
    }
    return null;
  }
}
