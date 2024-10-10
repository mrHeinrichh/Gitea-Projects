import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class HeartBeatTask extends ScheduleTask {
  int executeTime = 0;
  bool islongLinkChecking = false;
  HeartBeatTask({
    Duration delay = const Duration(milliseconds: 2000),
  }) : super(delay);

  @override
  Future<void> execute() async {
    executeTime += delay.inMilliseconds;
    if (executeTime >= 59 * 1000) {
      shortLinkCheck();
      executeTime = 0;
    }
    longLinkCheck();
  }

  longLinkCheck() async {
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

  shortLinkCheck() async {
    try {
      final int curTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await heartbeat(curTime);
    } on NetworkException catch (e) {
      pdebug("HeartBeatTask Failed: ${e.getMessage()}");
    } on AppException catch (e) {
      if (e is NetworkException) {
        objectMgr.addCheckKiwiTask();
      }
      pdebug(e.getMessage());
    }
  }
}
