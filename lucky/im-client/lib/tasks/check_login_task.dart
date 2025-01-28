import 'package:get/get.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import '../api/account.dart';
import '../main.dart';
import '../managers/object_mgr.dart';
import '../object/account.dart';
import '../object/user.dart';
import '../routes.dart';
import '../utils/lang_util.dart';
import '../utils/localization/app_localizations.dart';
import '../utils/net/app_exception.dart';
import '../utils/net/error_code_constant.dart';
import '../utils/toast.dart';

class CheckLoginTask extends ScheduleTask {
  CheckLoginTask({int delay = 1 * 1000, bool isPeriodic = true})
      : super(delay, isPeriodic);

  @override
  execute() async {
    if (objectMgr.loginMgr.isMobile) return;
    try {
      final responseData = await desktopLoginCheck();
      Get.toNamed(RouteName.desktopLoadingView);
      try {
        ///如果成功的话就会叫API来确认登入
        final bool successLink = await desktopConfirmLogin();
        if (successLink) {
          objectMgr.loginMgr.saveAccount(
            Account.fromJson(responseData),
          );
          final User user = await objectMgr.userMgr.loadUser();
          await objectMgr.prepareDBData(user);

          Get.offAndToNamed(RouteName.desktopHome);
        } else {
          Get.back();
          Toast.showToast(localized(somethingWrongDeviceLinking));
        }
      } on AppException catch (e) {
        pdebug(e.getMessage());
      }
    } on AppException catch (e) {
      ///判断后端传回的错误
      if (e.getPrefix() == ErrorCodeConstant.STATUS_LOGIN_QR_EXPIRED_DESKTOP ||
          e.getPrefix() == ErrorCodeConstant.STATUS_NO_LOGIN_REQUEST) {
        objectMgr.loginMgr.desktopSecret.value = await desktopGenerateQR();
      } else {
        if (e.getPrefix() != ErrorCodeConstant.STATUS_NOT_LOGGED_IN_DESKTOP) {
          // Toast.showToast(e.getMessage());
        }else{
          ///temp solve connecting
          objectMgr.appInitState.value = AppInitState.done;
        }
      }
    }
  }
}
