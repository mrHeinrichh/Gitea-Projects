import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

import '../../../utils/theme/text_styles.dart';
import '../../component/custom_alert_dialog.dart';

class DeleteAccountController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

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
            contactNumber, countryCode, OtpPageType.deleteAccount.type);
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
    }
  }
}
