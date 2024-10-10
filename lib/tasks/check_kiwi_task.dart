import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/kiwi_manage.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class CheckKiwiTask extends ScheduleTask {
  int attempt = 1;

  CheckKiwiTask({
    Duration delay = const Duration(milliseconds: 2),
  }) : super(delay);

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
        finish();

        objectMgr.onNetworkOn();
        pdebug("debug info: kiwi connected");
      }
    } else {
      objectMgr.onNetworkOff();
      finish();

      pdebug("debug info: kiwi connect failed");
    }
    attempt++;
  }
}
