import 'dart:async';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

// 长链接pingpong
class PingPongTask extends ScheduleTask {
  PingPongTask({
    Duration delay = const Duration(milliseconds: 2000),
  }) : super(delay);

  @override
  Future<void> execute() async {
    _pingpong();
  }

  bool islongLinkChecking = false;

  _pingpong() async {
    if (islongLinkChecking) {
      return;
    }
    islongLinkChecking = true;
    try {
      await objectMgr.socketMgr.healthCheck();
    } finally {
      islongLinkChecking = false;
    }
  }
}
