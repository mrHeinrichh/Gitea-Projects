// ignore_for_file: non_constant_identifier_names

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/offline_request_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/net/response_data.dart';

/// 登录im
Future<HttpResponseBean> login(String token) async {
  return Request.send("/im/chat/login",
      method: Request.methodTypePost, headers: {"token": token});
}

/// 取得正在語音群聊的群組
Future<ResponseData> getTalkingChat() async {
  var res = await Request.doGet("/rhino/talking_chat/get");
  return res;
}

/// 会话列表
Future<ResponseData> list(int user_id, {int? startTime}) async{
   try{
    return await list_sub(user_id, startTime:startTime);
   }catch(e){
    await Future.delayed(const Duration(seconds: 3));
    return await list_sub(user_id, startTime:startTime);
   }
}

/// 会话列表
Future<ResponseData> list_sub(int user_id, {int? startTime}) async {
  dynamic data = {"user_id": user_id};

  if (startTime != null) {
    data['start_time'] = startTime;
  }
  var res = await Request.doPost("/im/chat/list/v2", data: data);
  return res;
}

/// 取会话信息, 参数朋友uid
Future<ResponseData> find_chat({int? friend_id, int? typ}) async {
  final data = {};
  if (friend_id != null) {
    data["friend_id"] = friend_id;
  }
  if (typ != null) {
    data["typ"] = typ;
  }

  return Request.doPost("/im/chat/find_chat", data: data);
}

/// 取会话信息, 参数chat_id
Future<ResponseData> get_chat(int chat_id) async {
  final data = {"chat_id": chat_id};
  return Request.doPost("/im/chat/get_chat", data: data);
}

/// 隐藏会话
/// chat_id 会话id
Future<ResponseData> hide(int user_id, int chat_id, int isHide) async {
  final apiPath = '/im/chat/set_hide';
  final data = {"chat_id": chat_id, "hide": isHide};

  // if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
  //   OfflineRequest req = OfflineRequest(apiPath, data);
  //   objectMgr.offlineRequestMgr.add(req);
  //   return ResponseData();
  // }

  return Request.doPost(apiPath, data: data);
}

/// 删除消息
Future<ResponseData> deleteChat(int chat_id, int hide_msg_idx) async {
  final apiPath = '/im/chat/delete';
  final data = {"chat_id": chat_id, "hide_msg_idx": hide_msg_idx};

  /// 没网的时候把请求加到无网管理器里
  // if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
  //   //暂时把无网删除聊天室的功能移出
  //   Toast.showToast(localized(noNetworkPleaseTryAgainLater));
  //   // OfflineRequest req = OfflineRequest(apiPath, data);
  //   // objectMgr.offlineRequestMgr.add(req);
  //   return ResponseData();
  // }

  return Request.doPost(apiPath, data: data);
}

// -- /chat/clear_message   清空聊天记录
// -- @chat_id     会话ID
// -- @hide_msg_idx 本会话从这边消息id后开始显示
// -- @return      {code:0}
Future<ResponseData> clear_message(int chat_id, int hide_msg_idx,
    {bool isAll = false, int? friendId}) async {
  final apiPath = "/im/chat/clear_message";
  final data = {
    "chat_id": chat_id,
    "hide_msg_idx": hide_msg_idx,
    "is_all": isAll
  };
  if (isAll && friendId != null) {
    data["friend_id"] = friendId;
  }

  // if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
  //   OfflineRequest req = OfflineRequest(apiPath, data);
  //   objectMgr.offlineRequestMgr.add(req);
  //   return ResponseData();
  // }

  return Request.doPost(apiPath, data: data);
}

// -- 置为已读
Future<ResponseData> set_read(int chat_id, int msg_idx) async {
  final apiPath = '/im/chat/set_read';
  final data = {
    "user_id": objectMgr.userMgr.mainUser.uid,
    "chat_id": chat_id,
    "msg_idx": msg_idx
  };

  /// 没网的时候把请求加到无网管理器里
  // if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
  //   OfflineRequest req = OfflineRequest(apiPath, data);
  //   objectMgr.offlineRequestMgr.add(req);
  //   return ResponseData();
  // }

  return Request.doPost(apiPath, data: data);
}

