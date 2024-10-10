part of 'upload_util.dart';

class UploadChunk extends UploadChunkBase {
  UploadChunk(
    super.sourceFilePath, {
    required super.cancelToken,
    super.onSendProgress,
    super.fileType,
  });

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
      "is_encrypt": false, // 是否加密
      "sourceFilePath": sourceFilePath, // 源文件地址
      "totalBytes": totalBytes, // 总字节数
    };
  }

  @override
  Future<bool> initAsync() async {
    File file = File(sourceFilePath);
    bool exist = await file.exists();
    if (exist && file.lengthSync() > 0) {
      int chunkSize = 5 * 1024 * 1024; // 5MB
      totalBytes = await file.length();
      totalBlock = (totalBytes! / chunkSize).ceil();
      fileExt = path.extension(sourceFilePath).toLowerCase();
    }

    return exist;
  }

  @override
  Future<void> initMd5() async {
    _sourceMd5 ??=
        await compute<String, String?>(calculateMD5FromPath, sourceFilePath) ??
            '';
    _cacheFilePath = null;
  }

  /// 注意事项:
  ///
  /// 路径返回只能是 相对路径, iOS每次重启app | 升级 | 重装app 会导致沙盒路径变化
  /// 绝对路径返回会导致下一次app环境变化的时候, 提供的沙盒id改变导致无法找到文件
  Future<void> copyLocalFile({
    required String? sourcePath,
    required String? targetPath,
  }) async {
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
    return;
  }

  String get hashPath => path.dirname(cacheFilePath) + '/hash.txt';

  String get cacheFilePath => _cacheFilePath ??= downloadMgr.appCacheRootPath +
      '/upload_cache/$sourceMd5/${path.basename(sourceFilePath)}';
  String? _cacheFilePath;

  Future<void> clear() async {
    await File(sourceFilePath).delete();
    final cacheFile = path.dirname(cacheFilePath);
    await Directory(cacheFile).delete(recursive: true);
  }
}

UploadQueue _uploadQueue = UploadQueue();

abstract class UploadChunkBase implements JsonSerializable {
  // 源文件地址
  String sourceFilePath;

  bool completed = false;

  UploadQueue get uploadQueue => _uploadQueue;

  CancelToken cancelToken;

  // 源文件md5
  String? fileId;

  // 文件类型
  UploadExt? fileType;

  ProgressCallback? onSendProgress;

  // 文件扩展名
  String? fileExt;

  // 切片数量
  int? totalBlock;

  // 文件大小
  int? totalBytes;

  // 上传地址
  UploadResponseData? uploadResponseData;

  List<String> checksums = [];

  // 源文件md5
  String? _sourceMd5;
  String get sourceMd5 => _sourceMd5 ?? '';

  UploadChunkBase(
    this.sourceFilePath, {
    required this.cancelToken,
    this.onSendProgress,
    this.fileType,
  });

  // 参数tojson
  @override
  Map<String, dynamic> toJson();

  // 用于异步的初始化接口
  Future<bool> initAsync();

  Future<void> initMd5();
}

abstract class UploadResponse {
  UploadExt? typ;
}

Future<UploadResponseData> uploadPost(
  String url, {
  Map<String, dynamic>? data,
  required CancelToken cancelToken,
}) async {
  int firstPostTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  UploadResponseData responseData = await _uploadPostSub(
    url,
    firstPostTime,
    1,
    data: data,
    cancelToken: cancelToken,
  );
  return responseData;
}

Future<UploadResponseData> _uploadPostSub(
  String url,
  int firstPostTime,
  rePostWaitTime, {
  Map<String, dynamic>? data,
  required CancelToken cancelToken,
}) async {
  if (cancelToken.isCancelled) {
    return UploadResponseData(false);
  }
  try {
    final response = await CustomRequest.doPost(url, data: data);
    if (response.success()) {
      return UploadResponseData(true, data: response.data);
    } else {
      return UploadResponseData(false, data: response.data);
    }
  } catch (e) {
    if (e is CodeException) {
      return UploadResponseData(false, err: e);
    }
    await Future.delayed(Duration(seconds: rePostWaitTime));
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowTime - firstPostTime > 10 * 60) {
      return UploadResponseData(false);
    } else {
      if (rePostWaitTime > 5) {
        rePostWaitTime = 5;
      }
      return _uploadPostSub(
        url,
        firstPostTime,
        rePostWaitTime + 2,
        data: data,
        cancelToken: cancelToken,
      );
    }
  }
}

class UploadResponseData {
  final bool success;
  final Map<String, dynamic>? data;
  final Object? err;

  // 上传地址
  Map<String, dynamic> _uploadURLs = {};
  Map<String, dynamic> _target_files = {};

  Map<String, dynamic> get uploadURLs => _uploadURLs;

  Map<String, dynamic> get target_files => _target_files;

