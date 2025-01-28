part of '../upload_util.dart';

final ImageMgr imageMgr = ImageMgr();

class ImageMgr {
  /// 图片上传统一入口, 只能调用这个接口进行图片上传
  ///
  /// @params: 参数描述
  ///
  /// **[path]**: 文件路径, 必须为全路径
  ///
  /// **[width]**: 图片宽度
  ///
  /// **[height]**: 图片高度
  ///
  /// **[cancelToken]**: 取消请求的token
  ///
  /// **[onSendProgress]**: 上传进度回调
  ///
  /// **[enableGaussian]**: 是否生成高斯模糊图
  Future<String?> upload(
    String path,
    int width,
    int height, {
    int? firstPostTime,
    required CancelToken cancelToken,
    ProgressCallback? onSendProgress,
    bool enableGaussian = true,
    void Function(String gausPath)? onGaussianComplete,
    GaussianGenFormat format = GaussianGenFormat.ffmpeg,
    StorageType storageType = StorageType.image,
  }) async {
    firstPostTime ??= DateTime.now().millisecondsSinceEpoch;

    Handler chain = CalculateMD5Handler(
      RequestInitHandler<ImageUploadRequest>(
        CalculateMD5Base64Handler(
          ImageRequestUploadUrlHandler(
            UploadPartHandler(ImageRequestCompositionHandler(null)),
          ),
        ),
      ),
    );

    if (enableGaussian) {
      final String? gausImagePath = await genBlurHashFFi(path);

      if (gausImagePath != null) {
        onGaussianComplete?.call(gausImagePath);
      }
    }

    ImageUploadRequest imageRequest = ImageUploadRequest(
      path,
      width: width,
      height: height,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      storageType: storageType,
    );

    try {
      HandleMsg result = await chain.handleRequest(imageRequest);

      final isTimeOut =
          DateTime.now().millisecondsSinceEpoch - firstPostTime >= (10 * 60);
      if (!result.result &&
          isTimeOut &&
          imageRequest.targetURLs?.sourceFile == null) {
        SumUploadAnalytics.sharedInstance.updateUploadStatistic(
          AnalyticsHelper.getFileType(imageRequest.totalBytes),
          failedCount: true,
        );
        return null;
      }

      if (result.result && imageRequest.targetURLs?.sourceFile != null) {
        SumUploadAnalytics.sharedInstance.updateUploadStatistic(
          AnalyticsHelper.getFileType(imageRequest.totalBytes),
          successCount: true,
        );
        return imageRequest.targetURLs!.sourceFile;
      }
    } catch (e, stackTrace) {
      SumUploadAnalytics.sharedInstance.updateUploadStatistic(
        AnalyticsHelper.getFileType(imageRequest.totalBytes),
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
        await Future.delayed(const Duration(seconds: 5));
        return await upload(
          path,
          width,
          height,
          firstPostTime: firstPostTime,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          enableGaussian: enableGaussian,
          onGaussianComplete: onGaussianComplete,
          format: format,
        );
      }

      rethrow;
    } finally {
      downloadMgr.updateCacheSubValue(
        imageRequest.sourceFilePath,
        imageRequest.targetURLs?.sourceFile,
        isfinal: true,
      );

      SumUploadAnalytics.sharedInstance.updateUploadStatistic(
        AnalyticsHelper.getFileType(imageRequest.totalBytes),
        uploadDuration: DateTime.now().millisecondsSinceEpoch - firstPostTime,
      );
    }
    return null;
  }

  Future<String?> compressImage(
    String path,
    int width,
    int height,
  ) async {
    Handler chain = ImageCompressHandler(null);

    String compressedPath = '';

    ImageUploadRequest imageRequest = ImageUploadRequest(
      path,
      width: width,
      height: height,
      cancelToken: CancelToken(),
      onCompressedComplete: (p) => compressedPath = p,
    );

    HandleMsg result = await chain.handleRequest(imageRequest);

    if (result.result && compressedPath.isNotEmpty) {
      return compressedPath;
    }

    return null;
  }

  Future<String?> genGaussianImage(
    String path,
    int width,
    int height,
  ) async {
    File oriFile = File(path);

    if (!oriFile.existsSync() || oriFile.lengthSync() <= 0) {
      return null;
    }

    String sourceMd5 =
        await compute<String, String?>(calculateMD5FromPath, path) ?? '';
    // 生成 64尺寸高斯模糊图
    final String smallImgPath = await downloadMgr.getTmpCachePath(
      '${sourceMd5}_160.${getFileExtension(path)}',
      sub: 'cover',
      create: false,
    );
    final String gausImgPath = await downloadMgr.getTmpCachePath(
      '${sourceMd5}_gaus_160.${getFileExtension(path)}',
      sub: 'cover',
      create: false,
    );

    if (File(gausImgPath).existsSync()) {
      return gausImgPath;
    }

    final imgRatio = width / height;

    final imageSession = await FFmpegKit.execute(
      '-y -i $path -vf "scale=${imgRatio > 1 ? '160:-1' : '-1:160'}" $smallImgPath',
    );

    final imageReturnCode = await imageSession.getReturnCode();
    final imageFile = File(smallImgPath);
    if ((imageReturnCode?.isValueCancel() ?? false) ||
        !imageFile.existsSync() ||
        imageFile.lengthSync() <= 0) {
      return null;
    }

    final gausSession = await FFmpegKit.execute(
      '-y -i $smallImgPath -vf "gblur=sigma=4" $gausImgPath',
    );

    final gausReturnCode = await gausSession.getReturnCode();
    final gausFile = File(gausImgPath);
    if ((gausReturnCode?.isValueCancel() ?? false) ||
        !gausFile.existsSync() ||
        gausFile.lengthSync() <= 0) {
      // 返回smallImgPath
      return smallImgPath;
    }

    imageFile.deleteSync();
    return gausImgPath;
  }

