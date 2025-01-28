import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/log/log_base.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as path;

class ImageUploadRequest extends UploadChunk {
  // 上传完成地址
  ImageUploadResponse? targetURLs;

  ProgressCallback? onSendProgress;

  // 图片压缩完成
  void Function(String path)? onCompressedComplete;

  // 图片宽
  int width;

  // 图片高
  int height;

  ImageUploadRequest(
    super.sourceFilePath, {
    super.showOriginal,
    required super.cancelToken,
    this.onSendProgress,
    this.onCompressedComplete,
    required this.width,
    required this.height,
  }) {
    file_typ = UploadExt.image;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "file_id": file_id, //文件hash ''  源文件
      "file_typ": file_typ?.value, //文件类型 'Video' 原文件 ‘document’
      "file_ext": file_ext, //文件扩展名 '.mp4' ‘.mp4’
      "total_block": total_block, //分片数量 ''
      "checksums": checksums, //分片md5 ['md5', 'md5']
      "is_kiwi_upload": true, // kiwi上传
      "is_encrypt": is_encrypt, // 是否加密
      "is_check_md5": true, // 是否校验md5
      "is_original": showOriginal,
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
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    String sourcePath = request.sourceFilePath;
    final compressedFile;
    if (!request.showOriginal) {
      compressedFile = await getThumbImageWithPath(
        File(sourcePath),
        request.width,
        request.height,
        savePath: path.basename(sourcePath),
        sub: 'cover',
      );
    } else {
      if (!sourcePath.toLowerCase().endsWith('jpg') &&
          !sourcePath.toLowerCase().endsWith('jpeg') &&
          !sourcePath.toLowerCase().endsWith('png')) {
        compressedFile = await getThumbImageWithPath(
          File(sourcePath),
          request.width,
          request.height,
          quality: 100,
          savePath: path.basename(sourcePath),
          sub: 'cover',
        );
      } else {
        compressedFile = File(request.sourceFilePath);
      }
    }

    request.sourceFilePath = compressedFile.path;
    request.onCompressedComplete?.call(compressedFile.path);

    if (!await request.initAsync()) {
      pdebug("ImageMgr initAsync fail", isError: true);
      return HandleMsg(true,
          message: "ImageMgr initAsync fail : ${request.toJson()}");
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true,
        message: "Calculate MD5 Success request:${request.toJson()}");
  }
}

class ImageCalculateMD5Handler
    extends RequestUploadCompressHandlerBase<ImageUploadRequest> {
  ImageCalculateMD5Handler(super.next);

  @override
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
      msg: 'ImageCalculateMD5Handler start request:${request.toJson()}',
    ));

    // 每个分片md5的存储变量
    List<Uint8List> md5List = [];

    String sourcePath = request.sourceFilePath;
    request.sourceMd5 =
        await compute<String, String?>(calculateMD5FromPath, sourcePath) ?? '';

    if (request.sourceMd5.isEmpty) {
      return HandleMsg(
        false,
        message:
            'VideoCalculateMD5Handler Failed to calculate source md5 before compress',
      );
    }

    request.md5CacheKey = downloadMgr.appCacheRootPath +
        '/image' + //这里缓存聊天室id
        (request.showOriginal ? '/origin' : '') +
        "/${request.sourceMd5}${path.extension(sourcePath)}";

    Map<String, dynamic>? map;
    try {
      map = objectMgr.localStorageMgr
          .read<Map<String, dynamic>>(request.md5CacheKey);
    } catch (e) {
      objectMgr.localStorageMgr.remove(request.md5CacheKey);
    }

    if (map == null ||
        map.isEmpty ||
        !notBlank(map['checksums']) ||
        map['file_id'] == null) {
      final file = File(request.sourceFilePath);
      final openedFile = await file.open();
      const chunkSize = 5 * 1024 * 1024; // 5MB
      int totalSize = file.lengthSync();

      // for 循环文件分片
      for (int index = 0; index < request.total_block!; index++) {
        final start = index * chunkSize;

        final byte = await (await openedFile.setPosition(start))
            .readSync(min(totalSize - start, chunkSize));

        // 计算每个分片的md5
        md5List.add(await compute(calculateMD5Bytes, byte));
      }

      if (request.sourceMd5.isNotEmpty && request.showOriginal) {
        request.file_id = request.sourceMd5;
      } else {
        request.file_id =
            await compute<String, String?>(calculateMD5FromPath, file.path) ??
                '';
      }

      request.checksums = md5List.map((e) => convert.base64Encode(e)).toList();
      objectMgr.localStorageMgr.write(request.md5CacheKey,
          {'checksums': request.checksums, 'file_id': request.file_id});
    } else {
      request.file_id = map['file_id']!;
      request.checksums = [...map['checksums']];
    }

    request.finishFileKey = 'finish_${request.file_id}';

    // 赋值给 request.file_id
    assert(request.file_id!.isNotEmpty,
        "error: VideoCalculateMD5Handler localMd5 is empty");

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true,
        message: "Calculate MD5 Success request:${request.toJson()}");
  }
}