// -- /chat/set_sort   置顶
// -- @uesr_id     针对用户ID
// -- @chat_id     会话ID
// -- @return      {code:0}
Future<ResponseData> set_sort(int user_id, int chat_id, int sort) async {
  final apiPath = '/im/chat/set_sort';
  final data = {"user_id": user_id, "chat_id": chat_id, "sort": sort};

  /// 没网的时候把请求加到无网管理器里
  // if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
  //   OfflineRequest req = OfflineRequest(apiPath, data);
  //   objectMgr.offlineRequestMgr.add(req);
  //   return ResponseData();
  // }

  return Request.doPost(apiPath, data: data);
}

// -- /chat/set_msg_mute 消息免打扰
// -- @uesr_id     针对用户ID
// -- @chat_id     会话ID
// -- @return      {code:0}
Future<ResponseData> set_msg_mute(int user_id, int chat_id, int mute) async {
  dynamic data = {"user_id": user_id};
  data["chat_id"] = chat_id;
  data["mute"] = mute;

  return Request.doPost("/im/chat/set_msg_mute", data: data);
}

/// 置顶某条消息
Future<ResponseData> get_pin_message(List<int> chatId) async {
  final data = {"chat_ids": chatId};
  final res = await Request.doPost("/im/chat/basic/multiple", data: data);
  return res;
}

/// 置顶某条消息
Future<ResponseData> pin_message(int chatId, int messageId) async {
  final data = {"chat_id": chatId};
  data["message_id"] = messageId;

  try {
    final res = await Request.doPost("/im/chat/pin", data: data);
    return res;
  } catch (e) {
    if (e is NetworkException) {
      // Toast.showToast(e.getMessage());
    } else {
      pdebug(e.toString());
    }
    rethrow;
  }
}

/// 取消置顶某条消息
Future<ResponseData> unpin_message(int chatId, int messageId) async {
  final data = {"chat_id": chatId};
  data["message_id"] = messageId;

  final res = await Request.doPost("/im/chat/unpin", data: data);
  return res;
}

Future<ResponseData> unpin_all(int chatId, List<int> messageIds) async {
  final Map<String, dynamic> data = {
    "chat_id": chatId,
    "message_id": messageIds
  };
  data['message_id'] = messageIds;

  final res = await Request.doPost("/im/chat/unpin/all", data: data);
  return res;
}

Future<ResponseData> setAutoDeleteInterval(int chatId, int interval) async {
  final Map<String, dynamic> data = {
    "chat_id": chatId,
    "interval": interval,
  };

  try {
    final res = await Request.doPost("/im/chat/set_auto_delete", data: data);
    return res;
  } catch (e) {
    rethrow;
  }
}

// -- /message/check_valid 校验消息是否有效
// -- @ids             消息id
// -- @return          {code:0, datas = {}}
Future<HttpResponseBean> message_check_valid(List<int> ids) async {
  dynamic data = {};
  data["params"] = ids.join(',');
  return Request.send("/im/message/check_valid",
      method: Request.methodTypePost, data: data);
}

// -- /message/send    发消息
// -- @user_id         接受人id
// -- @send_id         发送者id
// -- @chat_id         会话id
// -- @content         消息内容
// -- @typ             消息类型
// -- @ref_id          引用的消息ID
// -- @return          {code:0, msg:'', data = 1234}
Future<ResponseData> send(
  int user_id,
  int send_id,
  int chat_id,
  int type,
  String content, {
  required int sendTime,
  bool no_unread = false,
  String atUser = '',
  int refId = 0,
  int refType = 0,
}) async {
  Map<String, dynamic> data = {};
  if (user_id != 0) {
    data["user_id"] = user_id;
  }
  data["send_id"] = send_id;
  data["chat_id"] = chat_id;
  data["content"] = content;
  data['send_time'] = sendTime;
  if (no_unread) {
    data["no_unread"] = 1;
  }
  if (atUser.isNotEmpty) {
    data["at_user"] = atUser;
  }
  if (refId != 0) {
    data["ref_id"] = refId;
  }

  if (refType != 0) {
    data['ref_typ'] = refType;
  }

  data["typ"] = type;

  return Request.doPost("/im/message/send", data: data, maxTry: 1);
}

