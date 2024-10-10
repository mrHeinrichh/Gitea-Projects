import 'dart:convert';
import 'package:jxim_client/managers/object_mgr.dart';

// 历史消息拉取
const int ACTION_HISTORY_MSG = 100001;
// 输入状态推送
const int ACTION_SENDINPUT_MSG = 100002;
// 已读状态推送
const int ACTION_SETREAD_MSG = 100003;

socketSend(
  int action,
  dynamic data, {
  bool isBatchExecute = false,
  String requestId = "",
}) async {
  if (requestId == "") {
    requestId = DateTime.now().millisecondsSinceEpoch.toString();
  }
  Map req = {
    "action": action,
    "requestId": requestId,
    "data": data,
  };
  //pdebug("-----action:${action}--requestId:${requestId}--data:${data}");
  String jsonString = json.encode(req);
  return await objectMgr.socketMgr
      .send(jsonString, isBatchExecute: isBatchExecute);
}
