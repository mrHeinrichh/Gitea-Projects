part of '../upload_util.dart';

final DocumentMgr documentMgr = DocumentMgr();

class DocumentMgr {
  Future<String?> upload(
    String path, {
    int? firstPostTime,
    ProgressCallback? onSendProgress,
    Function(String path, bool isEncrypt, FileType type)? onFileCoverGenerated,
    required CancelToken cancelToken,
  }) async {
    firstPostTime ??= DateTime.now().millisecondsSinceEpoch;

    Handler chain = CalculateMD5Handler(
      RequestInitHandler(
        CalculateMD5Base64Handler(
          DocumentRequestUploadUrlHandler(
            UploadPartHandler(DocumentRequestCompositionHandler(null)),
          ),
        ),
      ),
    );

    DocumentUploadRequest documentRequest = DocumentUploadRequest(
      path,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onFileCoverGenerated: onFileCoverGenerated,
    );

    try {
      HandleMsg result = await chain.handleRequest(documentRequest);

      final isTimeOut =
          DateTime.now().millisecondsSinceEpoch - firstPostTime >= (10 * 60);
      if (!result.result &&
          isTimeOut &&
          documentRequest.targetURLs?.sourceFile == null) {
        return null;
      }

      if (result.result && documentRequest.targetURLs?.sourceFile != null) {
        return documentRequest.targetURLs!.sourceFile;
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
          firstPostTime: firstPostTime,
          onSendProgress: onSendProgress,
          onFileCoverGenerated: onFileCoverGenerated,
          cancelToken: cancelToken,
        );
      } else {
        rethrow;
      }
    } finally {
      downloadMgr.updateCacheSubValue(
        documentRequest.sourceFilePath,
        documentRequest.targetURLs?.sourceFile,
        isfinal: true,
      );
    }
    return null;
  }
}
