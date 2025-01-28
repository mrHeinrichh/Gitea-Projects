import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/task/queue_task_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/dio/dio_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

class DownLoadQueue {
  Future<String?> downloadQueue(
    dynamic downloadPath, {
    String? savePath,
    int timeoutSeconds = 60,
    int? mini,
    Function(int bytes, int totalBytes)? onReceiveProgress,
    int priority = 0, // 任务优先级
    CancelToken? cancelToken,
  }) async {
    if (downloadPath == null) {
      return null;
    }

    String downloadUrl = '';
    if (downloadPath is String) {
      if (downloadPath.isEmpty) {
        return null;
      } else {
        downloadUrl = downloadPath;
      }
    } else if (downloadPath is Uri) {
      if (downloadPath.isBlank == true) {
        return null;
      } else {
        downloadUrl = downloadPath.toString();
      }
    } else {
      assert(false, 'QUEUE unknow type');
    }

    savePath = savePath ?? downloadMgr.getSavePath(downloadUrl, mini: mini);

    bool isExist = downloadMgr.checkFileExistsSync(savePath);
    if (isExist) {
      return savePath;
    }

    bool isDecode = downloadUrl.contains('enc/');

    Future<Uri?> getRedirect(String downloadUrl,
        {bool shouldRedirect = false, required int? mini}) async {
      final Uri? finalUri = await downloadMgr.getDownloadUrl(downloadUrl,
          mini: mini, shouldRedirect: shouldRedirect);
      return finalUri;
    }

    final Uri? finalUri = await getRedirect(downloadUrl, mini: mini);

    cancelToken ??= CancelToken();
    Future<void> future = queueDownloadTaskMgr.addTask(QueueTask(
        id: finalUri.toString(),
        timeout: Duration(seconds: timeoutSeconds),
        priority: priority,
        task: (cancelToken, shouldRedirect) async {
          final Uri? finalUri = await getRedirect(downloadUrl,
              mini: mini, shouldRedirect: shouldRedirect);
          if (finalUri == null) {
            return TaskResult(
                success: false,
                noRetry: true,
                message: 'line 119',
                shouldRedirect: shouldRedirect);
          }
          try {
            final response = await DioUtil.instance.downloadUriFile(
              finalUri,
              savePath,
              isDecode: isDecode,
              onReceiveProgress: onReceiveProgress,
              cancelToken: cancelToken,
              options: Options(
                sendTimeout: Duration(seconds: timeoutSeconds),
                receiveTimeout: Duration(seconds: timeoutSeconds),
              ),
            );
            final statusCode = response.statusCode;
            if (statusCode == HttpStatus.ok) {
              return TaskResult(success: true);
            } else if (statusCode == HttpStatus.found ||
                statusCode == HttpStatus.forbidden) {
              return TaskResult(
                  success: false,
                  shouldRedirect: true,
                  message: "line 88 ${statusCode}");
            } else {
              return TaskResult(
                  success: false,
                  message: "line 91 ${statusCode}",
                  shouldRedirect: shouldRedirect);
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
                    shouldRedirect: shouldRedirect,
                    message: "line 101 ${e.toString()}");
              }
              // 如果302直接重定向
              else if (statusCode == HttpStatus.found ||
                  statusCode == HttpStatus.forbidden) {
                return TaskResult(
                    success: false,
                    shouldRedirect: true,
                    message: "line 104 ${statusCode}");
              }
              // 其他默认不存在失败
              else {
                return TaskResult(
                  success: false,
                  noRetry: true,
                  shouldRedirect: shouldRedirect,
                  message: "line 110 ${e.toString()}",
                );
              }
            } else {
              // 没有经过请求的内部错误，固定重试倒计时
              return TaskResult(
                  success: false,
                  shouldRedirect: shouldRedirect,
                  message: "line 104 ${e.toString()}");
            }
          }
        },
        onComplete: onTaskComplete,
        onStart: onTaskStart,
        cancelToken: cancelToken));

    try {
      await future;
      if (downloadMgr.checkFileExistsSync(savePath))
        return savePath;
      else
        return null;
    } catch (e) {
      return null;
    }
  }

  void onTaskComplete(QueueTaskEnum status, String str) {
    pdebug("QUEUE download Task completed with status: $status \n ID:$str");
  }

  // 创建一个任务开始回调函数
  void onTaskStart(String str) {
    pdebug("QUEUE download Task started ID:$str");
  }
}