  UploadResponseData(this.success, {this.data, this.err}) {
    _uploadURLs = data?['presign_urls'] ?? {};
    _target_files = data?['target_files'] ?? {};
  }

  Map<String, dynamic> toJson() {
    if (err is CodeException) {
      return {
        "data": data,
        "success": success,
        "err": (err as CodeException).getMessage(),
      };
    }
    return {"data": data, "success": success, "err": err.toString()};
  }
}

// 责任链回调
class HandleMsg implements JsonSerializable {
  bool result;
  bool isClearAll;
  String? message;

  HandleMsg(this.result, {required this.message, this.isClearAll = false}) {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'message': message ?? '',
    };
  }
}

// 参数构造
class RequestInitHandler<T extends UploadChunk>
    extends RequestInitHandlerBase<T> {
  RequestInitHandler(super.next);

  @override
  Future<HandleMsg> handle(T request) async {
    if (!await request.initAsync()) {
      return HandleMsg(
        false,
        message: "请求参数构造失败  request: ${request.toJson()}",
      );
    }

    return HandleMsg(true, message: "请求参数构造成功 request:${request.toJson()}");
  }
}

// 计算源文件md5
class CalculateMD5Handler<T extends UploadChunk>
    extends _CalculateMD5HandlerBase<T> {
  CalculateMD5Handler(super.next);

  @override
  Future<HandleMsg> handle(T request) async {
    await request.initMd5();
    if (request.sourceMd5.isEmpty) {
      return HandleMsg(false, message: "计算源文件md5失败");
    }
    if (File(request.cacheFilePath).existsSync() == false) {
      File(request.hashPath).createSync(recursive: true);
      IOSink sink = File(request.hashPath).openWrite(mode: FileMode.write);
      try {
        sink.writeln(request.sourceMd5); // 写入带有换行符的文本行
      } catch (e) {
        rethrow;
      } finally {
        sink.close(); // 关闭文件流
      }
      await request.copyLocalFile(
        sourcePath: request.sourceFilePath,
        targetPath: request.cacheFilePath,
      );
    }
    request.sourceFilePath = request.cacheFilePath;
    request.fileId = request.sourceMd5;
    return HandleMsg(true, message: "计算源文件md5成功 request:${request.toJson()}");
  }
}

class CalculateMD5Base64Handler<T extends UploadChunk>
    extends _CalculateMD5Base64HandlerBase<T> {
  CalculateMD5Base64Handler(super.next);

  @override
  Future<HandleMsg> handle(T request) async {
    String logs = '';
    if (File(request.cacheFilePath).existsSync() &&
        File(request.hashPath).existsSync() &&
        File(request.hashPath).readAsLinesSync().length > 1) {
      final md5List = File(request.hashPath).readAsLinesSync()..removeAt(0);
      request.checksums = md5List;
      logs = '缓存';
    } else {
      // 每个分片md5的存储变量
      List<Uint8List> md5List = [];

      final file = File(request.sourceFilePath);
      final openedFile = await file.open();
      const chunkSize = 5 * 1024 * 1024; // 5MB
      int totalSize = file.lengthSync();

      // for 循环文件分片
      for (int index = 0; index < request.totalBlock!; index++) {
        final start = index * chunkSize;

        final byte = (await openedFile.setPosition(start))
            .readSync(min(totalSize - start, chunkSize));

        // 计算每个分片的md5
        md5List.add(await compute(calculateMD5Bytes, byte));
      }

      request.checksums = md5List.map((e) => convert.base64Encode(e)).toList();

      IOSink sink = File(request.hashPath).openWrite(mode: FileMode.append);
      try {
        for (var line in request.checksums) {
          sink.writeln(line); // 写入带有换行符的文本行
        }
      } catch (e) {
        rethrow;
      } finally {
        sink.close(); // 关闭文件流
        openedFile.close();
      }
    }

    return HandleMsg(
      true,
      message: "计算md5base64成功 $logs request:${request.toJson()}",
    );
  }
}

