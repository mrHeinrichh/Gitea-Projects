// 上传分片基类
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/managers/log/log_base.dart';
import 'package:jxim_client/managers/task/upload_queue.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/utility.dart';

class UploadChunk extends UploadChunkBase {
  UploadChunk(super.sourceFilePath,
      {super.showOriginal, required super.cancelToken});

  @override
  Map<String, dynamic> toJson() {
    return {
      "file_id": file_id, //文件hash ''  源文件
      "file_typ": file_typ?.value, //文件类型 'Video' 原文件 ‘document’
      "file_ext": file_ext, //文件扩展名 '.mp4' ‘.mp4’
      "total_block": total_block, //分片数量 ''
      "checksums": checksums, //分片md5 ['md5', 'md5']
      "is_kiwi_upload": true, // kiwi上传
      "is_check_md5": true, // 是否校验md5
      "is_encrypt": is_encrypt, // 是否加密
      "is_original": showOriginal, // 是否是源文件
    };
  }

  @override
  Future<bool> initAsync() async {
    File file = File(sourceFilePath);
    bool exist = await file.exists();
    if (exist) {
      int chunkSize = 5 * 1024 * 1024; // 5MB
      totalBytes = await file.length();
      total_block = (totalBytes! / chunkSize).ceil();
      file_ext = getFileExtension2(sourceFilePath);
    }

    return exist;
  }
}

UploadQueue _uploadQueue = UploadQueue();
abstract class UploadChunkBase implements JsonSerializable {
  // 源文件地址
  String sourceFilePath;

  UploadQueue get uploadQueue => _uploadQueue;

  /// 拷贝的目标文件
  /// ! 最终初始化的时候 要把targetFilePath赋值给sourceFilePath
  String? targetFilePath;

  CancelToken cancelToken;

  // 是否发送源文件
  bool showOriginal = false;

  // 源文件md5
  String? file_id;

  // 文件类型
  UploadExt? file_typ;

  // 文件扩展名
  String? file_ext;

  // 切片数量
  int? total_block;

  // 是否加密
  bool _is_encrypt = Config().is_encrypt;

  bool get is_encrypt => _is_encrypt;

  // 文件大小
  int? totalBytes;

  // 上传地址
  Map<String, dynamic>? uploadURLs;

  // // 分片列表
  // List<List<int>>? chunks;

  List<String> checksums = [];

  // 源文件md5
  String sourceMd5 = '';

  // md5缓存的key
  String md5CacheKey = '';

  // 已完成的文件缓存的key
  String finishFileKey = '';

  UploadChunkBase(this.sourceFilePath,
      {this.showOriginal = false, required this.cancelToken});

  // 参数tojson
  Map<String, dynamic> toJson();

  // 用于异步的初始化接口
  Future<bool> initAsync();

  /// 注意事项:
  ///
  /// 路径返回只能是 相对路径, iOS每次重启app | 升级 | 重装app 会导致沙盒路径变化
  /// 绝对路径返回会导致下一次app环境变化的时候, 提供的沙盒id改变导致无法找到文件
  Future<void> copyLocalFile(
      {required String? sourcePath, required String? targetPath}) async {
    if (sourcePath == null || sourcePath.isEmpty) {
      return;
    }
    if (targetPath == null || targetPath.isEmpty) {
      return;
    }

    if (!await File(sourcePath).exists()) {
      return;
    }

    await mkdirPath(targetPath);

    File copiedFile = await File(sourcePath).copy(targetPath);

    if (await copiedFile.exists()) {
      return;
    }
    return null;
  }
}

abstract class UploadResponse {
  UploadExt? typ;
}

int totalTask = 0;

Future<ResponseData> uploadPost(String url,
    {Map<String, dynamic>? data, required CancelToken cancelToken}) async {
  totalTask++;
  int firstPostTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  ResponseData responseData = await _uploadPostSub(url, firstPostTime, 1,
      data: data, cancelToken: cancelToken);
  totalTask--;
  pdebug("==============uploadPost totalTask: $totalTask");
  return responseData;
}

