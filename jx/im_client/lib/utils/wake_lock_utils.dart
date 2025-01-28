import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
// GooglePlay=====>
import 'package:wakelock_plus/wakelock_plus.dart';
// <=====GooglePlay

class WakeLockUtils {
  static Future<void> disable() async {
    // GooglePlay=====>
    if (objectMgr.callMgr.currentState.value == CallState.Idle) {
      await WakelockPlus.disable();
    }
    // <=====GooglePlay
  }

  static Future<void> enable() async {
    // GooglePlay=====>
    await WakelockPlus.enable();
    // <=====GooglePlay
  }
}