class UploadPartHandler<T extends UploadChunk>
    extends _UploadPartHandlerBase<T> {
  UploadPartHandler(super.next);

  // 所有分片总大小
  int totalSize = 0;

  // 已上传大小
  int uploadedSize = 0;

  @override
  Future<HandleMsg> handle(T request) async {
    if (request.uploadResponseData!.success &&
        request.uploadResponseData!.uploadURLs.isEmpty &&
        request.uploadResponseData!.target_files.isEmpty) {
      return HandleMsg(
        true,
        message:
            '直接通知合成 response:${request.toJson()}  request:${request.toJson()}',
      );
    }

    final file = File(request.sourceFilePath);
    final openedFile = await file.open();
    const chunkSize = 5 * 1024 * 1024; // 5MB
    totalSize = file.lengthSync();
    uploadedSize = 0;
    if (request.uploadResponseData!.uploadURLs.isEmpty) {
      return HandleMsg(
        false,
        message: '上传s3失败 presign_urls isEmpty  request:${request.toJson()}',
      );
    }

    if (request.checksums.length != request.totalBlock) {
      return HandleMsg(
        false,
        message: '上传s3失败 checksums 长度不一致  request:${request.toJson()}',
      );
    }

    List<Future<bool>> futures = [];
    for (int i = 0; i < request.totalBlock!; i++) {
      String? url = request.uploadResponseData!.uploadURLs["${i + 1}"];
      if (url == null || url.isEmpty) continue;

      final start = i * chunkSize;

      final byte = (await openedFile.setPosition(start))
          .readSync(min(totalSize - start, chunkSize));

      futures.add(
        request.uploadQueue.uploadQueue(
          byte,
          url,
          contentMd5: request.checksums[i],
          timeout: const Duration(seconds: 600),
          cancelToken: request.cancelToken,
          onSendProgress: (int sent, int total) {
            uploadedSize += sent;
            request.onSendProgress?.call(uploadedSize, totalSize);
          },
        ),
      );
    }

    try {
      List<bool> allResults = await Future.wait(futures);

      bool anyFail = allResults.any((element) => element == false);

      if (anyFail) {
        return HandleMsg(false, message: "上传s3失败 request: ${request.toJson()}");
      }

      return HandleMsg(
        true,
        message: '上传成功到s3成功 request:${request.toJson()}',
      );
    } catch (e) {
      rethrow;
    } finally {
      openedFile.close();
    }
  }
}

// 责任链接口
abstract class Handler<T extends UploadChunk> with PrepareHandleMaxin<T> {
  Handler? next;

  Handler(this.next);

  Future<HandleMsg> handleRequest(T request) async {
    HandleMsg? result;
    final stopwatch = Stopwatch()..start();
    try {
      if (request.cancelToken.isCancelled) {
        return HandleMsg(
          false,
          message: '上传s3失败 任务被取消 request:${request.toJson()}',
        );
      }
      request = await prepareHandle(request);

      // 调用子类的处理方法
      result = await handle(request);
      stopwatch.stop();

      logger.i(
        '{"uploadHandleRequest":"$runtimeType ${result.toString()}", "execution_time": ${stopwatch.elapsedMilliseconds}}',
      );
    } catch (e, stackTrace) {
      if (result == null ||
          (result.result == false && result.isClearAll == true)) {
        request.clear();
      }
      logger.e(
        '"uploadHandleRequest":"Error in $runtimeType", "stackTrace": "$stackTrace","e":"$e"',
        e,
        stackTrace,
      );
      rethrow; // 重新抛出异常，以便上层调用者也能处理
    } finally {
      stopwatch.stop();
    }

    // 返回失败，清除
    if (result.result == false && result.isClearAll == true) {
      request.clear();
      return result;
    }
    // 成功
    if (request.completed) {
      request.onSendProgress?.call(
        request.totalBytes ?? 1,
        request.totalBytes ?? 1,
      );
      return result;
    }

    // 有没有下一步
    if (next != null) {
      result = await next!.handleRequest(request);
    }
    return result;
  }

  // 子类必须实现这个方法来处理请求
  Future<HandleMsg> handle(T request);

  @override
  @mustCallSuper
  Future<T> prepareHandle(T request) async {
    return request;
  }
}

mixin PrepareHandleMaxin<T extends UploadChunk> {
  // 预处理数据
  Future<T> prepareHandle(T request);
}

// 请求上传地址处理器
abstract class RequestUploadUrlHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  RequestUploadUrlHandlerBase(super.next);
}

// 构造参数
abstract class RequestInitHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  RequestInitHandlerBase(super.next);
}

// 进行压缩
abstract class RequestUploadCompressHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  RequestUploadCompressHandlerBase(super.next);
}

abstract class RequestCoverHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  RequestCoverHandlerBase(super.next);
}

// md5
abstract class _CalculateMD5HandlerBase<T extends UploadChunk>
    extends Handler<T> {
  _CalculateMD5HandlerBase(super.next);
}

// md5 part base64
abstract class _CalculateMD5Base64HandlerBase<T extends UploadChunk>
    extends Handler<T> {
  _CalculateMD5Base64HandlerBase(super.next);
}

// 上传分片处理器
abstract class _UploadPartHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  _UploadPartHandlerBase(super.next);
}

// 请求合成处理器
abstract class RequestCompositionHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  RequestCompositionHandlerBase(super.next);
}

// 下载文件处理器
abstract class DownloadFileHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  DownloadFileHandlerBase(super.next);
}

// 下载ts文件处理器
abstract class DownloadTsFileHandlerBase<T extends UploadChunk>
    extends Handler<T> {
  DownloadTsFileHandlerBase(super.next);
}
