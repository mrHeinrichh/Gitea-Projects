part of 'retry_util.dart';

class RetryParameter {
  ///根據自身邏輯，決定重試時，在發起請求後多久算過期，過期就不再重試，單位為分鐘
  ///Ex: expireTime = 5，發起時間為2024/09/12 12:00:00，過期時間為2024/09/12 12:05:00
  ///此重試時間與http request timeout無關，http request timeout是指發起請求後，多久沒有收到response就timeout
  int expireTime = 0;

  ///定義此api請求，當有一樣的api請求時的行為。
  /// int NO_REPLACE = 0;    當有一樣請求已經在佇列中，新加入的一樣再次加入佇列中。
  /// int NEW_PRIORITY = 1;  當有一樣請求已經在佇列中，移除舊的請求，新加入請求為主。
  /// int OLD_PRIORITY = 2;  當有一樣請求已經在佇列中，移除新加入請求，舊的請求為主。
  /// Note:Replace行為不屬於失敗或成功，因此不會呼叫重試回調方法.
  /// ex:
  /// 發送點讚請求'/app/api/moment/like-post'時，若設置為RetryReplace.NO_REPLACE,新的請求一樣再次加入佇列中.
  int isReplaced = RetryReplace.NO_REPLACE;

  ///重試成功後，要執行的callback function名稱
  String callbackFunctionName = "";

  RetryRequestData requestData;

  final int _uuid = RetryMgr.generateNumericUUID();

  RetryParameter({
    required this.expireTime,
    required this.isReplaced,
    required this.callbackFunctionName,
    required String apiPath,
    required String methodType,
    required dynamic data,
    RetryRequestData? requestData,
    bool printBody = false,
    bool needToken = true,
  }) : requestData = requestData ??
            RetryRequestData(
              apiPath,
              data: data,
              attempts: 1,
              refreshAttempts: 1,
              maxTry: 3,
              printBody: printBody,
              needToken: needToken,
              methodType: methodType,
            );

  int getUuid() {
    return _uuid;
  }
}

class RetryRequestData extends RequestData {
  RetryRequestData(
    super.apiPath, {
    required super.data,
    required super.attempts,
    required super.refreshAttempts,
    required super.maxTry,
    required super.printBody,
    required super.needToken,
    required super.methodType,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'apiPath': apiPath,
      'data': data,
      'attempts': attempts,
      'refreshAttempts': refreshAttempts,
      'maxTry': maxTry,
      'printBody': printBody,
      'needToken': needToken,
      'methodType': methodType,
    };
  }

  @override
  factory RetryRequestData.fromJson(Map<String, dynamic> json) {
    return RetryRequestData(
      json['apiPath'] ?? '',
      data: json['data'] ?? {},
      attempts: json['attempts'] ?? 0,
      refreshAttempts: json['refreshAttempts'] ?? 0,
      maxTry: json['maxTry'] ?? 0,
      printBody: json['printBody'] ?? false,
      needToken: json['needToken'] ?? false,
      methodType: json['methodType'] ?? 'POST',
    );
  }

  @override
  bool operator ==(other) {
    return (other is RetryRequestData) &&
        other.apiPath == apiPath &&
        other.data == data &&
        other.attempts == attempts &&
        other.refreshAttempts == refreshAttempts &&
        other.maxTry == maxTry &&
        other.printBody == printBody &&
        other.needToken == needToken &&
        other.methodType == methodType;
  }

  @override
  int get hashCode {
    return apiPath.hashCode ^
        data.hashCode ^
        attempts.hashCode ^
        refreshAttempts.hashCode ^
        maxTry.hashCode ^
        printBody.hashCode ^
        needToken.hashCode ^
        methodType.hashCode;
  }
}