// 请求上传地址处理器
class ImageRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<ImageUploadRequest> {
  ImageRequestUploadUrlHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    var response = await uploadPost('/app/api/file/upload_part_presign',
        data: request.toJson(), cancelToken: request.cancelToken);
    if (!response.success) {
      await objectMgr.localStorageMgr.remove(request.md5CacheKey);
      await File(request.sourceFilePath).delete();
      return HandleMsg(
        false,
        message: 'Failed to obtain upload URLs request:${request.toJson()}',
      );
    }

    request.uploadURLs = response.data!['presign_urls'];
    request.targetURLs =
        ImageUploadResponse.fromJson(response.data!['target_files']);
    if (!(notBlank(request.uploadURLs))) {
      HandleMsg handleMsg = HandleMsg(
        true,
        message: "image_upload_request 191 request:${request.toJson()}",
      );
      await objectMgr.localStorageMgr
          .write(request.finishFileKey, request.file_id);

      return handleMsg;
    }

    logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
      msg:
          'ImageRequestUploadUrlHandler 请求上传地址处理器完成 request:${request.toJson()}',
    ));

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: "Requesting upload URLs success... request:${request.toJson()}",
    );
  }
}

class ImageUploadPartHandler extends UploadPartHandlerBase<ImageUploadRequest> {
  ImageUploadPartHandler(Handler? next) : super(next);

  // 所有分片总大小
  int totalSize = 0;

  // 已上传大小
  int uploadedSize = 0;

  @override
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
      msg: 'ImageUploadPartHandler 开始上传分片处理器 request:${request.toJson()}',
    ));

    final file = File(request.sourceFilePath);
    final openedFile = await file.open();
    const chunkSize = 5 * 1024 * 1024; // 5MB
    totalSize = file.lengthSync();

    if (request.uploadURLs!.isNotEmpty) {
      List<Future<bool>> futures = [];
      for (int index = 0; index < request.total_block!; index++) {
        String url = request.uploadURLs!["${index + 1}"] ?? '';
        if (url.isEmpty) {
          uploadedSize += chunkSize;
          continue;
        }

        if (request.cancelToken.isCancelled) {
          return HandleMsg(
            false,
            message: 'Cancelled request:${request.toJson()}',
          );
        }

        final start = index * chunkSize;
        final end = min(start + chunkSize, totalSize);

        final byte =
            await (await openedFile.setPosition(start)).readSync(end - start);

        futures.add(request.uploadQueue.uploadQueue(
          byte,
          url,
          request.file_ext ?? '.png',
          headers: {
            'Content-MD5': request.checksums[index],
          },
          cancelToken: request.cancelToken,
          onSendProgress: (int bytes, int total) {
            uploadedSize += bytes;
            request.onSendProgress?.call(uploadedSize, totalSize);
          },
        ));
      }
      openedFile.close();

      List<bool> allResults = await Future.wait(futures);

      bool anyFail = allResults.any((element) => element == false);

      if (anyFail) {
        return HandleMsg(false, message: "上传失败 request: ${request.toJson()}");
      }
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: 'Upload Image Success request:${request.toJson()}',
    );
  }
}

// 请求合成处理器
class ImageRequestCompositionHandler
    extends RequestCompositionHandlerBase<ImageUploadRequest> {
  ImageRequestCompositionHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
      msg:
          'ImageRequestCompositionHandler 开始请求合成处理器 request:${request.toJson()}',
    ));

    var response = await uploadPost('/app/api/file/upload_part_finish',
        data: request.toJson(), cancelToken: request.cancelToken);
    if (!response.success) {
      pdebug("Requesting file fail...");
      await objectMgr.localStorageMgr.remove(request.md5CacheKey);
      await File(request.sourceFilePath).delete();

      logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
        msg:
            'ImageRequestCompositionHandler 通知合成失败 request:${request.toJson()}',
      ));

      return HandleMsg(
        false,
        message: "Requesting file fail... request:${request.toJson()}",
      );
    }

    logMgr.logUploadImageMgr.addMetrics(LogUploadImageMsg(
      msg:
          'ImageRequestCompositionHandler 请求合成处理器结束 request:${request.toJson()}',
    ));

    request.uploadURLs = response.data!['presign_urls'];
    request.targetURLs =
        ImageUploadResponse.fromJson(response.data!['target_files']);
    if (request.targetURLs!.sourceFile != null &&
        request.targetURLs!.sourceFile!.isNotEmpty) {
      HandleMsg handleMsg = HandleMsg(
        true,
        message: "image_upload_request 358 request:${request.toJson()}",
      );
      await objectMgr.localStorageMgr
          .write(request.finishFileKey, request.file_id);

      return handleMsg;
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: "Composition Completed request:${request.toJson()}",
    );
  }
}

// 暂时不用, 待设计实际使用场景
class ImageDownloadFileHandler
    extends DownloadFileHandlerBase<ImageUploadRequest> {
  ImageDownloadFileHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(ImageUploadRequest request) async {
    throw ();
    // pdebug("Downloading Image...");
    // ConcurrencyLoader concurrencyFileloader = ConcurrencyLoader();
    // String? localPath = await concurrencyFileloader.concurrencyDownloadFile(
    //   request.sourceFilePath,
    //   cancelToken: request.cancelToken,
    // );
    // concurrencyFileloader.dispose();
    // if (localPath == null) {
    //   return HandleMsg(false, "Downloading Image fail...");
    // }

    // if (next != null) return await next!.handleRequest(request);
    // return HandleMsg(true, "Downloading Image success...");
  }
}
