import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';

class DeleteAccountController extends GetxController {
  void showDeleteAccountConfirmation() {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: '${localized(localized(deleteAccount))}?',
          content: Text(
            localized(afterDeletingYourAccount),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonDelete),
          cancelText: localized(buttonCancel),
          confirmCallback: () => getOtp(),
        );
      },
    );
  }

  Future<void> getOtp() async {
    String countryCode = objectMgr.userMgr.mainUser.countryCode;
    String contactNumber = objectMgr.userMgr.mainUser.contact;
    String email = objectMgr.userMgr.mainUser.email;

    try {
      if (countryCode != "" && contactNumber != "") {
        final res = await getOTP(
          contactNumber,
          countryCode,
          OtpPageType.deleteAccount.type,
        );
        if (res) {
          Get.toNamed(
            RouteName.otpView,
            arguments: {'from_view': OtpPageType.deleteAccount.page},
          );
        }
      } else {
        if (email != "") {
          final res =
              await getOTPByEmail(email, OtpPageType.deleteAccount.type);
          if (res) {
            Get.toNamed(
              RouteName.otpView,
              arguments: {'from_view': OtpPageType.deleteAccount.page},
            );
          }
        }
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    } catch (e) {
      if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
        Toast.showToast(localized(homeOtpMaxLimit));
      } else if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_BE_REACH_LIMIT) {
        Toast.showToast(localized(homeOtpBeMaxLimit));
      }
    }
  }
}