  Future<String?> genBlurHashFFi(String path) async {
    try {
      final String blurHash = await BlurhashFFI.encode(
        FileImage(File(path)),
      );

      return blurHash;
    } catch (e) {
      pdebug('Image to Blur Hash conversion failed: $e');
      return null;
    }
  }

  String getBlurHashSavePath(String filePath) =>
      '${downloadMgr.appDocumentRootPath}/${path.dirname(filePath)}${path.basenameWithoutExtension(filePath)}_gaus${path.extension(filePath)}';

  Future<String?> genBlurHashImage(String blurhash, String filePath) async {
    if (blurhash.isEmpty || filePath.isEmpty) return null;
    try {
      // 生成 64尺寸高斯模糊图
      final String smallImgPath = getBlurHashSavePath(filePath);

      if (File(smallImgPath).existsSync()) {
        return smallImgPath;
      }

      final uiImage = await BlurhashFFI.decode(
        blurhash,
        width: 64,
        height: 64,
      );

      final byteData = await uiImage.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return null;

      final file = File(smallImgPath);
      file.createSync(recursive: true);
      file.writeAsBytesSync(byteData.buffer.asUint8List());
      return smallImgPath;
    } catch (e) {
      pdebug('Blur Hash to image conversion failed: $e');
      return null;
    }
  }

  Future<(int width, int height)> getImageSize(String filePath) async {
    final savePath = downloadMgr.getSavePath(filePath);
    final imageFile = File(savePath);
    final bool fileExist = imageFile.existsSync();
    if (fileExist) {
      final imageSize = await getImageFromAsset(imageFile);
      if (notBlank(imageSize)) {
        return (imageSize['width'] as int, imageSize['height'] as int);
      }
    }

    return (0, 0);
  }

  Future<String> resizeImageTo384(String inputPath, String md5Path,
      {int? mini}) async {
    final imageFile = File(inputPath);
    final image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      return "";
    }

    // Resize the image
    final resizedImage = img.copyResize(image,
        width: mini ?? Config().sMessageMin, maintainAspect: true);

    String originalPaths = '${downloadMgr.appDocumentRootPath}/$md5Path';
    String fileExtension = path.extension(md5Path);
    List<String> segments = originalPaths.split('/');
    segments.removeLast();
    String dir = segments.join('/');

    String pathWithoutExtension = md5Path.split('.').first;
    String path_384 =
        "${downloadMgr.appDocumentRootPath}/${pathWithoutExtension}_${mini ?? Config().sMessageMin}$fileExtension";

    await Directory(dir).create(recursive: true);

    File copiedFile = await File(inputPath).copy(originalPaths);

    if (await copiedFile.exists()) {
      // Save the resized image
      final resizedImageFile = File(path_384);
      resizedImageFile.writeAsBytesSync(img.encodeJpg(resizedImage));

      int width = image.width;
      int height = image.height;
      String shortOriPath = md5Path;

      Map<String, dynamic> data = {
        'width': width,
        'height': height,
        'shortOriginalPath': shortOriPath,
      };
      return jsonEncode(data);
    } else {
      return "";
    }
  }

  Future<bool> convertHeifToJpg(String inputPath, String outputPath) async {
    bool isSuccess = true;
    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outputPath,
      format: CompressFormat.jpeg,
      quality: 95,
    );

    if (result == null) {
      isSuccess = false;
    }
    return isSuccess;
  }

  Future<String?> testUpload(CancelToken cancelToken, File file,
      {int? firstPostTime}) async {
    firstPostTime ??= DateTime.now().millisecondsSinceEpoch;

    Handler chain = CalculateMD5Handler(
      RequestInitHandler<ImageUploadRequest>(
        CalculateMD5Base64Handler(
          ImageRequestUploadUrlHandler(
            UploadPartHandler(ImageRequestCompositionHandler(null)),
          ),
        ),
      ),
    );

    ImageUploadRequest imageRequest = ImageUploadRequest(
      file.path,
      width: 854,
      height: 1280,
      cancelToken: cancelToken,
      onSendProgress: (a, b) {},
      storageType: StorageType.speedTest,
    );

    imageRequest.fileType = UploadExt.speedTest;
    imageRequest.isEncrypt = false;

    try {
      HandleMsg result = await chain.handleRequest(imageRequest);

      final isTimeOut =
          DateTime.now().millisecondsSinceEpoch - firstPostTime >= (10 * 60);
      if (!result.result &&
          isTimeOut &&
          imageRequest.targetURLs?.sourceFile == null) {
        return null;
      }

      if (result.result && imageRequest.targetURLs?.sourceFile != null) {
        return imageRequest.targetURLs!.sourceFile;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

enum GaussianGenFormat {
  ffmpeg,
  blurHash,
}
