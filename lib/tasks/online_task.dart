import 'dart:async';

import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/format_time.dart';

class OnlineTask extends ScheduleTask {
  OnlineTask({
    Duration delay = const Duration(milliseconds: 60000),
  }) : super(delay);

  @override
  Future<void> execute() async {
    _updateOnlineStatus();
  }

  // 第一次数据是否拿到
  bool _hasFirstInit = false;

  // 更新在线状态
  _updateOnlineStatus() async {
    List<User> users = [];
    // 一分钟请求一次
    List<Chat> callValidChats =
        objectMgr.chatMgr.getAllChats(needProcess: true);
    if (callValidChats.isNotEmpty) {
      try {
        final friendChats = callValidChats
            .map((e) => e.friend_id)
            .where((x) => x != 0)
            .toList();
        friendChats.add(objectMgr.userMgr.mainUser.id);
        users = await getUsersByUID(uidList: friendChats, maxTry: 0);
        _hasFirstInit = true;
      } catch (e) {
        if (objectMgr.onlineMgr.friendOnlineTime.isNotEmpty) {
          objectMgr.onlineMgr.friendOnlineTime.clear();
          objectMgr.onlineMgr.friendOnlineString.clear();
          objectMgr.onlineMgr.event(
            objectMgr.chatMgr,
            OnlineMgr.eventLastSeenStatus,
            data: users,
          );
        }
        await Future.delayed(const Duration(milliseconds: 500));
        resetDelayCount(fource: !_hasFirstInit);
        return;
      }
    }

    if (users.isEmpty) return;

    bool isUpdate = false;
    for (final user in users) {
      //如果是自己，则在线
      if (objectMgr.userMgr.isMe(user.uid)) {
        final int currTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        if (user.lastOnline < currTime) {
          user.lastOnline = currTime;
        }
      }

      if (user.lastOnline > 0) {
        objectMgr.onlineMgr.friendOnlineTime[user.uid] = user.lastOnline;
        objectMgr.onlineMgr.friendOnlineString[user.uid] =
            FormatTime.formatTimeFun(
          objectMgr.onlineMgr.friendOnlineTime[user.uid],
        );
      }
      isUpdate = true;
    }

    if (isUpdate) {
      objectMgr.onlineMgr.event(
        objectMgr.chatMgr,
        OnlineMgr.eventLastSeenStatus,
        data: users,
      );
    }
  }
}