Future<ResponseData> _uploadPostSub(
    String url, int firstPostTime, rePostWaitTime,
    {Map<String, dynamic>? data, required CancelToken cancelToken}) async {
  if (cancelToken.isCancelled) {
    return ResponseData(false);
  }
  try {
    final response = await Request.doPost(url, data: data, timeoutInSeconds: 5);
    if (response.success()) {
      return ResponseData(true, data: response.data);
    } else {
      return ResponseData(false, data: response.data);
    }
  } catch (e) {
    if (e is CodeException) {
      return ResponseData(false, err: e);
    }
    await Future.delayed(Duration(seconds: rePostWaitTime));
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowTime - firstPostTime > 10 * 60) {
      return ResponseData(false);
    } else {
      if (rePostWaitTime > 5) {
        rePostWaitTime = 5;
      }
      return _uploadPostSub(url, firstPostTime, rePostWaitTime + 2,
          data: data, cancelToken: cancelToken);
    }
  }
}

class ResponseData {
  final bool success;
  final Map<String, dynamic>? data;
  final Object? err;

  ResponseData(this.success, {this.data, this.err});

  Map<String, dynamic> toJson() {
    return {
      "data": data,
      "success": success,
    };
  }
}

// 责任链回调
class HandleMsg implements JsonSerializable {
  bool result;
  String? message;

  HandleMsg(this.result, {required this.message}) {
    if (result) {
      pdebug("责任链回调===========$result");
    }
  }

  @override
  String toString() {
    return "result: $result msg: $message";
  }

  factory HandleMsg.fromJson(Map<String, dynamic> json) {
    return HandleMsg(
      json['result'],
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'message': message ?? '',
    };
  }
}

// 责任链接口
abstract class Handler<T extends UploadChunkBase> {
  Handler? next;

  Handler(this.next);

  Future<HandleMsg> handleRequest(T request);
}

class FileEncodeHandler
    extends RequestUploadUrlEncodeHandlerBase<UploadChunkBase> {
  FileEncodeHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(UploadChunkBase request) async {
    if (request.is_encrypt) {
      File file = File(request.sourceFilePath);
      if (await file.exists()) {
        String tmpPath = await downloadMgr
            .getTmpCachePath(request.sourceFilePath, sub: 'enc');
        final File fileTmp = File(tmpPath);
        Uint8List bytes = await file.readAsBytes();
        bytes = await compute<Uint8List, Uint8List>(xorEncode, bytes);
        await fileTmp.writeAsBytes(bytes);

        downloadMgr.updateCacheSubValue(request.sourceFilePath, tmpPath);
        request.sourceFilePath = tmpPath;
      }
    }
    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true,
        message:
            "RequestUploadUrlEncodeHandler Success request:${request.toJson()}");
  }
}

// encode handle
abstract class RequestUploadUrlEncodeHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  RequestUploadUrlEncodeHandlerBase(Handler? next) : super(next);
}

// 请求上传地址处理器
abstract class RequestUploadUrlHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  RequestUploadUrlHandlerBase(Handler? next) : super(next);
}

abstract class RequestUploadCheckCompressHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  RequestUploadCheckCompressHandlerBase(Handler? next) : super(next);
}

// 进行压缩
abstract class RequestUploadCompressHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  RequestUploadCompressHandlerBase(Handler? next) : super(next);
}

// 上传分片处理器
abstract class UploadPartHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  UploadPartHandlerBase(Handler? next) : super(next);
}

// 请求合成处理器
abstract class RequestCompositionHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  RequestCompositionHandlerBase(Handler? next) : super(next);
}

// 轮询合成状态处理器
abstract class PollingCompositionHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  PollingCompositionHandlerBase(Handler? next) : super(next);
}

// 下载文件处理器
abstract class DownloadFileHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  DownloadFileHandlerBase(Handler? next) : super(next);
}

// 下载ts文件处理器
abstract class DownloadTsFileHandlerBase<T extends UploadChunkBase>
    extends Handler<T> {
  DownloadTsFileHandlerBase(Handler? next) : super(next);
}
