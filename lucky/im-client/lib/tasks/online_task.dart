import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';

import '../managers/chat_mgr.dart';

class OnlineTask extends ScheduleTask {
  OnlineTask({int delay = 3*1000, bool isPeriodic = true})
      : super(delay, isPeriodic);
  int executeTime = 60 * 1000;
  List<User> users = [];
  Map<int,String>  onlineDecs = {};

  @override
  execute() async {
    executeTime += delay;
    if (executeTime >= 57 * 1000) {
      List<Chat> callValidChats = objectMgr.chatMgr.getAllChats(need_process: true);
      if (callValidChats.isNotEmpty) {
        try {
          final friendChats =
              callValidChats.map((e) => e.friend_id).where((x) => x != 0).toList();
          friendChats.add(objectMgr.userMgr.mainUser.id);
          users = await getUsersByUID(uidList: friendChats);
        } catch (e) {
          mypdebug('FetchOnlineUsersFailed：$e');
        }
      }
      executeTime = 0;
    }

    var isUpdate = false;
    for (final user in users) {
      User? u = objectMgr.userMgr.getUserById(user.uid);
      if (u == null) {
        continue;
      }
      if (u.lastOnline > user.lastOnline) {
        user.lastOnline = u.lastOnline;
      }else{
        u.lastOnline = user.lastOnline;
      }

      //如果是自己，则在线
      if(objectMgr.userMgr.isMe(user.uid)){
        user.lastOnline = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1;
      }

      objectMgr.userMgr.friendOnlineTime[user.uid] = user.lastOnline;
      objectMgr.userMgr.friendOnline[user.uid] = FormatTime.isOnline(user.lastOnline);
      if (onlineDecs.containsKey(user.uid)) {
        var newDsc = FormatTime.formatTimeFun(user.lastOnline);
        if (newDsc != onlineDecs[user.uid]) {
          onlineDecs[user.uid] = newDsc;
          isUpdate = true;
        }
      } else {
        onlineDecs[user.uid] = FormatTime.formatTimeFun(user.lastOnline);
        isUpdate = true;
      }
    }
   
    if (isUpdate) {
      objectMgr.chatMgr.event(objectMgr.chatMgr, ChatMgr.eventLastSeenStatus, data: users);
    }
  }

  doExecute(){
    executeTime = 60 * 1000;
    objectMgr.scheduleMgr.onlineTask.execute();
  }
}
