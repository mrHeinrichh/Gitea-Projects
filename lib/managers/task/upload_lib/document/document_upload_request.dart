part of '../upload_util.dart';

class DocumentUploadRequest extends UploadChunk {
  DocumentUploadResponse? targetURLs;

  Function(String path, bool isEncrypt, FileType type)? onFileCoverGenerated;

  DocumentUploadRequest(
    super.sourceFilePath, {
    required super.cancelToken,
    super.onSendProgress,
    this.onFileCoverGenerated,
  }) {
    fileType = UploadExt.document;
  }
}

class DocumentUploadResponse {
  String? sourceFile;

  DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    sourceFile = json['source_file'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['source_file'] = sourceFile;
    return data;
  }
}

// 请求上传地址处理器
class DocumentRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<DocumentUploadRequest> {
  DocumentRequestUploadUrlHandler(super.next);

  @override
  Future<HandleMsg> handle(DocumentUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_presign',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );
    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            '请求s3地址失败 response:${request.uploadResponseData!.toJson()} request:${request.toJson()}',
        isClearAll: true,
      );
    }

    request.targetURLs = DocumentUploadResponse.fromJson(
        request.uploadResponseData!.target_files);
    if (request.targetURLs!.sourceFile != null &&
        request.targetURLs!.sourceFile!.isNotEmpty) {
      request.completed = true;
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "请求s3成功并返回target_files结果 response:${request.uploadResponseData!.toJson()} request:${request.toJson()}",
      );

      return handleMsg;
    }
    return HandleMsg(
      true,
      message:
          '请求s3地址成功...response:${request.uploadResponseData!.toJson()} request:${request.toJson()}',
    );
  }

  @override
  Future<DocumentUploadRequest> prepareHandle(
    DocumentUploadRequest request,
  ) async {
    if (request.onFileCoverGenerated == null) {
      return super.prepareHandle(request);
    }

    final FileType type = getFileType(request.sourceFilePath.toLowerCase());
    if (request.sourceFilePath.toLowerCase().contains('.pdf')) {
      try {
        final doc = await PdfDocument.openFile(request.sourceFilePath);
        if (doc.isEncrypted) {
          request.onFileCoverGenerated?.call('', true, type);
        }

        final PdfPage page = await doc.getPage(1);

        PdfPageImage img = await page.render(
          width: 480,
          height: 480,
        );

        final image = await img.createImageIfNotAvailable();
        final byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final String path = await downloadMgr.getTmpCachePath(
          'file_thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
          sub: 'document/file',
          create: true,
        );

        File imgFile = File(path);
        await imgFile.writeAsBytes(pngBytes);

        request.onFileCoverGenerated?.call(path, false, type);

        doc.dispose();
      } catch (e) {
        request.onFileCoverGenerated?.call('', true, type);
      }
    }

    if (type == FileType.image) {
      request.onFileCoverGenerated?.call(request.sourceFilePath, false, type);
    }

    if (type == FileType.video &&
        (request.totalBytes ?? 0) < 500 * 1024 * 1024) {
      try {
        final videoCover = await generateThumbnailWithPath(
          request.sourceFilePath,
          savePath: '${DateTime.now().millisecondsSinceEpoch.toString()}.jpg',
          sub: 'document/video',
        );

        request.onFileCoverGenerated?.call(videoCover.path, false, type);
      } catch (e) {
        request.onFileCoverGenerated?.call('', false, type);
      }
    }

    return super.prepareHandle(request);
  }
}

// 请求合成处理器
class DocumentRequestCompositionHandler
    extends RequestCompositionHandlerBase<DocumentUploadRequest> {
  DocumentRequestCompositionHandler(super.next);

  @override
  Future<HandleMsg> handle(DocumentUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_finish',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );
    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            '通知合成失败 response:${request.uploadResponseData!.toJson()}... request:${request.toJson()}',
        isClearAll: true,
      );
    }

    request.targetURLs = DocumentUploadResponse.fromJson(
        request.uploadResponseData!.target_files);
    if (request.targetURLs!.sourceFile != null &&
        request.targetURLs!.sourceFile!.isNotEmpty) {
      request.completed = true;
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "请求s3成功并返回target_files结果 response:${request.uploadResponseData!.toJson()} request:${request.toJson()}",
      );

      return handleMsg;
    }

    return HandleMsg(
      false,
      message:
          '通知合成成功 response:${request.uploadResponseData!.toJson()} request:${request.toJson()}',
    );
  }
}
