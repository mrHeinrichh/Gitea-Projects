import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class HeartBeatTask extends ScheduleTask {
  int executeTime = 0;
  HeartBeatTask({int delay = 1000, bool isPeriodic = true}): super(delay, isPeriodic);

  @override
  execute() async {
    executeTime += delay;
    if(executeTime >= 59 * 1000){
      shortLinkCheck();
      executeTime = 0;
    }
    longLinkCheck();
  }

  longLinkCheck() async {
    objectMgr.socketMgr.healthCheck();
  }

  shortLinkCheck() async {
    try {
      final int curTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await heartbeat(curTime);
      
      if (objectMgr.appInitState.value == AppInitState.no_connect ||
          objectMgr.appInitState.value == AppInitState.connecting) {
          objectMgr.appInitState.value = AppInitState.done;
      }
    } on NetworkException catch (e){
      pdebug("HeartBeatTask Failed: ${e.getMessage()}");
    } on AppException catch (e) {
      if (e is NetworkException){
        objectMgr.addCheckKiwiTask();
      }
      pdebug(e.getMessage());
    }
  }
}
