import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import '../../../api/wallet_services.dart';
import '../../../utils/net/response_data.dart';
import '../../../utils/second_verification_utils.dart';

class PaymentTwoFactorAuthController extends GetxController {
  final paymentTwoFactorAuthSwitch = false.obs;

  onInit() {
    super.onInit();
    if (Get.arguments != null) {
      paymentTwoFactorAuthSwitch.value =
          Get.arguments['isPayTwoFactorAuthEnable'] ??
              false;
    }
  }

  /// 开启不需要认证，关闭需要
  Future<void> setPaymentTwoFactorAuthSwitch(bool value) async {
    if (value) {
      openTwoFactorAuthSettingsUpdate(value);
    } else {
      closeTwoFactorAuthSettingsUpdate(value);
    }
  }

  /// 开启认证
  Future<void> openTwoFactorAuthSettingsUpdate(bool value) async {
    Map<String, dynamic> map = {"pay_two_factor_auth_enable": 1};
    ResponseData res =
        await walletServices.postTwoFactorAuthSettingsUpdate(map);
    if (res.code == 0) {
      paymentTwoFactorAuthSwitch.value = value;
    } else {
      showWarningToast(res.message);
      paymentTwoFactorAuthSwitch.value = false;
    }
  }

  ///关闭认证
  Future<void> closeTwoFactorAuthSettingsUpdate(bool value) async {
    Map<String, dynamic> map = {"pay_two_factor_auth_enable": 0};
    ResponseData res =
        await walletServices.postTwoFactorAuthSettingsUpdate(map);
    if (res.code == 0) {
      bool isPhoneAuth = res.data["phoneVcodeSend"]??false;
      bool emailAuth = res.data["emailVcodeSend"]??false;
      Map<String,String> tokenMap= await goSecondVerification(phoneAuth: isPhoneAuth,emailAuth: emailAuth);
      if(tokenMap.isEmpty){
        return;
      }
      Map<String, dynamic> map2 = {
        "pay_two_factor_auth_enable": 0,
      };
      tokenMap.forEach((key, value) {
        if(key =="phoneToken"){
          map2['phone_token'] = value;
        }else if(key =="emailToken"){
          map2['email_token'] = value;
        }
      });
      ResponseData res2 =
      await walletServices.postTwoFactorAuthSettingsUpdate(map2);
      if (res2.code == 0) {
        paymentTwoFactorAuthSwitch.value = false;
      } else {
        showWarningToast(res2.message);
      }
    } else {
      showWarningToast(res.message);
      paymentTwoFactorAuthSwitch.value = false;
    }
  }
}
