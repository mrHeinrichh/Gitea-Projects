import 'dart:async';
import 'dart:convert';
import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/response_data.dart';

const int customTypeInvite = 1; // 邀请消息
const int customTypeAccept = 2; // 接受邀请
const int customTypeReject = 3; // 拒绝邀请
const int customTypeCancel = 4; // 取消邀请
const int customTypeClose = 5; // 结束邀请（1v1
const int customTypeTimeout = 6; // 超时
const int customTypeBusy = 7; // 忙线中
const int customTypeStartGroupCall = 11; // 讨论组发起通话
const int customTypeCloseGroupCall = 12; // 讨论组结束通话

class SignalingMgr extends EventDispatcher {
  static const eventSignalingUpdate = 'eventSignalingUpdate';
  ChatMgr? _chatMgr;

  init(ChatMgr chatMgr) {
    _chatMgr = chatMgr;
    // _chatMgr!.on(ChatMgr.eventMessageChange, onMessageChange);
  }

  final Map<int, Signaling> _signalings = {};

  // Signaling? getSignaling(int id) {
  //   if (_signalings.containsKey(id)) {
  //     return _signalings[id];
  //   }
  //   return null;
  // }

  // 对方无应答
  // void onTimeout(int chatID, int inviteID, int inviter, {String? data}) async {
  //   List<Signaling> del = [];
  //   for (var item in _signalings.values) {
  //     if (inviteID == item.inviteID) {
  //       item.type = customTypeTimeout;
  //       if (data != null) {
  //         item.data = data;
  //       }
  //       updateSignaling(item);
  //     }
  //
  //     if (item.type > customTypeAccept) {
  //       del.add(item);
  //     }
  //   }
  //   for (var item in del) {
  //     _signalings.remove(item.inviteID);
  //   }
  // }
  //
  // void onMessageChange(Object sender, Object type, Object? data) {
  //   var msg = data as Message;
  //   var signaling = msg.signaling;
  //   if (!signaling.valid) {
  //     return;
  //   }
  //
  //   // 保留最新状态
  //   var cur = getSignaling(signaling.inviteID);
  //   if (cur == null || signaling.type > cur.type) {
  //     if (signaling.checkTimeout(DateTime.now().millisecondsSinceEpoch)) {
  //       signaling.type = customTypeTimeout;
  //       _signalings.remove(signaling.inviteID);
  //     } else {
  //       _signalings[signaling.inviteID] = signaling;
  //     }
  //     updateSignaling(signaling);
  //   }
  // }
  //
  // void updateSignaling(Signaling signaling) {
  //   pdebug("Coming signaling: ${signaling.jsonDataString}");
  //   objectMgr.chatMgr.event(objectMgr.chatMgr, ChatMgr.eventChatMessageChange,
  //       data: signaling.chatID);
  //   event(this, eventSignalingUpdate, data: signaling);
  // }

  //============================== 聊天消息发送 ==================================

  // 单聊邀请
  Future<ResponseData> invite(
    int chatID,
    int inviter, // 邀请者
    int invitee, // 被邀请者
    {
    required String? data,
    int timeout = 0,
    int onlineUserOnly = 0,
    // OfflinePushInfo offlinePushInfo, todo
  }) async {
    var info = InviteInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteeList = [invitee];
    if (data != null) {
      info.data = data;
    }
    info.timeout = timeout;
    info.onlineUserOnly = onlineUserOnly;

    return _chatMgr!.sendCustom(info.chatID, info.jsonDataString);
  }

  // 群聊邀请
  Future<ResponseData> inviteGroup(
    int chatID,
    int inviter, // 邀请者
    List<int> inviteeList, {
    required String? data,
    int timeout = 0,
    int onlineUserOnly = 0,
    // OfflinePushInfo offlinePushInfo, todo
  }) async {
    var info = InviteInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteeList = inviteeList;
    if (data != null) {
      info.data = data;
    }
    info.timeout = timeout;
    info.onlineUserOnly = onlineUserOnly;

    return _chatMgr!.sendCustom(info.chatID, info.jsonDataString);
  }

