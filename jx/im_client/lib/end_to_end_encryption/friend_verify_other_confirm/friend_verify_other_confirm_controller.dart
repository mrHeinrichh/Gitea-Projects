import 'package:get/get.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class FriendVerifyOtherConfirmController extends GetxController {
  late User user;
  String code = '';

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments["user"] != null) {
        user = Get.arguments["user"];
      }

      if (Get.arguments["code"] != null) {
        code = Get.arguments["code"];
      }
    }
  }

  Future<void> onConfirmClick() async {
    if (user != null && code != ''){
      try {
        bool status = await friendAssistVerify(user.uid, code);
        String message = "";
        if (status) {
          Get.close(2);
          message = "认证成功";
        } else {
          message = "认证失败";
        }

        imBottomToast(
          Get.context!,
          title: message,
          icon: ImBottomNotifType.warning,
        );

      } on AppException catch (e) {
        imBottomToast(
          Get.context!,
          title: e.getMessage(),
          icon: ImBottomNotifType.warning,
        );
      }

    }
  }

  void onNotSureClick() {
    Get.close(2);
  }
}
