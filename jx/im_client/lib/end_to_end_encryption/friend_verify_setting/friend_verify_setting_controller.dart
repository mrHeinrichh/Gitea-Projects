import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';

class FriendVerifySettingController extends GetxController{

  void navigateToForgetPasswordPage() {
    Get.toNamed(RouteName.encryptionForgetPwPage);
  }

  void navigateFriendVerifyPage() {
    Get.toNamed(RouteName.encryptionFriendVerifyOtherPage);
  }
}