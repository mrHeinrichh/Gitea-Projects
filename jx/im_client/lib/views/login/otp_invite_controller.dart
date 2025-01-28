import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/account.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/login/login_controller.dart';
import 'package:jxim_client/views/login/welcome_view.dart';
import 'package:jxim_client/api/account.dart' as account_api;

class OtpInviteController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocus = FocusNode();

  ///OTP状态的变量
  RxBool wrongOTP = false.obs;
  RxBool redBorder = false.obs;
  RxBool greenBorder = false.obs;
  RxBool loginProgress = false.obs;

  RxInt otpAttempts = 5.obs;

  late LoginController loginController;

  OtpInviteController() : loginController = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (!otpFocus.hasFocus) {
          otpFocus.requestFocus();
        }
      },
    );
  }

  @override
  void onClose() {
    super.onClose();
    otpController.dispose();
    otpFocus.dispose();
  }

  void accountChecking() async {
    wrongOTP.value = false;
    loginProgress.value = true;

    try {
      await verifyMainlandInvitesCode(otpController.text);
      objectMgr.loginMgr.mainlandInviteCode = otpController.text;
      Toast.show();
      await mainlandUserLogin();
      await Future.delayed(const Duration(milliseconds: 1000));
      Toast.hide();
      Get.offAll(const WelcomeView());
    } on AppException catch (e) {
      //用户不存在，引导到创建新用户
      if (objectMgr.loginMgr.isDesktop) {
        Get.back();
      }
      if (e.getPrefix() == ErrorCodeConstant.STATUS_INVITE_CODE_ERROR) {
        otpAttempts -= 1;
        wrongOTP.value = true;
        redBorder.value = true;
        await Future.delayed(
          const Duration(seconds: 1),
          () {
            redBorder.value = false;
            otpController.clear();
            otpFocus.requestFocus();
          },
        );
      } else if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_NOT_EXIST) {
        if (objectMgr.loginMgr.isDesktop) {
          Get.back();
          Toast.showToast(
            localized(thisUserIsNotExits),
            duration: 3,
          );
        } else {
          await Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              if (e.getData() is Account) {
                Get.offAll(const WelcomeView());
              }
              greenBorder.value = false;
            },
          );
        }
      } else {
        Toast.showToast(e.getMessage());
      }
    }
    loginProgress.value = false;
  }

  // # 大陆用户登陆
  Future<Account> mainlandUserLogin() async {
    Account account = await account_api.accountLogin();
    objectMgr.loginMgr.mainlandSetAccount(account);

    pdebug("LoginToken=====> ${CustomRequest.token}");

    CustomRequest.token = account.token;

    if (!notBlank(account.user?.username)) {
      throw CodeException(
        ErrorCodeConstant.STATUS_USER_NOT_EXIST,
        localized(thisUserIsNotExits),
        account,
      );
    }

    objectMgr.loginMgr.saveAccount(account);

    return account;
  }

  void backToLogin() {
    if (objectMgr.loginMgr.isDesktop) {
      Get.back(id: 3);
    } else {
      Get.back();
    }
  }
}
