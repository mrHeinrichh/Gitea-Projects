part of 'upload_util.dart';

class UploadQueue {
  Future<bool> uploadQueue(
    List<int> chunks,
    String urlPath, {
    required CancelToken? cancelToken,
    required String contentMd5,
    Duration timeout = const Duration(seconds: 60),
    int priority = 0, // 任务优先级
    ProgressCallback? onSendProgress,
  }) async {
    final Uri? uploadUri =
        await serversUriMgr.exChangeKiwiUrl(urlPath, serversUriMgr.uploadUri);
    if (uploadUri == null) {
      return false;
    }
    cancelToken ??= CancelToken();
    Future<void> future = queueUploadTaskMgr.addTask(
      QueueUploadTask(
        id: urlPath,
        priority: priority,
        task: (cancelToken) async {
          try {
            final statusCode = await DioUtil.instance.putUri(
              uploadUri,
              chunks: chunks,
              contentMd5: contentMd5,
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
            );
            if (statusCode == HttpStatus.ok) {
              return true;
            } else {
              return false;
            }
          } catch (e) {
            rethrow;
          }
        },
        onComplete: onTaskComplete,
        onStart: onTaskStart,
        cancelToken: cancelToken,
      ),
    );

    try {
      await future;
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void onTaskComplete(QueueUploadTaskEnum status, String str) {
    pdebug("QUEUE upload Task completed ID:$str status: $status");
  }

  // 创建一个任务开始回调函数
  void onTaskStart(String str) {
    pdebug("QUEUE upload Task started ID:$str");
  }
}