// -- /im/chat/set_screenshot 设置截图权限
// -- @chatID              聊天室id
// -- @enable              开启 = 1, 关闭 = 0
// -- @return          {code:0, data = {}}
Future<ResponseData> setScreenshot(int chatID, int enable) async {
  dynamic data = {};
  data["chat_id"] = chatID;
  data["enable"] = enable;
  return Request.doPost("/im/chat/set_screenshot", data: data, maxTry: 1);
}

// -- /im/chat/screenshot 发送截图动作
// -- @chatID              聊天室id
// -- @type                 0 = 截图，1 = 录屏
// -- @return          {code:0, data = {}}
Future<ResponseData> onScreenshot(int chatID, {int type = 0}) async {
  dynamic data = {};
  data["chat_id"] = chatID;
  return Request.doPost("/im/chat/screenshot", data: data, maxTry: 1, offlineProcess: true);
}

// -- /message/get_msg 取信息
// -- @id              消息内容
// -- @return          {code:0, data = {}}
Future<HttpResponseBean> get_msg(int id) async {
  dynamic data = {};
  data["id"] = id;
  return Request.send("/message/get_msg",
      method: Request.methodTypePost, data: data);
}

/// 编辑消息
/// id 需要编辑的消息ID
/// typ 消息内容类型 如:文本,图片,视频,地理,长文本,音乐,链接
/// content 消息内容 存在大json,格式待定
Future<HttpResponseBean> edit(
    int chat_id, int id, int type, String content, String atStr) async {
  dynamic data = {};
  data["chat_id"] = chat_id;
  data["id"] = id;
  data["content"] = content;
  data["typ"] = type;
  if (atStr.isNotEmpty) {
    data["at_flag"] = atStr;
  }
  return Request.send("/message/edit",
      method: Request.methodTypePost, data: data);
}

/// 删除消息
Future<ResponseData> deleteMsg(int chat_id, List<int> msgIds,
    {bool isAll = false}) async {
  const apiPath = '/im/message/delete';
  final data = {
    "chat_id": chat_id,
    "message_ids": msgIds,
    "all": isAll ? 1 : 0
  };

  try {
    OfflineRequest req = OfflineRequest(apiPath, data);
    objectMgr.offlineRequestMgr.add(req);
    var res =  await Request.doPost(apiPath, data: data);
    objectMgr.offlineRequestMgr.remove(req);
    return res;
  } catch (e) {
    return ResponseData();
  }
}

/// 编辑消息
Future<ResponseData> editMsg(
    int chat_id, int chat_idx, int related_id, String content) async {
  const apiPath = '/im/message/edit';
  final data = {
    "chat_id": chat_id,
    "chat_idx": chat_idx,
    "related_id": related_id,
    "content": content
  };
  try {
    var res = await Request.doPost(apiPath, data: data);
    return res;
  } catch (e) {
    return ResponseData();
  }
}

/// 取得消息历史
/// chat_id 会话id
/// count  查询的消息数量
/// chat_idx 查询的消息最大idx
Future<ResponseData> history(
  int chat_id,
  int chat_idx, {
  int forward = 1,
  int must = 1,
  int count = messagePageCount,
}) async {
  dynamic data = {};

  data["chat_id"] = chat_id;
  data["chat_idx"] = chat_idx;
  data["count"] = count;
  data["must"] = must;
  data["forward"] = forward;
  return Request.doPost("/im/message/history", data: data);
}

Future<ResponseData> getMessageByRemote(String params,
    {int must = 1, int forward = 0, int count = messagePageCount}) async {
  dynamic data = {};

  data["params"] = params;
  data["count"] = count;
  data["must"] = must;
  data["forward"] = forward;
  return Request.doPost("/im/message/historys", data: data);
}

