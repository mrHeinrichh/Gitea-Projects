import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:jxim_client/managers/task/queue_task_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/dio/dio_util.dart';

class UploadQueue {
  Future<bool> uploadQueue(
    List<int> chunk,
    String urlPath,
    String fileExt, {
    int timeoutSeconds = 60,
    int priority = 0, // 任务优先级
    required CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    Map<String, dynamic> headers = const {},
  }) async {
    final Uri? uploadUri =
        await serversUriMgr.exChangeKiwiUrl(urlPath, serversUriMgr.uploadUri);
    if (uploadUri == null) {
      return false;
    }
    cancelToken ??= CancelToken();
    Future<void> future = queueUploadTaskMgr.addTask(QueueTask(
        id: urlPath,
        timeout: Duration(minutes: timeoutSeconds),
        priority: priority,
        task: (cancelToken, _) async {
          try {
            Response response = await DioUtil.instance.putUri(
              uploadUri,
              fileExt,
              data: Uint8List.fromList(chunk),
              options: Options(
                method: 'PUT',
                headers: {
                  HttpHeaders.contentTypeHeader: 'application/octet-stream',
                  HttpHeaders.contentLengthHeader: chunk.length,
                  ...headers,
                },
                sendTimeout: const Duration(minutes: 30),
                receiveTimeout: const Duration(minutes: 30),
              ),
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
            );
            final statusCode = response.statusCode;
            if (statusCode == HttpStatus.ok) {
              return TaskResult(success: true);
            } else {
              return TaskResult(
                  success: false, message: "line 88 ${statusCode}");
            }
          } catch (e) {
            if (e is DioException) {
              if (e.type == DioExceptionType.cancel) {
                rethrow;
              }
              final statusCode = e.response?.statusCode;
              // 如果response 不存在直接重试
              if (statusCode == null) {
                return TaskResult(
                    success: false,
                    retryOnNetworkFailure: true,
                    message: "line 101 ${e.toString()}");
              }
              // 其他默认不存在失败
              else {
                return TaskResult(
                  success: false,
                  noRetry: true,
                  message: "line 110 ${e.toString()}",
                );
              }
            } else {
              // 没有经过请求的内部错误，固定重试倒计时
              return TaskResult(
                  success: false, message: "line 104 ${e.toString()}");
            }
          }
        },
        onComplete: onTaskComplete,
        onStart: onTaskStart,
        cancelToken: cancelToken));

    try {
      await future;
      return true;
    } catch (e) {
      return false;
    }
  }

  void onTaskComplete(QueueTaskEnum status, String str) {
    pdebug("QUEUE upload Task completed with status: $status \n ID:$str");
  }

  // 创建一个任务开始回调函数
  void onTaskStart(String str) {
    pdebug("QUEUE upload Task started ID:$str");
  }
}
