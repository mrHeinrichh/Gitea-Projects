import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import '../api/account.dart';
import '../api/wallet_services.dart';
import '../main.dart';
import '../object/enums/enum.dart';
import '../object/wallet/wallet_settings_bean.dart';
import '../routes.dart';

Future<Map<String, String>> goSecondVerification(
    {bool phoneAuth = false, bool emailAuth = false}) async {
  Map<String, String> tokenMap = {};
  String countryCode = objectMgr.userMgr.mainUser.countryCode;
  String phoneNumber = objectMgr.userMgr.mainUser.contact;
  String emailAddress = await getEmailAddress();
  if (phoneAuth && emailAuth) {
    bool result1 = await getOTP(
        phoneNumber, countryCode, OtpPageType.secondVerification.type);
    if (!result1) {
      showTip();
      return {};
    }

    /// 手机认证
    var resultMap1 = await Get.toNamed(
      RouteName.otpView,
      arguments: {
        'from_view': OtpPageType.secondVerification.page,
        "phoneAuth": true,
      },
    );
    if (resultMap1 != null && resultMap1 is Map<String, dynamic>) {
      tokenMap['phoneToken'] = resultMap1['token'];
    }else{
      showWarningToast("验证码错误");
      return {};
    }
    await Future.delayed(const Duration(milliseconds: 500));
    bool result2 =
        await getOTPByEmail(emailAddress, OtpPageType.secondVerification.type);
    if (!result2) {
      showTip();
      return {};
    }

    /// 邮箱验证码
    var resultMap2 = await Get.toNamed(
      RouteName.otpView,
      arguments: {
        'from_view': OtpPageType.secondVerification.page,
        'emailAuth': true,
      },
    );
    if (resultMap2 != null && resultMap2 is Map<String, dynamic>) {
      tokenMap['emailToken'] = resultMap2['token'];
    }else{
      showWarningToast("验证码错误");
      return {};
    }
  } else {
    if (phoneAuth) {
      bool result1 = await getOTP(
          phoneNumber, countryCode, OtpPageType.secondVerification.type);
      if (!result1) {
        showTip();
        return {};
      }
      var resultMap = await Get.toNamed(
        RouteName.otpView,
        arguments: {
          'from_view': OtpPageType.secondVerification.page,
          "phoneAuth": true,
        },
      );
      if (resultMap != null && resultMap is Map<String, dynamic>) {
        tokenMap['phoneToken'] = resultMap['token'];
      }

      if(tokenMap.isEmpty){
        showWarningToast("验证码错误");
        return {};
      }
    } else {
      bool result = await getOTPByEmail(
          emailAddress, OtpPageType.secondVerification.type);
      if (!result) {
        showTip();
        return {};
      }
      var resultMap = await Get.toNamed(
        RouteName.otpView,
        arguments: {
          'from_view': OtpPageType.secondVerification.page,
          'emailAuth': true,
        },
      );
      if (resultMap != null && resultMap is Map<String, dynamic>) {
        tokenMap['emailToken'] = resultMap['token'];
      }
      if(tokenMap.isEmpty){
        //showWarningToast("验证码错误");
        return {};
      }
    }
  }
  return tokenMap;
}

Future<String> getEmailAddress() async {
  String email = objectMgr.userMgr.mainUser.email;
  if (email.trim().isNotEmpty) {
    return email;
  }
  dynamic res = await walletServices.getSettings();
  if (res.code == 0) {
    WalletSettingsBean bean = WalletSettingsBean.fromJson(res.data);
    if(bean.emailAuthEmail!=null && bean.emailAuthEmail!.trim().isNotEmpty){
      objectMgr.userMgr.mainUser.email=bean.emailAuthEmail!;
    }
    return bean.emailAuthEmail ?? "--";
  }
  return "--";
}

void showTip() {
  showWarningToast("验证码发送失败");
}
