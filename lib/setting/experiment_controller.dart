import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class ExperimentController extends GetxController {
  final isLoading = false.obs;
  TextEditingController otpController = TextEditingController();
  final otpFocusNode = FocusNode();
  final showError = false.obs;
  final showRedBorder = false.obs;

  onCompleted(String value, BuildContext context) async {
    isLoading.value = true;
    try {
      final res = await validateInvitation(value);

      if (res.success()) {
        int showReel = res.data['show_reel'];
        int showWallet = res.data['show_wallet'];

        await objectMgr.localStorageMgr.write('show_reel', showReel);
        await objectMgr.localStorageMgr.write('show_wallet', showWallet);

        String toast = '';
        if (showWallet == 1 && showReel == 1) {
          toast = localized(unlockFeatures,
              params: [localized(myWallet), localized(channel)]);
        } else if (showWallet == 1) {
          toast = localized(unlockFeature, params: [localized(myWallet)]);
        } else {
          toast = localized(unlockFeature, params: [localized(channel)]);
        }
        if (Get.isRegistered<SettingController>()) {
          Get.find<SettingController>().updateExperiment();
        }
        imBottomToast(
          context,
          title: toast,
          icon: ImBottomNotifType.success,
          duration: 5,
        );
        Get.back();
      } else {
        invalidCodeProcess();
      }
    } catch (e) {
      invalidCodeProcess();
    }
  }

  invalidCodeProcess() {
    isLoading.value = false;
    otpController.clear();
    showError.value = true;
    showRedBorder.value = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      otpFocusNode.requestFocus();
      showRedBorder.value = false;
    });
  }
}
