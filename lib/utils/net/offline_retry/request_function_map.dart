part of 'retry_util.dart';

class RetryStatus {
  static const int SYNCED_NOT_YET = 0;
  static const int SYNCED_SUCCESS = 1;
  static const int SYNCED_FAILED = -1;
  static const int SYNCED_CANCEL = 2;
  static const int SYNCED_REPLACE = 3;
}

class RetryExpired {
  static const int SYNCED_NOT_EXPIRED = 0;
  static const int SYNCED_EXPIRED = 1;
}

/// New Priority (NP): Remove existing items from the queue when a new item is added, prioritizing the new item.
/// Old Priority (OP): Remove new items from the queue when an existing item is added, prioritizing the old item.
class RetryReplace {
  static const int NO_REPLACE = 0;
  static const int NEW_PRIORITY = 1;
  static const int OLD_PRIORITY = 2;
}

///加入重試後的回調方法名
class RetryEndPointCallback {
  static const String MOMENT_POST_LIKE_RETRY_CALLBACK =
      '/app/api/moment/like-post-v2';

  static const String CHAT_PIN_FAIL_CALLBACK = '/chat/pin/fail-callback';
}

/// `RequestFunctionMap` 資料結構
class RequestFunctionMap {
  ///retryData: 重試的資料，isSuccess: 是否成功
  ///retryData為 [Retry] 資料結構,若成功ResponseData不為null
  final Map<String, Function(Retry retryData, bool isSuccess)> methodMap = {};

  static final RequestFunctionMap _instance = RequestFunctionMap._internal();

  factory RequestFunctionMap() {
    return _instance;
  }

  /// 加入樂觀更新的業務，這邊必須加入重試後的回調方法
  RequestFunctionMap._internal() {
    registerCallback(RetryEndPointCallback.MOMENT_POST_LIKE_RETRY_CALLBACK,
        objectMgr.momentMgr.likeRetryCallback);
    registerCallback(RetryEndPointCallback.CHAT_PIN_FAIL_CALLBACK,
        objectMgr.chatMgr.onLocalPinFail);
  }

  void registerCallback(
      String key, Function(Retry retry, bool isSuccess) callback) {
    if (callback == null) {
      throw ArgumentError('Callback cannot be null');
    }
    methodMap[key] = callback;
  }

  bool containsCallback(String key) {
    return methodMap.containsKey(key);
  }
}