  // 邀请方取消邀请
  Future<ResponseData> cancel(
    int chatID,
    int inviteID,
    int inviter, // 邀请者
    {
    String? data,
  }) async {
    var info = CancelInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteID = inviteID;
    if (data != null) {
      info.data = data;
    }
    return _chatMgr!
        .sendCustom(info.chatID, info.jsonDataString, noUnread: true);
  }

  // 接收方接受邀请
  Future<ResponseData> accept(int chatID, int inviteID, int inviter, // 邀请者
      {String? data}) async {
    var info = AcceptInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteID = inviteID;
    if (data != null) {
      info.data = data;
    }
    return _chatMgr!
        .sendCustom(info.chatID, info.jsonDataString, noUnread: true);
  }

  // 接收方拒绝邀请
  Future<ResponseData> reject(int chatID, int inviteID, int inviter, // 邀请者
      {String? data}) async {
    var info = RejectInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteID = inviteID;
    if (data != null) {
      info.data = data;
    }
    return _chatMgr!
        .sendCustom(info.chatID, info.jsonDataString, noUnread: true);
  }

  // 接收忙线
  Future<ResponseData> busy(int chatID, int inviteID, int inviter, // 邀请者
      {String? data}) async {
    var info = BusyInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteID = inviteID;
    if (data != null) {
      info.data = data;
    }
    return _chatMgr!
        .sendCustom(info.chatID, info.jsonDataString, noUnread: true);
  }

  // Future<ResponseData> close(int chatID, int inviteID, int inviter, // 邀请者
  //     {String? data}) async {
  //   var info = CloseInfo();
  //   info.chatID = chatID;
  //   info.inviter = inviter;
  //   info.inviteID = inviteID;
  //   if (data != null) {
  //     info.data = data;
  //   }
  //   return _chatMgr!
  //       .sendCall(info.chatID, info.jsonDataString, objectMgr.userMgr.isMe(inviter) ? messageCallerEndCall : messageReceiverEndCall);
  // }

  Future<ResponseData> timeout(int chatID, int inviteID, int inviter, // 邀请者
      {String? data}) async {
    var info = TimeOutInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviteID = inviteID;
    if (data != null) {
      info.data = data;
    }
    return _chatMgr!
        .sendCustom(info.chatID, info.jsonDataString, noUnread: true);
  }

  // 讨论组发起语音通话
  Future<ResponseData> disCall(
    int chatID,
    int inviter, // 邀请者
    String inviterName, // 邀请名
    {
    required String? data,
    int timeout = 0,
    int onlineUserOnly = 0,
  }) async {
    var info = DiscussCallInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.inviterName = inviterName;
    if (data != null) {
      info.data = data;
    }
    info.timeout = timeout;
    info.onlineUserOnly = onlineUserOnly;

    return _chatMgr!.sendGroupCall(info.chatID, info.jsonDataString);
  }

  Future<ResponseData> closeGroupCall(
    int chatID,
    int inviter, // 邀请者
    {
    required String? data,
    String msg = "",
    int timeout = 0,
    int onlineUserOnly = 0,
    // OfflinePushInfo offlinePushInfo, todo
  }) async {
    var info = CloseGroupCallInfo();
    info.chatID = chatID;
    info.inviter = inviter;
    info.msg = msg;
    return _chatMgr!.sendCloseGroupCall(info.chatID, info.jsonDataString);
  }

  Future<void> logout() async {
    // _chatMgr?.off(ChatMgr.eventMessageChange, onMessageChange);
  }
}

class JsonObj {
  final Map<String, dynamic> _jsonData = {};
  Map<String, dynamic> get jsonData => _jsonData;
  String get jsonDataString => jsonEncode(_jsonData);

  /// 根据键值获得值
  setValue(String key, dynamic value) {
    _jsonData[key] = value;
  }

  /// 根据key获得键值
  T getValue<T>(String? key, [dynamic def]) {
    if (key == null) {
      return _jsonData as T;
    }
    if (_jsonData[key] is T) {
      return _jsonData[key];
    }
    return def;
  }
}

