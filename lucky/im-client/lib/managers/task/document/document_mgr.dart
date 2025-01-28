import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/task/document/document_upload_request.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';

final DocumentMgr documentMgr = DocumentMgr();

class DocumentMgr {
  Future<String?> upload(
    String path, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    cancelToken ??= CancelToken();
    Handler chain = FileEncodeHandler(DocumentCalculateMD5Handler(
        DocumentRequestUploadUrlHandler(DocumentUploadPartHandler(
            DocumentRequestCompositionHandler(null)))));

    DocumentUploadRequest documentRequest = DocumentUploadRequest(
      path,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );

    try {
      documentRequest.file_id = await compute(
        calculateMD5,
        File(documentRequest.sourceFilePath).readAsBytesSync(),
      );
      if (!await documentRequest.initAsync()) {
        pdebug("DocumentMgr initAsync fail", isError: true);
        return null;
      }

      HandleMsg result = await chain.handleRequest(documentRequest);
      logMgr.logUploadDocmentMgr.addMetrics(LogUploadDocmentMsg(
        msg:
            'DocumentMgr upload 完成 ${result.toJson()} documentRequest: ${documentRequest.toJson()}',
      ));
      if (result.result && documentRequest.targetURLs?.sourceFile != null) {
        return documentRequest.targetURLs!.sourceFile;
      }
    } catch (e, s) {
      if (cancelToken.isCancelled == false) {
        cancelToken.cancel();
      }

      logMgr.logUploadDocmentMgr.addMetrics(LogUploadDocmentMsg(
        msg:
            'DocumentMgr upload 出错了 ${e.toString()} documentRequest: ${documentRequest.toJson()}',
      ));
    } finally {
      downloadMgr.updateCacheSubValue(documentRequest.sourceFilePath,
          documentRequest.targetURLs?.sourceFile,
          isfinal: true);
    }
    return null;
  }
}
