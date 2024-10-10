import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';

class RetryParameter {
  ///根據自身邏輯，決定重試時，在發起請求後多久算過期，過期就不再重試，單位為分鐘
  ///Ex: expireTime = 5，發起時間為2024/09/12 12:00:00，過期時間為2024/09/12 12:05:00
  ///此重試時間與http request timeout無關，http request timeout是指發起請求後，多久沒有收到response就timeout
  int expireTime = 0;

  int isReplaced = RetryReplace.NO_REPLACE;

  ///重試成功後，要執行的callback function名稱
  String callbackFunctionName = "";

  RetryParameter(
      {required this.expireTime,
      required this.isReplaced,
      required this.callbackFunctionName});
}
