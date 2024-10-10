import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/general_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CurrentPasscodeController extends GetxController {
  final TextEditingController currentPasscodeController =
      TextEditingController();
  Rx<ErrorModel> errorModel = ErrorModel().obs;

  Future<void> checkPasscode(String value) async {
    try {
      final data = await SettingServices().checkPasscode(value);

      if (data) {
        resetErrorModel();
        if (objectMgr.loginMgr.isDesktop) {
          Get.toNamed(
            RouteName.setupPasscodeView,
            arguments: {
              'passcode_type': WalletPasscodeOption.changePasscode.type,
              'current_passcode': value,
            },
            id: 3,
          );
        } else {
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
        Get.toNamed(
          RouteName.blockPasscodeView,
          arguments: {
            'expiryTime': e.getData()['exp'],
          },
        );
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_INVALID_WALLET_PASSCODE) {
        int retryChance = e.getData()['retry_chance'] ?? 0;
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(
            incorrectPasscodePleaseTryAgainAttemptLeftWithParam,
            params: ['$retryChance'],
          ),
          color: colorRed,
        );
      } else {
        errorModel.value = ErrorModel(
          isError: true,
          errorMessage: localized(anUnknownErrorHasOccurred),
          color: colorRed,
        );
      }
    }
  }

  void resetErrorModel() {
    if (errorModel.value.isError) {
      errorModel.value = ErrorModel(
        isError: false,
        errorMessage: "",
        color: colorTextSecondary,
      );
    }
  }
}
