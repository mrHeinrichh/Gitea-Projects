import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/kiwi_manage.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class CheckKiwiTask extends ScheduleTask {
  int attempt = 1;

  CheckKiwiTask({
    int delay = 2,
    bool isPeriodic = true,
  }) : super(delay, isPeriodic);

  @override
  execute() async {
    /// maximum 3 attempt
    if (attempt <= 3) {
      try {
        objectMgr.appInitState.value = AppInitState.connecting;
        await kiwiMgr.initKiwi();
      } on AppException catch (e) {
        pdebug(e.getMessage());
      }

      if (serversUriMgr.isKiWiConnected) {
        objectMgr.appInitState.value = AppInitState.done;
        objectMgr.scheduleMgr.checkKiwiTask.finished = true;

        objectMgr.onNetworkOn();
        pdebug("debug info: kiwi connected");
      }
    } else {
      objectMgr.appInitState.value = AppInitState.no_connect;
      objectMgr.scheduleMgr.checkKiwiTask.finished = true;

      pdebug("debug info: kiwi connect failed");
    }
    attempt++;
  }
}
