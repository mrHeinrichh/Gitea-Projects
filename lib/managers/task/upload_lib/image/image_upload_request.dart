part of '../upload_util.dart';

class ImageUploadRequest extends UploadChunk {
  // 上传完成地址
  ImageUploadResponse? targetURLs;

  // 图片压缩完成
  void Function(String path)? onCompressedComplete;

  // 图片宽
  int width;

  // 图片高
  int height;

  ImageUploadRequest(
    super.sourceFilePath, {
    required super.cancelToken,
    super.onSendProgress,
    this.onCompressedComplete,
    required this.width,
    required this.height,
  }) {
    fileType = UploadExt.image;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "file_id": fileId, //文件hash ''  源文件
      "file_typ": fileType?.value, //文件类型 'Video' 原文件 ‘document’
      "file_ext": fileExt, //文件扩展名 '.mp4' ‘.mp4’
      "total_block": totalBlock, //分片数量 ''
      "checksums": checksums, //分片md5 ['md5', 'md5']
      "is_kiwi_upload": true, // kiwi上传
      "is_check_md5": true, // 是否校验md5
    };
  }
}

class ImageUploadResponse extends UploadResponse implements JsonSerializable {
  Map<String, dynamic>? resizedImgs;
  String? sourceFile;
  String? message;

  ImageUploadResponse({this.message, this.sourceFile, this.resizedImgs});

  ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    resizedImgs = json['resized_imgs'];
    sourceFile = json['source_file'];
    typ = UploadExt.image;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['resized_imgs'] = resizedImgs;
    data['source_file'] = sourceFile;
    data['typ'] = typ;
    return data;
  }
}

class ImageCompressHandler
    extends RequestUploadCompressHandlerBase<ImageUploadRequest> {
  ImageCompressHandler(super.next);

  @override
  Future<HandleMsg> handle(ImageUploadRequest request) async {
    String logMsg = '';

    final String cachePath = await downloadMgr.getTmpCachePath(
      '${path.basenameWithoutExtension(request.sourceFilePath)}_${min(request.width, request.height)}.jpeg',
      sub: 'cover',
      create: false,
    );

    if (File(request.cacheFilePath).existsSync() ||
        File(cachePath).existsSync()) {
      if (File(cachePath).existsSync()) {
        request.sourceFilePath = cachePath;
      } else {
        request.sourceFilePath = request.cacheFilePath;
      }
    } else {
      final File compressedFile;

      if (request.width != 0 && request.height != 0) {
        // 根据分辨率压缩图片
        compressedFile = await getThumbImageWithPath(
          File(request.sourceFilePath),
          request.width,
          request.height,
          savePath:
              '${path.basenameWithoutExtension(request.sourceFilePath)}_${min(request.width, request.height)}.jpeg',
          sub: 'cover',
        );
        logMsg = '图片分辨率压缩 - ';
      } else {
        if (![
              '.jpg',
              '.jpeg',
              '.png',
            ].contains(path.extension(request.sourceFilePath.toLowerCase())) &&
            request.width != 0 &&
            request.height != 0) {
          // 非这些格式做转换
          compressedFile = await getThumbImageWithPath(
            File(request.sourceFilePath),
            request.width,
            request.height,
            quality: 100,
            savePath:
                '${path.basenameWithoutExtension(request.sourceFilePath)}_${min(request.width, request.height)}.jpeg',
            sub: 'cover',
          );
          logMsg = '图片格式转换 - ';
        } else {
          logMsg = '图片不需要压缩 - ';
          compressedFile = File(request.sourceFilePath);
        }
      }

      request.sourceFilePath = compressedFile.path;
    }
    request.onCompressedComplete?.call(request.sourceFilePath);

    return HandleMsg(true, message: "$logMsg 成功 request:${request.toJson()}");
  }
}

// 请求上传地址处理器
class ImageRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<ImageUploadRequest> {
  ImageRequestUploadUrlHandler(super.next);

  @override
  Future<HandleMsg> handle(ImageUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_presign',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );
    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            '请求s3上传地址失败 respone:${request.uploadResponseData!.toJson()} request:${request.toJson()}',
        isClearAll: true,
      );
    }

    request.targetURLs =
        ImageUploadResponse.fromJson(request.uploadResponseData!.target_files);

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
          "请求s3上传地址成功...respone:${request.uploadResponseData!.toJson()} request:${request.toJson()}",
    );
  }
}

// 请求合成处理器
class ImageRequestCompositionHandler
    extends RequestCompositionHandlerBase<ImageUploadRequest> {
  ImageRequestCompositionHandler(super.next);

  @override
  Future<HandleMsg> handle(ImageUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_finish',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );
    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            "通知合成失败...response:${request.uploadResponseData!.toJson()}  request:${request.toJson()}",
        isClearAll: true,
      );
    }

    request.targetURLs =
        ImageUploadResponse.fromJson(request.uploadResponseData!.target_files);

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
          "通知合成成功 response:${request.uploadResponseData!.toJson()} request:${request.toJson()}",
    );
  }
}
