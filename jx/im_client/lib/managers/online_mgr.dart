import 'dart:math';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';

class OnlineMgr extends EventDispatcher {
  static const String eventLastSeenStatus = 'OnlineMgr.eventLastSeenStatus';

  // 长链接来的key
  static const String socketFriendOnline = "user_last_online";

  // 只能用于记录时间
  final friendOnlineTime = <int, int>{};

  // 所有展示使用这个
  final friendOnlineString = <int, String>{};

  bool _hasInitData = false;
  fetchUserList({bool reload = false}) async {
    // 如果是reload则重置
    if (reload) _hasInitData = false;
    // 拉到以后不做二次请求
    if (_hasInitData) return;
    try {
      List users = await getUserList();
      for (final user in users) {
        int uid = user?['uid'] ?? 0;
        int lastOnline = user?['last_online'] ?? 0;
        int deleted_at = user?['deleted_at'] ?? 0;
        if (uid == 0 || lastOnline == 0) continue;
        //如果是自己，则在线
        if (objectMgr.userMgr.isMe(uid)) {
          final int currTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
          if (lastOnline < currTime) {
            lastOnline = currTime;
          }
        }

        if (deleted_at > 0) {
          friendOnlineString.remove(uid);
          friendOnlineTime.remove(uid);
        } else {
          if (lastOnline > 0) {
            friendOnlineTime[uid] = max(lastOnline, friendOnlineTime[uid] ?? 0);
          }
        }
      }

      friendOnlineTime.forEach((key, value) {
        friendOnlineString[key] = FormatTime.formatTimeFun(
          value,
        );
      });

      event(
        this,
        OnlineMgr.eventLastSeenStatus,
        data: users,
      );
      _hasInitData = true;
    } catch (e) {
      _hasInitData = false;
      pdebug('online_mgr 获取用户信息失败 $e');
    }
  }

  Future<void> _onSocketOpen(a, b, c) async {
    // 己方连上网络马上重新获取联系人在线时间
    fetchUserList(reload: true);

    // 己方连上网络马上触发心跳
    objectMgr.scheduleMgr.heartBeatTask.resetDelayCount(fource: true);
  }

  void _onChatInput(sender, type, data) {
    if (data is ChatInput && data.state != ChatInputState.noTyping) {
      final int currTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      updateOnlineTime(data.sendId, currTime, onlyUpdateExist: true);
    }
  }

  Future<void> logout() async {
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
    objectMgr.chatMgr.off(ChatMgr.eventChatIsTyping, _onChatInput);
    clear();
  }

  Future<void> register() async {
    fetchUserList();

    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
    objectMgr.chatMgr.on(ChatMgr.eventChatIsTyping, _onChatInput);
  }

  // 更新在线时间
  updateOnlineTime(int uid, int lastOnline, {bool onlyUpdateExist = false}) {
    if (lastOnline > 0) {
      // 只更新存在数据
      if (onlyUpdateExist && friendOnlineTime[uid] == null) return;
      friendOnlineTime[uid] = max(lastOnline, friendOnlineTime[uid] ?? 0);
      updateOnlineStatus(uid: uid);
    }
  }

  // 更新在线状态
  updateOnlineStatus({int? uid}) async {
    if (friendOnlineTime.isEmpty) return;
    bool update = false;
    friendOnlineTime.forEach((key, value) {
      if (uid == null || key == uid) {
        final str = FormatTime.formatTimeFun(
          value,
        );
        if (str != friendOnlineString[key]) {
          update = true;
          friendOnlineString[key] = str;
        }
      }
    });
    if (!update) return;
    event(
      this,
      OnlineMgr.eventLastSeenStatus,
      data: [],
    );
  }
}