/// 批量取得最新消息列表
///
/// [chatIds] 查询的聊天室 数组ID
///
/// [count]  查询的消息数量
///
/// [must] @value: 0 只加载count数量消息， 1 尽可能的加载到非特殊消息的消息
Future<ResponseData> getChatsLastMessage(
  List<int> chatIds,
  int count, {
  int must = 1,
}) async {
  dynamic data = {"chat_ids": chatIds, "count": count, "must": must};
  return Request.doPost("/im/message/lasts", data: data);
}

/// Get specific typed messages
Future<ResponseData> getTypedMessageByRemote(
  int chatId,
  int chatIdx,
  List<int> types, {
  int count = messagePageCount,
}) async {
  dynamic data = {
    "chat_id": chatId,
    "chat_idx": chatIdx,
    "types": types,
    "count": count,
  };
  return Request.doPost(
    "/im/message/history_with_type",
    data: data,
  );
}

Future<ResponseData> lists(int chat_id, List chatIdxList,
    {int? referID = 0}) async {
  dynamic data = {};
  data["chat_id"] = chat_id;
  data["chat_idx"] = chatIdxList;
  data["refer_id"] = referID;

  return Request.doPost("/im/message/lists", data: data);
}

// -- /message_read/get_message_read_infos 已读消息用户列表
// -- @messageId         消息id
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> getMessageReadInfos(
    int messageId, String? lastId, int pageCount) {
  dynamic data = {};
  data["message_id"] = messageId;
  if (lastId != null) data["last_id"] = lastId;
  data["page_count"] = pageCount;
  return Request.send("/message_read/get_message_read_infos_v2",
      method: Request.methodTypePost, data: data);
}

// -- /message_read/get_message_read_infos 未读消息用户列表
// -- @messageId         消息id
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> getMessageUnreadInfos(
    int messageId, String? lastId, int pageCount) {
  dynamic data = {};
  data["message_id"] = messageId;
  if (lastId != null) data["last_id"] = lastId;
  data["page_count"] = pageCount;
  return Request.send("/message_read/get_message_unread_infos_v2",
      method: Request.methodTypePost, data: data);
}

// -- /message_read/get_message_unread_num 未读消息人数
// -- @messageId         消息id
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> getMessageUnreadNum(int messageId) {
  dynamic data = {};
  data["message_id"] = messageId;
  return Request.send("/message_read/get_message_unread_num",
      method: Request.methodTypePost, data: data);
}

// -- /message_read/read_message 消息已读数量列表
// -- @messageIds         消息ids
// -- @return          {code:0, msg:'', data = 1234}
Future<ResponseData> getMessageReadNum(String messageIds) {
  dynamic data = {};
  data["message_ids"] = messageIds;
  return Request.doPost("/message_read/get_message_read_num", data: data);
}

// -- /message/get_forward_info_list 查询转发消息
// -- @messageIds         消息ids
// -- @return          {code:0, msg:'', data = 1234}
Future<ResponseData> getForwardInfoList(int messageId, int page, int pageSize) {
  dynamic data = {};
  data["message_id"] = messageId;
  data["page"] = page;
  data["page_count"] = pageSize;

  return Request.doPost("/im/message/get_forward_info_list", data: data);
}

Future<ResponseData> getDelMessageWithinTimeRange(
    List<int> chatIds, int startTime, int endTime) async {
  dynamic data = {
    "chat_ids": chatIds,
    "start_time": startTime,
    "end_time": endTime
  };
  return Request.doPost("/im/message/delete/retrieve", data: data);
}

// -- /small_secretary/create_customer_services 小秘书创建客服
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> createCustomerServices() {
  dynamic data = {};
  return Request.send("/small_secretary/create_customer_services",
      method: Request.methodTypePost, data: data);
}

