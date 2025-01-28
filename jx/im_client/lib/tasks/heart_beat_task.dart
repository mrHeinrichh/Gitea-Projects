import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

// 短链接
class HeartBeatTask extends ScheduleTask {
  HeartBeatTask({
    Duration delay = const Duration(milliseconds: 58000),
  }) : super(delay);

  @override
  Future<void> execute() async {
    shortLinkCheck();
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
