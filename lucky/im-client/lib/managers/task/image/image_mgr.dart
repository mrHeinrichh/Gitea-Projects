import 'package:dio/dio.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/task/image/image_upload_request.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

final ImageMgr imageMgr = ImageMgr();

class ImageMgr {
  Future<String?> upload(
    String path,
    int width,
    int height, {
    bool showOriginal = false,
    ProgressCallback? onSendProgress,
    void Function(String path)? onCompressedComplete,
    CancelToken? cancelToken,
  }) async {
    cancelToken ??= CancelToken();
    Handler chain = ImageCompressHandler(FileEncodeHandler(
        ImageCalculateMD5Handler(ImageRequestUploadUrlHandler(
            ImageUploadPartHandler(ImageRequestCompositionHandler(null))))));

    ImageUploadRequest imageRequest = ImageUploadRequest(
      path,
      width: width,
      height: height,
      showOriginal: showOriginal,
      cancelToken: cancelToken,
      onCompressedComplete: onCompressedComplete,
      onSendProgress: onSendProgress,
    );

    try {
      HandleMsg result = await chain.handleRequest(imageRequest);
      logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
        msg:
            'ImageMgr upload 完成 ${result.toJson()} imageRequest: ${imageRequest.toJson()}',
      ));
      if (result.result && imageRequest.targetURLs?.sourceFile != null) {
        return imageRequest.targetURLs!.sourceFile;
      }
    } catch (e, s) {
      if (cancelToken.isCancelled == false) {
        cancelToken.cancel();
      }

      logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
        msg:
            'ImageMgr upload 出错了 ${e.toString()} imageRequest: ${imageRequest.toJson()}',
      ));
    } finally {
      downloadMgr.updateCacheSubValue(
        imageRequest.sourceFilePath,
        imageRequest.targetURLs?.sourceFile,
        isfinal: true,
      );
    }
    return null;
  }
}