// -- /chat/clean_time
// -- @time   清理时间
// -- @chatId  会话id
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> cleanTime(int time, int chatId) {
  dynamic data = {};
  data["time"] = time;
  data["chat_id"] = chatId;
  return Request.send("/chat_clear_time/clean_time",
      method: Request.methodTypePost, data: data);
}

// -- /voice_text/recognition 语音转译
// -- @msgId  消息id
// -- @return          {code:0, msg:'', data = 1234}
Future<HttpResponseBean> voiceRecognition(int sourceId, int msgId) {
  dynamic data = {};
  data["id"] = sourceId;
  data["msg_id"] = msgId;
  return Request.send("/voice_text/recognition",
      method: Request.methodTypePost, data: data);
}

// // -- /message/text_translate 文字翻译
// // -- @content  内容
// // -- @from  传入语言类型 0.auto
// // -- @to  转出语言类型 0.中文 后期适配国际化
// // -- @id  消息id
// // -- @return          {code:0, msg:'', data = 1234}
// Future<HttpResponseBean> textTranslate(String content, int msgId) {
//   dynamic data = {};
//   data["content"] = content;
//   data["from"] = 0;
//   data["to"] = 0;
//   data["id"] = msgId;
//   return textFanyi(content);
// }

///文本翻译数据请求
Future<HttpResponseBean> textTranslate({
  required String content,
  required String userAgent,
  required int msgId,
  int? frome,
  int? to,
}) async {
  dynamic data = {};
  data['content'] = content;
  data['user_agent'] = userAgent;
  data['id'] = msgId;
  if (frome != null) data['frome'] = frome;
  if (to != null) data['to'] = to;
  return Request.send("/message/text_translate_v2",
      method: Request.methodTypePost, data: data);
}

const languageAUTO = 0; //'AUTO';自动
const languageCN = 1; //'zh'; //中文
const languageEN = 2; //'en'; //英文
const languageJP = 3; //'ja'; //日语
const languageKO = 4; //'ko'; //韩语
const languageFR = 5; //'fr'; //法语
const languageDE = 6; //'de'; //德语
const languageRU = 7; //'ru'; //俄语
const languageSE = 8; //'se'; //西班牙语
const languagePT = 9; //'pt'; //葡萄牙语
const languageIT = 10; //'it'; //意大利语
const languageVI = 11; //'vi'; //越南语
const languageID = 12; //'id'; //印尼语
const languageAR = 13; //'ar'; //阿拉伯语
const languageNL = 14; //'nl'; //荷兰语
const languageTH = 15; //'th'; //泰语

///文本翻译
///@content 翻译内容
///@from 翻译前语言:默认 AUTO
///@to 翻译后语言:默认 AUTO
///@return 翻译结果文本
Future<String> textFanyi(
  String content,
  int msgId, {
  int? from,
  int? to,
}) async {
  // if (_userAgent.isEmpty) {
  //   await FkUserAgent.init();
  //   _userAgent = FkUserAgent.userAgent!;
  // }
  // var rep = await textTranslate(
  //   content: content,
  //   userAgent: _userAgent,
  //   msgId: msgId,
  //   frome: from,
  //   to: to,
  // );
  // if (!rep.success) return '';
  // int type = rep.data['typ'] ?? 0;
  // if (type > 0) return rep.data['text'] ?? ''; //服务端直接翻译
  // String url = rep.data['url'] ?? '';
  // Map? headers = rep.data['headers'];
  // Map? data = rep.data['data'];
  // if (url.isEmpty || headers == null || data == null) return '';
  // await Request.send(url);
  return "";
}

Future<ResponseData> muteSpecificChat(int chat_id, int expireTime) async {
  dynamic data = {"chat_id": chat_id, "expiry": expireTime};
  return Request.doPost("/im/chat/mute", data: data);
}

Future<bool> reportIssue(
    int chatId, int messageId, String category, String description) async {
  final Map<String, dynamic> dataBody = {
    'chat_id': chatId,
    'message_id': messageId,
    'category': category,
    'description': description,
  };

  try {
    final res = await Request.doPost(
      "/im/message/report",
      data: dataBody,
    );
    return res.success();
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  }
}