// 信令信息
class Signaling extends JsonObj {
  static String typeKey = 'signaling_type';
  // 类型
  int get type => getValue(typeKey, 0);
  set type(int v) => setValue(typeKey, v);
  // 是否信令
  bool get valid => type != 0;
  // 创建时间
  int get createTime => getValue('create_time', 0);
  set createTime(int v) => setValue('create_time', v);
  // 会话ID
  int get chatID => getValue('chat_id', 0);
  set chatID(int v) => setValue('chat_id', v);
  // 邀请id
  int get inviteID => getValue('invite_id', 0);
  set inviteID(int v) => setValue('invite_id', v);
  // 邀请者
  int get inviter => getValue('inviter', 0);
  set inviter(int v) => setValue('inviter', v);
  // 邀请列表
  List<int> get inviteeList => getValue('invitee_list', []);
  set inviteeList(List<int> v) => setValue('invitee_list', v);
  // 邀请数据
  String get data => getValue('data', '');
  set data(String v) => setValue('data', v);
  // 邀请人名字
  String get inviterName => getValue('inviterName', '');
  set inviterName(String v) => setValue('inviterName', v);

  String get msg => getValue('msg', '');
  set msg(String v) => setValue('msg', v);

  String? _dataType;
  // 数据类型
  String? get dataType {
    if (_dataType == null) {
      Map<String, dynamic>? json;
      try {
        json = jsonDecode(data);
      } catch (e) {
        //
      }
      if (json != null && json.containsKey('type')) {
        _dataType = json["type"];
      }
    }
    return _dataType;
  }

  // 超时
  int get timeout => getValue('timeout', 0);
  set timeout(int v) => setValue('timeout', v);
  // 只在线用户
  int get onlineUserOnly => getValue('online_user_only', 0);
  set onlineUserOnly(int v) => setValue('onlineUserOnly', v);

  init(Message msg) {
    if (msg.typ < messageDiscussCall && msg.typ > messageRejectCall) {
      return;
    }
    var json = jsonDecode(msg.content);
    if (json == null) {
      return;
    }
    json.forEach((key, value) {
      if (value != null) {
        setValue(key, value);
      }
    });

    if (type == customTypeInvite) {
      // 邀请 消息id当邀请id
      inviteID = msg.id;
      createTime = msg.create_time;
    }
  }

  /// 根据键值获得值
  @override
  setValue(String key, dynamic value) {
    // _jsonData[key] = value;
    if (key == 'invitee_list') {
      if (value is List) {
        List<int> v = [];
        for (var item in value) {
          v.add(item);
        }
        value = v;
      }
      mypdebug(value);
    } else if (key == 'data') {
      _dataType = null;
    }
    super.setValue(key, value);
  }

  bool checkTimeout(int time) {
    return timeout != 0 && time > createTime + timeout;
  }
}

// 邀请
class InviteInfo extends Signaling {
  InviteInfo() {
    setValue(Signaling.typeKey, customTypeInvite);
  }
}

// 取消
class CancelInfo extends Signaling {
  CancelInfo() {
    setValue(Signaling.typeKey, customTypeCancel);
  }
}

// 接受
class AcceptInfo extends Signaling {
  AcceptInfo() {
    setValue(Signaling.typeKey, customTypeAccept);
  }
}

// 拒绝
class RejectInfo extends Signaling {
  RejectInfo() {
    setValue(Signaling.typeKey, customTypeReject);
  }
}

// 忙线
class BusyInfo extends Signaling {
  BusyInfo() {
    setValue(Signaling.typeKey, customTypeBusy);
  }
}

// 关闭
// class CloseInfo extends Signaling {
//   CloseInfo() {
//     setValue(Signaling.typeKey, customTypeClose);
//   }
// }

// 超时
class TimeOutInfo extends Signaling {
  TimeOutInfo() {
    setValue(Signaling.typeKey, customTypeTimeout);
  }
}

class DiscussCallInfo extends Signaling {
  DiscussCallInfo() {
    setValue(Signaling.typeKey, customTypeStartGroupCall);
  }
}

class CloseGroupCallInfo extends Signaling {
  CloseGroupCallInfo() {
    setValue(Signaling.typeKey, customTypeCloseGroupCall);
  }
}
