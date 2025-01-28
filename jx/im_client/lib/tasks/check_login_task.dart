import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/account.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';

class CheckLoginTask extends ScheduleTask {
  CheckLoginTask({
    Duration delay = const Duration(milliseconds: 2000),
  }) : super(delay);

  @override
  execute() async {
    desktopLoginCheck().then((responseData) async {
      if (responseData['login_data'] != null) {
        EncryptionMgr.loginDesktopEncryptionPrivateKey =
            responseData['login_data'];
      }
      // 检查成功会先进loading页面
      Get.toNamed(RouteName.desktopLoadingView);
      try {
        // 开始进行登陆
        final bool successLink = await desktopConfirmLogin();
        if (successLink) {
          objectMgr.loginMgr.saveAccount(
            Account.fromJson(responseData),
          );
          final User user = await objectMgr.userMgr.loadUser();
          await objectMgr.initMainUser(user);
          await objectMgr.prepareDBData(user);

          Get.offAndToNamed(RouteName.desktopHome)!.then((result) {
            if (result != null) {
              finish();
            }
            return result;
          });
        } else {
          Get.back();
          Toast.showToast(localized(somethingWrongDeviceLinking));
        }
      } on AppException catch (e) {
        pdebug(e.getMessage());
      }
    }).catchError((e) async {
      // 失败重新生成二维码
      if (e is AppException || e is CodeException) {
        if (e.getPrefix() ==
                ErrorCodeConstant.STATUS_LOGIN_QR_EXPIRED_DESKTOP ||
            e.getPrefix() == ErrorCodeConstant.STATUS_NO_LOGIN_REQUEST) {
          objectMgr.loginMgr.desktopSecret.value = await desktopGenerateQR();
        }
      } else {
        pdebug(e.toString());
      }
    });
  }
}
