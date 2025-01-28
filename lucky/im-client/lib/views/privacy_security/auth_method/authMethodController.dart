import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import '../../../api/wallet_services.dart';
import '../../../object/wallet/wallet_settings_bean.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/net/response_data.dart';
import '../../../utils/second_verification_utils.dart';

class AuthMethodController extends GetxController {
  final phoneNumAuthSwitch = true.obs;
  final emailAuthSwitch = true.obs;
  final emailAuthEmail = "--".obs;
  final phoneAuthContact = "--".obs;
  final phoneAuthCountryCode = "--".obs;

  @override
  void onInit() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      emailAuthEmail.value = arguments['emailAuthEmail'];
      emailAuthSwitch.value = arguments['emailAuthEnable'] == 1;
      phoneAuthContact.value = arguments['phoneAuthContact'];
      phoneAuthCountryCode.value = arguments['phoneAuthCountryCode'];
      phoneNumAuthSwitch.value = arguments['phoneAuthEnable'] == 1;
    }
    super.onInit();
  }

  Future<void> setPhoneNumAuthSwitch(bool value) async {
    if (phoneAuthContact != null &&
        phoneAuthCountryCode != null &&
        phoneAuthContact.isNotEmpty &&
        phoneAuthCountryCode.isNotEmpty) {
      if (value == false && emailAuthSwitch == false) {
        showWarningToast("请至少打开一个");
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
    if (emailAuthEmail != null && emailAuthEmail.isNotEmpty) {
      if (value == false && phoneNumAuthSwitch == false) {
        showWarningToast("请至少打开一个");
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
    if (phoneAuthContact != null && phoneAuthContact != null) {
      return "${phoneAuthCountryCode} ${phoneAuthContact}";
    }
    return localized(notSet);
  }

  /// 需要刷新
  String get getEmailStr {
    if (emailAuthEmail != null) {
      return "${emailAuthEmail}";
    }
    return localized(notSet);
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
      if(isOpen){
        if (isPhoneAuth) {
          phoneNumAuthSwitch.value = isOpen;
        } else {
          emailAuthSwitch.value = isOpen;
        }
      }else{
        Map<String, String>  tokenMap= await goSecondVerification(phoneAuth:isPhoneAuth ,emailAuth: !isPhoneAuth);
        if(tokenMap.isEmpty){
          if (isPhoneAuth) {
            phoneNumAuthSwitch.value = !isOpen;
          } else {
            emailAuthSwitch.value = !isOpen;
          }
          return;
        }
        tokenMap.forEach((key, value) {
          if(key =="phoneToken"){
            map['phone_token'] = value;
          }else if(key =="emailToken"){
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
      showWarningToast("${res.message}");
    }
  }
}
