import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/status/http_status.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/dio/dio_download_interceptors.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';

class DioUtil {
  static DioUtil get instance => (_instance ??= DioUtil());
  static DioUtil? _instance;

  final BaseOptions _baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.json,
      validateStatus: (status) {
        return status == HttpStatus.ok ||
            status == HttpStatus.found ||
            status == HttpStatus.forbidden ||
            status == HttpStatus.notFound;
      },
      followRedirects: false);

  DioUtil() {}

  /*
   * config it and create
   */
  Dio _getDio() {
    final dio = Dio(_baseOptions);
    dio..interceptors.add(DioDownloadInterceptors(dio: dio));
    return dio;
  }

  /*
   * putUri请求
   */
  Future<Response> putUri(
    Uri uri,
    String fileExt, {
    required Uint8List data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    options ??= Options(method: 'PUT');
    options.headers ??= {};
    options.headers![Headers.contentTypeHeader] = 'application/octet-stream';
    options.headers![Headers.contentLengthHeader] = data.length.toString();

    final fileStream = Stream.value(data);
    Stream<List<int>> stream = fileStream.transform(
      new StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          onSendProgress?.call(data.length, data.length);
          if (cancelToken != null && cancelToken.isCancelled) {
            sink.close();
            return;
          }

          sink.add(data);
        },
        handleError: (error, stack, sink) => sink.close(),
        handleDone: (sink) {
          sink.close();
        },
      ),
    );

    try {
      final response = await Dio().putUri(
        uri,
        data: stream,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _formatError(e);
      rethrow;
    }
  }

  /*
   * 下载文件
   */
  Future<Response> downloadUriFile(Uri uri, dynamic savePath,
      {void Function(int, int)? onReceiveProgress,
      CancelToken? cancelToken,
      Object? data,
      Options? options,
      bool isDecode = false}) async {
    bool deleteOnError = true;
    options ??= _checkOptions('GET', options);
    options.headers ??= {};
    options = options.copyWith(responseType: ResponseType.stream);
    final Response<ResponseBody> response;
    try {
      response = await _getDio().getUri<ResponseBody>(
        uri,
        options: options,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _formatError(e);
      rethrow;
    }

    String uplpadType = '';
    if (uri.origin == serversUriMgr.download1Uri!.origin) {
      // test 强制302
      uplpadType = 'download1Uri';
    } else if (uri.origin == serversUriMgr.download2Uri!.origin) {
      // test 强制302
      uplpadType = 'download2Uri';
    } else {
      uplpadType = 'downloadOthers';
    }

    final completer = Completer<Response>();
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.found) {
      logMgr.logDownloadMgr
        ..addMetrics(LogDownloadMsg(
            msg:
                'uplpadType:$uplpadType 状态码:${response.statusCode} 下载失败地址: ${uri.toString()} 保存地址: $savePath'));
      completer.completeError(
        _assureDioException(null, response.requestOptions, response),
      );
      return completer.future;
    }

    final File fileTmp;
    if (savePath is String) {
      String tmpPath =
          await downloadMgr.getTmpCachePath(savePath, sub: 'savePath');
      fileTmp = File(tmpPath);
    } else {
      throw ArgumentError.value(
        savePath.runtimeType,
        'savePath',
        'The type must be `String`.',
      );
    }

    RandomAccessFile raf = fileTmp.openSync(mode: FileMode.write);

    int received = 0;

    // Stream<Uint8List>
    final stream = response.data!.stream;

    final total = response.data?.contentLength ??
        int.parse(response.headers.value(Headers.contentLengthHeader) ?? '-1');
    if (total <= 0) {
      completer.completeError(
        _assureDioException(null, response.requestOptions, response),
      );
      return completer.future;
    }

    Future<void>? asyncWrite;
    bool closed = false;
    Future<void> closeAndDelete() async {
      if (!closed) {
        closed = true;
        await asyncWrite;
        await raf.close().catchError((_) => raf);
        if (deleteOnError && fileTmp.existsSync()) {
          await fileTmp.delete().catchError((_) => fileTmp);
        }
        final file = File(savePath);
        if (deleteOnError && file.existsSync()) {
          await file.delete().catchError((_) => file);
        }
      }
    }

    Future<void> clearTmpFile() async {
      await downloadMgr.clearTmpCacheFile(uri.toString());
    }

    Future<void> mvFile() async {
      if (fileTmp.existsSync()) {
        final totalTmp = await fileTmp.length();
        if (totalTmp == total) {
          final file = File(savePath);
          file.createSync(recursive: true);
          Uint8List bytes = await fileTmp.readAsBytes();
          if (isDecode)
            bytes = await compute<Uint8List, Uint8List>(xorDecode, bytes);
          await file.writeAsBytes(bytes);
          await fileTmp.delete().catchError((_) => fileTmp);
        } else {
          logMgr.logDownloadMgr.addMetrics(LogDownloadMsg(
              msg:
                  'uplpadType:$uplpadType mvFile 目标文件不一致: 原始大小($total) 实际保存大小($totalTmp) 下载地址:${uri.toString()} 保存地址: $savePath '));
          await closeAndDelete();
        }
        await clearTmpFile();
      }
    }

    if (response.statusCode == HttpStatus.ok) {
      late StreamSubscription subscription;
      subscription = stream.listen(
        (data) {
          subscription.pause();
          // Write file asynchronously
          asyncWrite = raf.writeFrom(data).then((result) {
            // Notify progress
            received += data.length;
            onReceiveProgress?.call(received, total);
            raf = result;
            if (cancelToken == null || !cancelToken.isCancelled) {
              subscription.resume();
            }
          }).catchError((Object e) async {
            try {
              await subscription.cancel().catchError((_) {});
              closed = true;
              await raf.close().catchError((_) => raf);
              if (deleteOnError && fileTmp.existsSync()) {
                await fileTmp.delete().catchError((_) => fileTmp);
              }
            } finally {
              completer.completeError(
                _assureDioException(e, response.requestOptions, response),
              );
            }
          });
        },
        onDone: () async {
          try {
            await asyncWrite;
            closed = true;
            await raf.close().catchError((_) => raf);
            await mvFile();
            completer.complete(response);
          } catch (e) {
            completer.completeError(
              _assureDioException(e, response.requestOptions, response),
            );
          }
        },
        onError: (e) async {
          logMgr.logDownloadMgr.addMetrics(LogDownloadMsg(
              msg:
                  'uplpadType:$uplpadType 流下载失败地址: ${uri.toString()} 保存地址: $savePath error:$e'));
          try {
            await closeAndDelete();
          } finally {
            completer.completeError(
              _assureDioException(e, response.requestOptions, response),
            );
          }
        },
        cancelOnError: true,
      );
      cancelToken?.whenCancel.then((_) async {
        await subscription.cancel();
        await closeAndDelete();
      });
    } else {
      logMgr.logDownloadMgr
        ..addMetrics(LogDownloadMsg(
            msg:
                'uplpadType:$uplpadType 状态码:${response.statusCode} 下载失败地址: ${uri.toString()} 保存地址: $savePath'));
      try {
        await closeAndDelete();
      } finally {
        completer.completeError(
          _assureDioException(null, response.requestOptions, response),
        );
      }
    }

    return _listenCancelForAsyncTask(cancelToken, completer.future);
  }

  Future<T> _listenCancelForAsyncTask<T>(
    CancelToken? cancelToken,
    Future<T> future,
  ) {
    if (cancelToken == null) {
      return future;
    }
    return Future.any([future, cancelToken.whenCancel.then((e) => throw e)]);
  }

  Options _checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    options.headers ??= {};
    return options;
  }

  DioException _assureDioException(Object? error, RequestOptions requestOptions,
      Response<ResponseBody>? response,
      {DioExceptionType type = DioExceptionType.unknown}) {
    if (error is DioException) {
      return error;
    }
    return DioException(
        requestOptions: requestOptions,
        error: error,
        response: response,
        type: type);
  }

  /*
   * error统一处理
   */
  void _formatError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      // It occurs when url is opened timeout.
      pdebug("连接超时 $e");
    } else if (e.type == DioExceptionType.sendTimeout) {
      // It occurs when url is sent timeout.
      pdebug("请求超时 $e");
    } else if (e.type == DioExceptionType.connectionError) {
      // It occurs when url is sent timeout.
      pdebug("连接错误 $e");
    } else if (e.type == DioExceptionType.receiveTimeout) {
      //It occurs when receiving timeout
      pdebug("接收超时 $e");
      // When the server response, but with a incorrect status, such as 404, 503...
    } else if (e.type == DioExceptionType.badResponse) {
      // When the server response, but with a incorrect status, such as 404, 503...
      pdebug("响应异常 $e");
    } else if (e.type == DioExceptionType.badCertificate) {
      // When the server response, but with a incorrect status, such as 404, 503...
      pdebug("证书异常 $e");
    } else if (e.type == DioExceptionType.cancel) {
      // When the server response, but with a incorrect status, such as 404, 503...
      pdebug("请求取消 $e");
    } else if (e.type == DioExceptionType.unknown) {
      // When the request is cancelled, _dio will throw a error with this type.
      pdebug("未知异常 $e");
    }
  }
}
