part of 'retry_util.dart';

final requestQueue = RequestQueue(1);

class _RequestTask {
  bool isCancelled = false;
  bool isReplaced = false;
  bool isRunning = false;
  final Retry retry;
  Completer<ResponseData> completer;
  final RetryRequestData requestData;

  _RequestTask(this.retry, this.completer, this.requestData);
}

class RequestQueue {
  ///重試時間，單位分鐘
  static const int RETRY_TIME_OUT_MINUTES = 1;

  final int maxConcurrent;
  final Queue<_RequestTask> _queue = Queue();

  int _activeRequests = 0;

  RequestQueue(this.maxConcurrent);

  ///expireTime: 自訂過期分鐘數，與產生時間做比對
  Future<void> addRetry(RetryParameter retryParameter) async {
    final completer = Completer<ResponseData>();

    Retry retry = Retry.generate(
      retryParameter.getUuid(),
      retryParameter.requestData.methodType,
      retryParameter.requestData.apiPath,
      jsonEncode(retryParameter.requestData.toJson()),
      RetryStatus.SYNCED_NOT_YET,
      retryParameter.callbackFunctionName,
      RetryExpired.SYNCED_NOT_EXPIRED,
      retryParameter.isReplaced,
      retryParameter.expireTime,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    addRetryWithExistingRetry(retry, completer, retryParameter.requestData);
  }

  ///expireTime: 自訂過期分鐘數，與產生時間做比對
  Future<void> addRetryWithExistingRetry(Retry retry,
      Completer<ResponseData> completer, RetryRequestData requestData,
      {bool isReload = false}) async {
    if (!_queue.any((task) => task.retry.uid == retry.uid)) {
      if (retry.replace != RetryReplace.NO_REPLACE) {
        // Check if a task with the same apiPath exists
        var existingTask = _queue.firstWhereOrNull(
          (task) => task.retry.requestData == retry.requestData,
        );
        //不返回callback，不列入失敗也不列入成功
        if (existingTask != null) {
          if (existingTask.isRunning) {
            //舊的任務會被取消，新的任務會排入佇列.
            if (retry.replace == RetryReplace.NEW_PRIORITY) {
              existingTask.isReplaced = true;
              _queue.add(_RequestTask(retry, completer, requestData));
            } else {
              //新的任務會被忽略,舊的繼續執行.
              return;
            }
          } else {
            //這邊要看是使用新的，還是舊的
            if (retry.replace == RetryReplace.NEW_PRIORITY) {
              _queue.remove(existingTask);
              // Update the retry status to replaced
              await objectMgr.retryMgr.updateRetry(existingTask.retry
                ..synced = RetryStatus.SYNCED_REPLACE
                ..expired = RetryExpired.SYNCED_NOT_EXPIRED);
              _queue.add(_RequestTask(retry, completer, requestData));
            } else {
              //新的任務會被忽略,舊的繼續執行.
              return;
            }
          }
        } else {
          _queue.add(_RequestTask(retry, completer, requestData));
        }
      } else {
        _queue.add(_RequestTask(retry, completer, requestData));
      }
    }

    if (!isReload) {
      await objectMgr.retryMgr.addRetry(retry);
    }

    if (_activeRequests >= maxConcurrent) {
      return;
    }

    _processQueue();

    try {
      ResponseData responseData = await _queue.first.completer.future;
      var temp = _queue.removeFirst();
      temp.retry.responseData = responseData;
      await objectMgr.retryMgr
          .updateRetry(temp.retry..synced = RetryStatus.SYNCED_SUCCESS);
      objectMgr.requestFunctionMap!.methodMap[temp.retry.callbackFun]
          ?.call(temp.retry, true);
    } catch (e) {
      if (e is RetryExpiredException) {
        var temp = _queue.removeFirst();
        await objectMgr.retryMgr.updateRetry(temp.retry
          ..synced = RetryStatus.SYNCED_FAILED
          ..expired = RetryExpired.SYNCED_EXPIRED);
        objectMgr.requestFunctionMap!.methodMap[temp.retry.callbackFun]
            ?.call(temp.retry, false);
      } else if (e is RetryCancelledException) {
        var temp = _queue.removeFirst();
        await objectMgr.retryMgr
            .updateRetry(temp.retry..synced = RetryStatus.SYNCED_CANCEL);
        objectMgr.requestFunctionMap!.methodMap[temp.retry.callbackFun]
            ?.call(temp.retry, false);
      } else if (e is RetryReplacedException) {
        var temp = _queue.removeFirst();
        await objectMgr.retryMgr.updateRetry(temp.retry
          ..synced = RetryStatus.SYNCED_REPLACE
          ..expired = RetryExpired.SYNCED_NOT_EXPIRED);
      } else {
        if(_queue.isNotEmpty){
          var temp = _queue.first;
          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final expireTime = temp.retry.createTime + (temp.retry.expireTime * 60);
          if (currentTime > expireTime) {
            await objectMgr.retryMgr.updateRetry(temp.retry
              ..synced = RetryStatus.SYNCED_FAILED
              ..expired = RetryExpired.SYNCED_EXPIRED);
            objectMgr.requestFunctionMap!.methodMap[temp.retry.callbackFun]
                ?.call(temp.retry, false);
            _queue.removeFirst();
          } else {
            _queue.first.completer = Completer<ResponseData>();
          }
        }
      }
    } finally {
      if (_queue.isNotEmpty) {
        addRetryWithExistingRetry(_queue.first.retry, _queue.first.completer,
            _queue.first.requestData,
            isReload: true);
      }
    }
  }

  void _processQueue() async {
    if (_activeRequests >= maxConcurrent || _queue.isEmpty) {
      return;
    }

    _activeRequests++;
    final task = _queue.first;
    try {
      //1.First timing cancel.
      if (task.isCancelled) {
        task.completer.completeError(RetryCancelledException(
            'Retry cancelled ${task.retry.endPoint} uuid:${task.retry.uid}'));
      } else {
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expireTime = task.retry.createTime + (task.retry.expireTime * 60);
        if (currentTime > expireTime) {
          task.completer.completeError(RetryExpiredException(
              'Retry expired  ${task.retry.endPoint} expireTime:$expireTime'));
        } else {
          task.isRunning = true;
          final response = await _retryRequest(task, task.requestData);
          task.completer.complete(response);
        }
      }
    } catch (e) {
      task.completer.completeError(e);
    } finally {
      _activeRequests--;
    }
  }

  Future<ResponseData> _retryRequest(
      _RequestTask requestTask, RetryRequestData requestData) async {
    const maxDuration = Duration(minutes: RETRY_TIME_OUT_MINUTES);
    final endTime = DateTime.now().add(maxDuration);
    int attempts = 0;

    while (DateTime.now().isBefore(endTime)) {
      //Second timing cancel.
      if (requestTask.isCancelled) {
        throw RetryCancelledException(
            'Retry ${requestTask.retry.endPoint} cancelled uuid:${requestTask.retry.uid}');
      }

      if (requestTask.isReplaced) {
        throw RetryReplacedException(
            'Retry ${requestTask.retry.endPoint} isReplaced uuid:${requestTask.retry.uid}');
      }

      try {
        /// methodTypeGet = "get";
        /// methodTypePost = "post";
        if (requestTask.retry.apiType == CustomRequest.methodTypeGet) {
          return await CustomRequest.doGet(requestData.apiPath,
              data: requestData.data, requestData: requestData);
        } else {
          return await CustomRequest.doPost(requestData.apiPath,
              data: requestData.data, requestData: requestData);
        }
      } catch (e) {
        if (e is CodeException) {
          return ResponseData(
              code: e.getPrefix(), message: e.getMessage(), data: e.getData());
        }
        attempts++;
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      }
    }
    throw TimeoutException(
        'Request failed after $RETRY_TIME_OUT_MINUTES minutes of retries');
  }

  Future<void> restoreQueue() async {
    await objectMgr.retryMgr.deleteFinishRetry();
    //從資料庫中讀取需要重試的資料
    final allRetry = await objectMgr.retryMgr.getAllRetry();
    for (var retry in allRetry) {
      Completer<ResponseData> completer = Completer<ResponseData>();
      addRetryWithExistingRetry(retry, completer,
          RetryRequestData.fromJson(jsonDecode(retry.requestData)),
          isReload: true);
    }
  }

  //給予指定的uuid，取消該uuid的request
  Future<void> cancelRequest(int uuid) async {
    for (var task in _queue) {
      if (task.retry.uid == uuid) {
        task.isCancelled = true;
      }
    }
  }

  ///手動覆蓋任務,會將已經在任務中的請求移除
  Future<void> replacedRequest(int uid) async {
    for (var task in _queue) {
      if (task.retry.uid == uid) {
        if (task.isRunning) {
          task.isReplaced = true;
        } else {
          await objectMgr.retryMgr.updateRetry(task.retry
            ..synced = RetryStatus.SYNCED_REPLACE
            ..expired = RetryExpired.SYNCED_NOT_EXPIRED);
          _queue.remove(task);
        }
        break;
      }
    }
  }
}

class RetryCancelledException implements Exception {
  final String message;

  RetryCancelledException([this.message = 'Retry was cancelled']);

  @override
  String toString() => message;
}

//超過請求者自定義時間
class RetryExpiredException implements Exception {
  final String message;

  RetryExpiredException([this.message = 'Retry was cancelled']);

  @override
  String toString() => message;
}

class RetryReplacedException implements Exception {
  final String message;

  RetryReplacedException([this.message = 'Retry was replaced']);

  @override
  String toString() => message;
}
