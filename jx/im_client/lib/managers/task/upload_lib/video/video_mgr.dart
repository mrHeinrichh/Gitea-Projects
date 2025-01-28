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
    StorageType storageType = StorageType.video,
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
      storageType: storageType,
    );

    try {
      HandleMsg result = await chain.handleRequest(videoRequest);

      final isTimeOut =
          DateTime.now().millisecondsSinceEpoch - firstPostTime >= (10 * 60);

      if (!result.result && isTimeOut) {
        SumUploadAnalytics.sharedInstance.updateUploadStatistic(
          AnalyticsHelper.getFileType(videoRequest.totalBytes),
          failedCount: true,
        );
        return ('', '');
      }

      if (result.result) {
        SumUploadAnalytics.sharedInstance.updateUploadStatistic(
          AnalyticsHelper.getFileType(videoRequest.totalBytes),
          successCount: true,
        );
        return (
          videoRequest.targetHLSURLs!.uploadedPath ?? '',
          videoRequest.targetHLSURLs!.sourceFile ?? '',
        );
      }
    } catch (e, stackTrace) {
      SumUploadAnalytics.sharedInstance.updateUploadStatistic(
        AnalyticsHelper.getFileType(videoRequest.totalBytes),
        failedCount: true,
      );
      objectMgr.logMgr.logUploadMgr.addMetrics(LogUploadMsg(
        msg:
            '"uploadHandleRequest":"Error in $runtimeType", "stackTrace": "$stackTrace","e":"$e"',
      ));

      if (e is CompleteUploadException) {
        rethrow;
      }

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
          storageType: storageType,
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
      SumUploadAnalytics.sharedInstance.updateUploadStatistic(
        AnalyticsHelper.getFileType(videoRequest.totalBytes),
        uploadDuration: DateTime.now().millisecondsSinceEpoch - firstPostTime,
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

    if (downloadMgrV2.getLocalPath(coverPath) != null) {
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

  Future<String?> genMacOSVideoCover(
    String path,
    int width,
    int height, {
    dynamic entity,
  }) async {
    File? coverF;
    final String coverPath = await downloadMgr.getTmpCachePath(
      '${path}_cover.jpeg',
      sub: 'cover',
      create: false,
    );

    if (downloadMgrV2.getLocalPath(coverPath) != null) {
      return coverPath;
    }

    File? assetFile;
    if (entity is File) {
      assetFile = entity;
    }

    if (entity != null && entity is AssetEntity) {
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
    } else if (assetFile != null) {
      coverF = File(coverPath);
      if (!coverF.existsSync() || coverF.lengthSync() == 0) {
        coverF.createSync(recursive: true);
        final File? imageFile = await generateThumbnailWithPath(
          assetFile.path,
        );

        if (imageFile != null) {
          final imageData = await imageFile.readAsBytes();
          coverF.writeAsBytesSync(imageData);
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
    String extension = path.extension(url);
    if (path.extension(url).toLowerCase() != '.m3u8') return;

    final mp4RelativeFolder = url.replaceAll(extension, '.mp4');
    String? localUrl = downloadMgrV2.getLocalPath(
      mp4RelativeFolder,
    );
    if (localUrl != null) {
      // 有本地文件，不必预加载
      return;
    }

    Uri? u = await downloadMgr.getDownloadUri(url);

    objectMgr.tencentVideoMgr.addPreloadTask(
      u,
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
    return downloadMgrV2
        .download(
          path,
          cancelToken: cancelToken,
          timeout: const Duration(seconds: 60),
        )
        .then((value) => value.localPath ?? "");
    // return await downloadMgr.downloadFile(
    //       path,
    //       cancelToken: cancelToken,
    //       timeout: const Duration(seconds: 60),
    //     ) ??
    //     '';
  }

  Future<bool> checkM3u8HasFinishedProcessing(String hash,
      {String type = "Video",
      bool isEncrypt = false,
      String? sourceExtension}) async {
    return await checkM3u8(hash, type: type, sourceExtension: sourceExtension);
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

    String? p1 = downloadMgrV2.getLocalPath(values[0]['url']);
    if (!notBlank(p1)) {
      return {};
    }

    if (values.length > 1) {
      //check second item
      String? p2 = downloadMgrV2.getLocalPath(values[1]['url']);
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

    tsFuture.add(downloadMgrV2
            .download(
              values[0]['url'],
              cancelToken: cancelToken,
              downloadType: DownloadType.largeFile,
              timeout: const Duration(seconds: 60),
            )
            .then((value) => value.localPath)
        // downloadMgr.downloadFile(
        //   values[0]['url'],
        //   cancelToken: cancelToken,
        //   timeout: const Duration(seconds: 60),
        // ),
        );
    if (values.length > 1) {
      tsFuture.add(downloadMgrV2
              .download(values[1]['url'],
                  cancelToken: cancelToken,
                  downloadType: DownloadType.largeFile,
                  timeout: const Duration(seconds: 60))
              .then((value) => value.localPath)
          // downloadMgr.downloadFile(
          //   values[1]['url'],
          //   cancelToken: cancelToken,
          //   timeout: const Duration(seconds: 60),
          // ),
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
      downloadTask.add(downloadMgrV2
          .download(url, timeout: const Duration(seconds: 500))
          .then((value) => value.localPath));
      // downloadMgr.downloadFile(url, timeout: const Duration(seconds: 500)));
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

    final tmpInputs = urlList.join("|");

    final command = '-i concat:"$tmpInputs" -c copy "$outputPath"';
    await FFmpegKit.execute(command);
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

  Future<bool> checkM3u8(String hash,
      {String type = "Video",
      bool isEncrypt = false,
      String? sourceExtension}) async {
    final Map<String, dynamic> dataBody = {
      "file_id": hash,
      "file_typ": type,
      'file_ext': sourceExtension ?? ".mp4",
      'is_encrypt': isEncrypt,
      'is_original': false,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/file/check_file',
        data: dataBody,
      );

      if (res.success()) {
        if (res.data['target_files'] == null) {
          return false;
        }

        VideoData d = VideoData.fromJson(res.data['target_files']);
        return d.hls?.first.isEnd ?? false;
      } else {
        throw AppException(res.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}
