import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/wallet/wallet_settings_bean.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';

import 'package:jxim_client/utils/lang_util.dart';

class AuthMethodController extends GetxController {
  final phoneNumAuthSwitch = false.obs;
  final emailAuthSwitch = false.obs;
  final emailAuthEmail = "".obs;
  final phoneAuthContact = "".obs;
  final phoneAuthCountryCode = "".obs;

  @override
  void onInit() async {
    phoneAuthCountryCode.value = objectMgr.userMgr.mainUser.countryCode;
    phoneAuthContact.value = objectMgr.userMgr.mainUser.contact;
    emailAuthEmail.value = objectMgr.userMgr.mainUser.email;
    final arguments = Get.arguments;
    if (arguments != null) {
      if (arguments['emailAuthEmail'] != null) {
        emailAuthEmail.value = arguments['emailAuthEmail'];
      }
      if (arguments['emailAuthEnable'] != null) {
        emailAuthSwitch.value = arguments['emailAuthEnable'] == 1;
      }
      if (arguments['phoneAuthContact'] != null) {
        phoneAuthContact.value = arguments['phoneAuthContact'];
      }
      if (arguments['phoneAuthCountryCode'] != null) {
        phoneAuthCountryCode.value = arguments['phoneAuthCountryCode'];
      }
      if (arguments['phoneAuthEnable'] != null) {
        phoneNumAuthSwitch.value = arguments['phoneAuthEnable'] == 1;
      }
    }
    super.onInit();
  }

  Future<void> setPhoneNumAuthSwitch(bool value) async {
    if (phoneAuthContact.isNotEmpty && phoneAuthCountryCode.isNotEmpty) {
      if (value == false && emailAuthSwitch.value == false) {
        showWarningToast(localized(authDescriptionEnabledVerification));
        return;
      }

      /// 不管打开还是关闭的时候都需要验证
      updateSettings(value, true);
    } else {
      showWarningToast("请先设置手机号码");
      phoneNumAuthSwitch.value = false;
    }
  }

  Future<void> setEmailAuthSwitch(bool value) async {
    if (emailAuthEmail.isNotEmpty) {
      if (value == false && phoneNumAuthSwitch.value == false) {
        showWarningToast(localized(authDescriptionEnabledVerification));
        return;
      }

      /// 至少认证一个
      updateSettings(value, false);
    } else {
      showWarningToast("请先设置邮箱");
      emailAuthSwitch.value = false;
    }
  }

  ///需要刷新
  String get getPhoneStr {
    return "$phoneAuthCountryCode $phoneAuthContact";
  }

  /// 需要刷新
  String get getEmailStr {
    return "$emailAuthEmail";
  }

  ///手机号和邮箱验证 关闭需要对应的验证码，开启不需要
  Future<void> updateSettings(bool isOpen, bool isPhoneAuth) async {
    int value = isOpen ? 1 : 0;
    Map<String, dynamic> map = {};
    if (isPhoneAuth) {
      map = {"phone_auth_enable": value};
    } else {
      map = {"email_auth_enable": value};
    }
    ResponseData res =
        await walletServices.postTwoFactorAuthSettingsUpdate(map);
    if (res.code == 0) {
      if (isOpen) {
        if (isPhoneAuth) {
          phoneNumAuthSwitch.value = isOpen;
        } else {
          emailAuthSwitch.value = isOpen;
        }
      } else {
        Map<String, String> tokenMap = await goSecondVerification(
          phoneAuth: isPhoneAuth,
          emailAuth: !isPhoneAuth,
        );
        if (tokenMap.isEmpty) {
          if (isPhoneAuth) {
            phoneNumAuthSwitch.value = !isOpen;
          } else {
            emailAuthSwitch.value = !isOpen;
          }
          return;
        }
        tokenMap.forEach((key, value) {
          if (key == "phoneToken") {
            map['phone_token'] = value;
          } else if (key == "emailToken") {
            map['email_token'] = value;
          }
        });
        ResponseData res2 =
            await walletServices.postTwoFactorAuthSettingsUpdate(map);
        if (res2.code == 0) {
          if (isPhoneAuth) {
            phoneNumAuthSwitch.value = isOpen;
          } else {
            emailAuthSwitch.value = isOpen;
          }
        } else {
          showWarningToast(res2.message);
          if (isPhoneAuth) {
            phoneNumAuthSwitch.value = !isOpen;
          } else {
            emailAuthSwitch.value = !isOpen;
          }
        }
      }
    } else {
      showWarningToast(res.message);
      if (isPhoneAuth) {
        phoneNumAuthSwitch.value = !isOpen;
      } else {
        emailAuthSwitch.value = !isOpen;
      }
    }
  }

  void refreshData() async {
    final res = await walletServices.getSettings();
    if (res.code == 0) {
      WalletSettingsBean settingBean = WalletSettingsBean.fromJson(res.data);
      emailAuthEmail.value = settingBean.emailAuthEmail ?? "--";
      phoneAuthContact.value = settingBean.phoneAuthContact ?? "--";
      phoneAuthCountryCode.value = settingBean.phoneAuthCountryCode ?? "--";
    } else {
      showWarningToast(res.message);
    }
  }
}
