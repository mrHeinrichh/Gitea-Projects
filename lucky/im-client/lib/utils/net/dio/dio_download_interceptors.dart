import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:jxim_client/utils/debug_info.dart';

class DioDownloadInterceptors extends RetryInterceptor {
  DioDownloadInterceptors({required super.dio})
      : super(
          // 重试次数
          retries: 1,
          // 重试间隔
          retryDelays: const [
            Duration.zero,
            Duration.zero,
            Duration.zero,
          ],
          retryableExtraStatuses: {HttpStatus.found},
          logPrint: pdebug,
        );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
   
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) {
    return super.onError(err, handler);
  }
}
