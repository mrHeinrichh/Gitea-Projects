import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

//查询免打扰
Future<HttpResponseBean> queryDisturbList(String? lastId, int pageCount) async {
  dynamic data = {};
  if (lastId != null) data["last_id"] = lastId;
  data["page_count"] = pageCount;

  return CustomRequest.send(
    "/chat/query_set_msg_mute_v2",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

//设置免打挠
Future<HttpResponseBean> setMsgMute(int chatId, int mute) async {
  dynamic data = {};
  data["chat_id"] = chatId;
  data["mute"] = mute;

  return CustomRequest.send(
    "/chat/set_msg_mute",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}
