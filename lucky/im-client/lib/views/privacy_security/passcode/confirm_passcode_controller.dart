import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/general_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';

class ConfirmPasscodeController extends GetxController {
  final SettingServices settingServices = SettingServices();
  late String title = "";
  late TextEditingController confirmPasscodeController;
  String passcode = "";
  String currentPasscode = "";
  String token = "";
  String walletPasscodeOptionType = "";
  String? fromView;
  Chat? chat;
  Rx<ErrorModel> errorModel = ErrorModel().obs;

  ConfirmPasscodeController();

  ConfirmPasscodeController.desktop(
      {String? walletPasscodeOptionType,
      String? passcode,
      String? currentPasscode,
      String? token}) {
    if (walletPasscodeOptionType != null) {
      this.walletPasscodeOptionType = walletPasscodeOptionType;
    }

    if (passcode != null) {
      this.passcode = passcode;
    }

    if (currentPasscode != null) {
      this.currentPasscode = currentPasscode;
    }

    if (token != null) {
      this.token = token;
    }
  }

  @override
  void onInit() {
    if (Get.arguments != null) {
      if (Get.arguments['passcode_type'] != null) {
        walletPasscodeOptionType = Get.arguments['passcode_type'];
      }
      if (Get.arguments['passcode'] != null) {
        passcode = Get.arguments['passcode'];
      }
      if (Get.arguments['current_passcode'] != null) {
        currentPasscode = Get.arguments['current_passcode'];
      }
      if (Get.arguments['token'] != null) {
        token = Get.arguments['token'];
      }
      if (Get.arguments['from_view'] != null) {
        fromView = Get.arguments['from_view'];
      }
      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }
    }

    setupView();
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void setupView() {
    confirmPasscodeController = TextEditingController();
    switch (walletPasscodeOptionType) {
      case 'setPasscode':
        title = localized(setPasscodeText);
        break;
      case 'changePasscode':
        title = localized(changePasscodeText);
        break;
      case 'resetPasscode':
        title = localized(resetPasscodeText);
        break;
      default:
        break;
    }
  }

  void onConfirmClick(BuildContext context, String value) {
    resetErrorModel();
    if (passcode == confirmPasscodeController.text) {
      switch (walletPasscodeOptionType) {
        case 'setPasscode':
          setPasscode(context, value);
          break;
        case 'changePasscode':
          changePasscode(context, value);
          break;
        case 'resetPasscode':
          resetPasscode(context, value);
          break;
        default:
          break;
      }
    } else {
      confirmPasscodeController.clear();
      errorModel.value = ErrorModel(
        isError: true,
        errorMessage: localized(passcodeDoesNotMatch),
        color: JXColors.secondaryTextBlack,
      );
    }
  }

  void resetErrorModel() {
    if (errorModel.value.isError) {
      errorModel.value = ErrorModel(
        isError: false,
        errorMessage: "",
        color: JXColors.secondaryTextBlack,
      );
    }
  }

  Future<void> setPasscode(BuildContext context, String value) async {
    final data = await settingServices.setPasscode(passcode: value);
    if (data) {
      objectMgr.localStorageMgr.write(LocalStorageMgr.SET_PASSWORD, data);
      objectMgr.chatMgr.event(
        objectMgr.chatMgr,
        ChatMgr.eventSetPassword,
        data: data,
      );

      if (fromView != null) {
        switch (fromView) {
          case 'chat_view':
            if (objectMgr.loginMgr.isDesktop) {
              Get.back(id: 3);
              Get.back(id: 3);
            } else {
              Get.back();
              Get.back();
              Get.back();
            }

            break;
          case 'wallet_view':
            Get.until((route) => Get.currentRoute == RouteName.home);
            Get.find<HomeController>().onPageChange(3);
            // imMiniAppManager.goToMyWalletPage(context);
            Get.toNamed(RouteName.walletView);
            break;
        }
        Toast.showSnackBar(
            context: context, message: localized(walletSetupPasscodeSuccess));
      } else {
        if (objectMgr.loginMgr.isDesktop) {
          Get.back(id: 3);
          Get.back(id: 3);
        } else {
          Get.until((route) => Get.currentRoute == RouteName.home);
          Get.find<HomeController>().onPageChange(3);
          Get.toNamed(RouteName.privacySecurity);
        }

        Toast.showSnackBar(
            context: context, message: localized(walletSetupPasscodeSuccess));
      }
    }
  }

  Future<void> changePasscode(BuildContext context, String value) async {
    try {
      final data = await settingServices.resetPasscode(currentPasscode, value);

      if (data) {
        if (objectMgr.loginMgr.isDesktop) {
          Get.back(id: 3);
          Get.back(id: 3);
          Get.back(id: 3);
        } else {
          Get.until((route) => Get.currentRoute == RouteName.privacySecurity);
          Get.toNamed(RouteName.passcodeSetting);
        }

        Toast.showSnackBar(
            context: context, message: localized(passcodeUpdated));
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        Get.toNamed(RouteName.blockPasscodeView, arguments: {
          'expiryTime': e.getData()['exp'],
        });
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_INVALID_WALLET_PASSCODE) {
        int retryChance = e.getData()['retry_chance'] ?? 0;
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(
              incorrectPasscodePleaseTryAgainAttemptLeftWithParam,
              params: ['${retryChance}']),
          color: JXColors.secondaryTextBlack,
        );
      } else {
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(anUnknownErrorHasOccurred),
          color: JXColors.secondaryTextBlack,
        );
      }
    }
  }

  Future<void> resetPasscode(BuildContext context, String value) async {
    try {
      final data = await settingServices.forgetPasscode(value, token);

      if (data) {
        if (objectMgr.loginMgr.isDesktop) {
          Get.back(id: 3);
          Get.back(id: 3);
          Get.back(id: 3);
        } else {
          Get.until((route) => Get.currentRoute == RouteName.privacySecurity);
          Get.toNamed(RouteName.passcodeSetting);
        }
        Toast.showSnackBar(
            context: context, message: localized(passcodeUpdated));
      }
    } on AppException catch (e) {
      if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_RESET_WALLET_PASSCODE_FAILED) {
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(resetPasscodeFailed),
          color: JXColors.secondaryTextBlack,
        );
      } else {
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(anUnknownErrorHasOccurred),
          color: JXColors.secondaryTextBlack,
        );
      }
    }
  }
}
