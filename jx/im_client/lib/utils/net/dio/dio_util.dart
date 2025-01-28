import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/status/http_status.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/tasks/data_analytics_task.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';

class DioUtil {
  static DioUtil get instance => (_instance ??= DioUtil());
  static DioUtil? _instance;

  final BaseOptions _baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    contentType: Headers.formUrlEncodedContentType,
    responseType: ResponseType.json,
    validateStatus: (status) {
      return status == HttpStatus.ok ||
          status == HttpStatus.found ||
          status == HttpStatus.forbidden ||
          status == HttpStatus.notFound;
    },
    followRedirects: false,
  );

  DioUtil();

  /*
   * config it and create
   */
  Dio _getDio() {
    final dio = Dio(_baseOptions);
    return dio;
  }

  /*
   * putUri请求
   */
  Future<int> putUri(
    Uri uri, {
    required List<int> chunks,
    required CancelToken cancelToken,
    required String contentMd5,
    required Duration timeout,
    ProgressCallback? onSendProgress,
  }) async {
    if (isLocalhost(uri.host)) {
      return await _putUriByLocalHost(uri,
          chunks: chunks,
          contentMd5: contentMd5,
          cancelToken: cancelToken,
          timeout: timeout,
          onSendProgress: onSendProgress);
    } else {
      return await _putUriByCdn(uri,
          chunks: chunks,
          contentMd5: contentMd5,
          cancelToken: cancelToken,
          timeout: timeout,
          onSendProgress: onSendProgress);
    }
  }

  // 通过cdn上传
  Future<int> _putUriByCdn(
    Uri uri, {
    required List<int> chunks,
    required CancelToken cancelToken,
    required String contentMd5,
    required Duration timeout,
    void Function(int, int)? onSendProgress,
  }) async {
    const timeout = Duration(seconds: 10);
    int contentLength = chunks.length;
    final HttpClient httpClient = HttpClient()..connectionTimeout = timeout;
    final file_path = await downloadMgr
        .getTmpCachePath(calculateMD5List(chunks), sub: '_putUriByCdn');
    File file = File(file_path);
    try {
      bool requestIsLive = true;
      HttpClientRequest request = await httpClient.putUrl(uri).timeout(
        timeout,
        onTimeout: () {
          requestIsLive = false;
          httpClient.close(force: true);
          throw TimeoutException('DioUtil _putUriByCdn close timeout');
        },
      );
      request.headers.add(HttpHeaders.contentLengthHeader, "$contentLength");
      request.headers
          .add(HttpHeaders.contentTypeHeader, "application/octet-stream");
      request.headers.add('Content-MD5', contentMd5);
      request.contentLength = contentLength;

      await file.writeAsBytes(chunks);

      final fileStream = file.openRead();

      int bytesUploaded = 0;
      Stream<List<int>> streamUpload = fileStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (!requestIsLive) sink.close();

            onSendProgress?.call(data.length, contentLength);
            bytesUploaded += data.length;
            pdebug(
                'UploadedByCdn $bytesUploaded of $contentLength bytes (${(bytesUploaded / contentLength * 100).toStringAsFixed(2)}%)');
            if (cancelToken.isCancelled) {
              pdebug("【上传文件】上传取消");
              sink.close();
              request.close();
              httpClient.close(force: true);
              return;
            }
            sink.add(data);
          },
          handleError: (error, stack, sink) {
            pdebug("【上传文件】上传错误 : ${error.toString()}");
            sink.close();
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      );

      await request.addStream(streamUpload);
      HttpClientResponse response = await request.close().timeout(
        timeout,
        onTimeout: () {
          requestIsLive = false;
          httpClient.close(force: true);
          throw TimeoutException('DioUtil _putUriByCdn close timeout');
        },
      );
      return response.statusCode;
    } catch (e) {
      // HttpException
      rethrow;
    } finally {
      file.delete().catchError((onError) => file);
    }
  }

  // 通过盾上传
  Future<int> _putUriByLocalHost(
    Uri uri, {
    required List<int> chunks,
    required CancelToken cancelToken,
    required String contentMd5,
    required Duration timeout,
    ProgressCallback? onSendProgress,
  }) async {
    const timeout = Duration(seconds: 10);
    List<int> intList = List<int>.from(chunks);
    int contentLength = chunks.length;
    final http.StreamedRequest request = http.StreamedRequest('PUT', uri);
    request.headers[Headers.contentTypeHeader] = 'application/octet-stream';
    request.headers[Headers.contentLengthHeader] = contentLength.toString();
    request.headers['Content-MD5'] = contentMd5;
    request.contentLength = contentLength;

    bool isClosed = false;

    closeSink() async {
      if (!isClosed) {
        request.sink.close();
        isClosed = true;
      }
    }

    sendData() async {
      int start = 0;
      int end = 0;
      final sinkLen = intList.length;
      int step = 0;
      final maxStep = min(sinkLen, 5000);
      final total = (sinkLen / maxStep).ceil();

      bool hasError = false;
      for (var i = 0; i < total; i += 1) {
        await Future.delayed(
          Duration.zero,
        ).then((_) {
          start = end;
          if (total - 1 == i) {
            step = sinkLen - end;
            end = sinkLen;
          } else {
            step = maxStep;
            end += step;
          }
          onSendProgress?.call(step, sinkLen);
          pdebug(
              'UploadedByLocalHost $end of $sinkLen bytes (${(end / sinkLen * 100).toStringAsFixed(2)}%)');
          request.sink.add(
            intList.sublist(start, end),
          );
        }).catchError((e) {
          cancelToken.cancel();
          hasError = true;
        });

        if (hasError) break;
      }

      closeSink();
    }

    sendData();

    Completer<int> completer = Completer<int>();

    cancelToken.whenCancel.then((_) async {
      closeSink();
    });

    http.Client client = http.Client();
    // 发送请求
    client
        .send(request)
        .timeout(timeout,
            onTimeout: () =>
                throw TimeoutException('DioUtil _putUriByLocalHost timeout'))
        .then((http.StreamedResponse response) async {
      if (response.statusCode == HttpStatus.ok) {
        completer.complete(response.statusCode);
      } else {
        objectMgr.logMgr.logUploadMgr.addMetrics(LogUploadMsg(
          msg:
              '{"uploadHandleRequest":"上传s3返回结果statusCode: ${response.statusCode} 请求头:${request.headers.toString()} 请求url:${uri.toString()}"}',
        ));
        completer.completeError(response);
      }
    }).catchError((onError) {
      completer.completeError(onError);
    }).whenComplete(() {
      closeSink();
      client.close();
    });

    return _listenCancelForAsyncTask(cancelToken, completer.future);
  }

  /*
   * 下载文件
   */
  Future<Response<ResponseBody>> downloadUriFile(
    Uri uri,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    required CancelToken cancelToken,
    Object? data,
    Options? options,
  }) async {
    if (uri.toString().contains(downloadMgr.appCacheRootPath) ||
        uri.path.contains(downloadMgr.appCacheRootPath)) {
      throw Exception('请求url异常,${uri.toString()}');
    }
    if (!uri.origin.contains('http')) {
      throw Exception('请求url异常,${uri.toString()}');
    }

    String decodeStr = '';
    if (uri.toString().contains('secret/')) {
      // 拿到解密的key
      decodeStr = getDecodeKey(uri.toString());
      if (decodeStr.isEmpty) {
        throw Exception('decode异常,${uri.toString()}');
      }
    }

    bool deleteOnError = true;
    options = _checkOptions('GET', options);
    options = options.copyWith(responseType: ResponseType.stream);
    late final Response<ResponseBody> response;
    final dioIns = _getDio();
    try {
      response = await dioIns.getUri<ResponseBody>(
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

    if (response.statusCode != HttpStatus.ok) {
      objectMgr.logMgr.logDownloadMgr.addMetrics(
        LogDownloadMsg(
          msg:
              'uplpadType:$uplpadType 状态码:${response.statusCode} 下载失败地址: ${uri.toString()} 保存地址: $savePath',
        ),
      );
      return response;
    }

    final completer = Completer<Response<ResponseBody>>();
    String tmpPath = await downloadMgr.getTmpCachePath(savePath,
        sub: 'savePath_${UniqueKey()}');
    final File fileTmp = File(tmpPath);
    await fileTmp.delete().catchError((_) => fileTmp);
    RandomAccessFile raf = fileTmp.openSync(mode: FileMode.write);

    int received = 0;

    final stream = response.data!.stream;

    final total = !response.headers.map.containsKey(Headers.contentLengthHeader)
        ? null
        : response.data?.contentLength;

    SumDownloadAnalytics.sharedInstance.updateDownloadStatistic(
      AnalyticsHelper.getFileType(total),
      taskCount: true,
    );

    if (total != null && total <= 0) {
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
        if (total == null || totalTmp == total) {
          final file = File(savePath);
          if (file.existsSync()) {
            pdebug('--------------- file exist');
          } else {
            file.createSync(recursive: true);
            Uint8List bytes = await fileTmp.readAsBytes();
            // 解密
            if (decodeStr.isNotEmpty) {
              bytes = xorDecode(bytes, decodeStr);
            }
            await file.writeAsBytes(bytes).catchError((e) {
              file.delete().catchError((_) => file);
              objectMgr.logMgr.logDownloadMgr.addMetrics(
                LogDownloadMsg(
                  msg:
                      'uplpadType:$uplpadType mvFile check file 目标文件不一致: 原始大小($total) 实际保存大小(${file.length()}) 下载地址:${uri.toString()} 保存地址: $savePath ',
                ),
              );
              throw e;
            });
          }
          await fileTmp.delete().catchError((_) => fileTmp);
        } else {
          objectMgr.logMgr.logDownloadMgr.addMetrics(
            LogDownloadMsg(
              msg:
                  'uplpadType:$uplpadType mvFile totalTmp => file 目标文件不一致: 原始大小($total) 实际保存大小($totalTmp) 下载地址:${uri.toString()} 保存地址: $savePath ',
            ),
          );
          await closeAndDelete();
        }
        await clearTmpFile();
      }
    }

    if (response.statusCode == HttpStatus.ok) {
      final localPath = downloadMgr.checkLocalFile(savePath);
      if (localPath != null && localPath.isNotEmpty) {
        completer.complete(response);
      } else {
        late StreamSubscription subscription;
        subscription = stream.listen(
          (data) {
            subscription.pause();

            // Write file asynchronously
            asyncWrite = raf.writeFrom(data).then((result) {
              // Notify progress
              received += data.length;
              if (total != null && total > 0) {
                onReceiveProgress?.call(received, total);
              }
              raf = result;
              if (!cancelToken.isCancelled) {
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
              await Future.delayed(Duration.zero);
              completer.complete(response);
            } catch (e) {
              completer.completeError(
                _assureDioException(e, response.requestOptions, response),
              );
            }
          },
          onError: (e) async {
            objectMgr.logMgr.logDownloadMgr.addMetrics(
              LogDownloadMsg(
                msg:
                    'uplpadType:$uplpadType 流下载失败地址: ${uri.toString()} 保存地址: $savePath error:$e response:${response.toString()}',
              ),
            );
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
        cancelToken.whenCancel.then((_) async {
          await subscription.cancel().catchError((_) {});
          await closeAndDelete();
        });
      }
    } else {
      objectMgr.logMgr.logDownloadMgr.addMetrics(
        LogDownloadMsg(
          msg:
              'uplpadType:$uplpadType 状态码:${response.statusCode} 下载失败地址: ${uri.toString()} 保存地址: $savePath',
        ),
      );
      try {
        await closeAndDelete();
      } finally {
        completer.completeError(
          _assureDioException(null, response.requestOptions, response),
        );
      }
    }

    return _listenCancelForAsyncTask(cancelToken, completer.future)
        .whenComplete(() {
      dioIns.close(force: true);
    });
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

  DioException _assureDioException(
    Object? error,
    RequestOptions requestOptions,
    Response<ResponseBody>? response, {
    DioExceptionType type = DioExceptionType.unknown,
  }) {
    if (error is DioException) {
      return error;
    }
    return DioException(
      requestOptions: requestOptions,
      error: error,
      response: response,
      type: type,
    );
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

  Future<bool> doPostDownload(
    String apiPath,
    String savePath, {
    dynamic data,
  }) async {
    final Uri uri = Uri.parse(Config().host + apiPath);
    final dioIns = _getDio();
    CancelToken cancelToken = CancelToken();
    try {
      Options options = Options();
      options.method = 'POST';
      options.headers = {
        Headers.contentTypeHeader: 'application/json',
        'token': objectMgr.loginMgr.account?.token,
        'lang': objectMgr.langMgr.currLocale.languageCode,
        'Keep-Alive': 'timeout=30000',
        'Channel': Config().orgChannel,
        'Platform': appVersionUtils.getDownloadPlatform() ?? '',
        'Client-Version': appVersionUtils.currentAppVersion,
      };

      final response = await dioIns.download(uri.toString(), savePath,
          data: data, options: options, cancelToken: cancelToken);

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      pdebug(e);
      return false;
    } finally {
      dioIns.close(force: true);
    }
  }
}
