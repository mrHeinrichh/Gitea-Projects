import 'dart:async';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class OnlineTask extends ScheduleTask {
  OnlineTask({
    Duration delay = const Duration(milliseconds: 30000),
  }) : super(delay);

  @override
  Future<void> execute() async {
    _updateOnlineStatus();
  }

  // 更新在线状态
  _updateOnlineStatus() async {
    // 拉取用户数据
    objectMgr.onlineMgr.fetchUserList();
    // 更新在线状态
    objectMgr.onlineMgr.updateOnlineStatus();
  }

  clear() {}
}
