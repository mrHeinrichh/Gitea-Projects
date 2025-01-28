import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/general_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';

class CurrentPasscodeController extends GetxController {
  final TextEditingController currentPasscodeController =
      TextEditingController();
  Rx<ErrorModel> errorModel = ErrorModel().obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> checkPasscode(String value) async {
    try {
      final data = await SettingServices().checkPasscode(value);

      if (data) {
        resetErrorModel();
        if(objectMgr.loginMgr.isDesktop){
          Get.toNamed(
            RouteName.setupPasscodeView,
            arguments: {
              'passcode_type': WalletPasscodeOption.changePasscode.type,
              'current_passcode': value,
            },
            id: 3
          );
        }else{
          Get.toNamed(
            RouteName.setupPasscodeView,
            arguments: {
              'passcode_type': WalletPasscodeOption.changePasscode.type,
              'current_passcode': value,
            },
          );
        }
      }
    } on AppException catch (e) {
      currentPasscodeController.clear();
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

  void resetErrorModel() {
    if (errorModel.value.isError) {
      errorModel.value = ErrorModel(
        isError: false,
        errorMessage: "",
        color: JXColors.secondaryTextBlack,
      );
    }
  }
}
