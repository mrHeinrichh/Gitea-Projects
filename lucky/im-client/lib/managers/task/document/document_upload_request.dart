import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';

import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:path/path.dart' as path;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';

class DocumentUploadRequest extends UploadChunk {
  DocumentUploadResponse? targetURLs;

  ProgressCallback? onSendProgress;

  DocumentUploadRequest(
    super.sourceFilePath, {
    required super.cancelToken,
    this.onSendProgress,
  }) {
    file_typ = UploadExt.document;
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

// 计算md5
class DocumentCalculateMD5Handler
    extends RequestUploadCompressHandlerBase<DocumentUploadRequest> {
  DocumentCalculateMD5Handler(super.next);

  @override
  Future<HandleMsg> handleRequest(DocumentUploadRequest request) async {
    logMgr.logUploadDocmentMgr.addMetrics(LogUploadDocmentMsg(
        msg: 'VideoCalculateMD5Handler start request:${request.toJson()}'));
    // 每个分片md5的存储变量
    List<Uint8List> md5List = [];

    String sourcePath = request.sourceFilePath;

    // 1、计算md5
    if (!File(request.sourceFilePath).existsSync()) {
      return HandleMsg(
        false,
        message: 'File does not exist request:${request.toJson()}',
      );
    }

    request.sourceMd5 =
        await compute<String, String?>(calculateMD5FromPath, sourcePath) ?? '';

    if (request.sourceMd5.isEmpty) {
      return HandleMsg(
        false,
        message:
            'DocumentCalculateMD5Handler Failed to calculate md5 request:${request.toJson()}',
      );
    }

    request.targetFilePath = downloadMgr.appCacheRootPath +
        '/document' + //这里缓存聊天室id
        '/origin' +
        "/${request.sourceMd5}${path.extension(sourcePath)}";

    await request.copyLocalFile(
      sourcePath: sourcePath,
      targetPath: request.targetFilePath,
    );

    request.md5CacheKey = '/sourceMd5 ${request.sourceMd5}_original';

    Map<String, dynamic>? map;
    try {
      map = objectMgr.localStorageMgr
          .read<Map<String, dynamic>>(request.md5CacheKey);
    } catch (e) {
      objectMgr.localStorageMgr.remove(request.md5CacheKey);
    }

    if (map == null ||
        map.isEmpty ||
        notBlank(map['checksums']) ||
        map['file_id'] == null) {
      final file = File(request.targetFilePath!);
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

      if (request.sourceMd5.isNotEmpty) {
        request.file_id = request.sourceMd5;
      } else {
        Uint8List uint8list = await file.readAsBytes();
        request.file_id = await compute(calculateMD5, uint8list);
      }

      // 赋值给 request.file_id
      request.checksums = md5List.map((e) => convert.base64Encode(e)).toList();
      await objectMgr.localStorageMgr.write<Map<String, dynamic>>(
          request.md5CacheKey,
          {'checksums': request.checksums, 'file_id': request.file_id});
      logMgr.logUploadDocmentMgr.addMetrics(LogUploadDocmentMsg(
        msg:
            'DocumentCalculateMD5Handler 计算分片md5 结束 :  request:${request.toJson()}',
      ));
    } else {
      request.file_id = map['file_id']!;
      request.checksums = [...map['checksums']];
    }

    request.finishFileKey = 'finish_${request.file_id}';
    // request.onCompressCallback?.call(request.targetFilePath!);
    logMgr.logUploadDocmentMgr.addMetrics(LogUploadDocmentMsg(
      msg: 'DocumentCalculateMD5Handler 数据上报:  request:${request.toJson()}',
    ));

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: "VideoCalculateMD5 success... request:${request.toJson()}",
    );
  }
}

// 请求上传地址处理器
class DocumentRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<DocumentUploadRequest> {
  DocumentRequestUploadUrlHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(DocumentUploadRequest request) async {
    var response = await uploadPost('/app/api/file/upload_part_presign',
        data: request.toJson(), cancelToken: request.cancelToken);
    if (!response.success) {
      return HandleMsg(
        false,
        message: 'Failed to obtain upload URLs request:${request.toJson()}',
      );
    }

    request.uploadURLs = response.data!['presign_urls'];

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: 'Requesting upload URLs success... request:${request.toJson()}',
    );
  }
}

class DocumentUploadPartHandler
    extends UploadPartHandlerBase<DocumentUploadRequest> {
  DocumentUploadPartHandler(Handler? next) : super(next);

  // 所有分片总大小
  int totalSize = 0;

  // 已上传大小
  int uploadedSize = 0;

  @override
  Future<HandleMsg> handleRequest(DocumentUploadRequest request) async {
    final file = File(request.sourceFilePath);
    final openedFile = await file.open();
    const chunkSize = 5 * 1024 * 1024; // 5MB
    totalSize = file.lengthSync();

    if (request.uploadURLs!.isNotEmpty) {
      List<Future<bool>> futures = [];

      for (int i = 0; i < request.total_block!; i++) {
        String url = request.uploadURLs!["${i + 1}"] ?? '';
        if (url.isEmpty) {
          uploadedSize += chunkSize;
          continue;
        }

        if (request.cancelToken.isCancelled) {
          return HandleMsg(
            false,
            message:
                'Request canceled, Task Ended. request:${request.toJson()}',
          );
        }

        final start = i * chunkSize;

        final byte = await (await openedFile.setPosition(start))
            .readSync(min(totalSize - start, chunkSize));

        futures.add(request.uploadQueue.uploadQueue(
          byte,
          url,
          request.file_ext!,
          headers: {
            'Content-MD5': request.checksums[i],
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
      message: 'Upload Document Success request:${request.toJson()}',
    );
  }
}

// 请求合成处理器
class DocumentRequestCompositionHandler
    extends RequestCompositionHandlerBase<DocumentUploadRequest> {
  DocumentRequestCompositionHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(DocumentUploadRequest request) async {
    var response = await uploadPost('/app/api/file/upload_part_finish',
        data: request.toJson(), cancelToken: request.cancelToken);
    if (!response.success) {
      pdebug("Requesting file fail...");
      return HandleMsg(
        false,
        message: 'Requesting file fail... request:${request.toJson()}',
      );
    }

    request.uploadURLs = response.data!['presign_urls'];
    request.targetURLs =
        DocumentUploadResponse.fromJson(response.data!['target_files']);

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      true,
      message: 'Composition Completed request:${request.toJson()}',
    );
  }
}
