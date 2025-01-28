import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:get/get.dart';

import 'package:jxim_client/views/login/components/otp_box.dart';

class PasscodeView extends GetView<WithdrawController> {
  const PasscodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          Scaffold(
            appBar: PrimaryAppBar(
              title: 'Enter to Proceed',
              onPressedBackBtn: () {
                Get.back();
                controller.pinCodeController.clear();
              },
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enter your passcode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: MFontWeight.bold4.value,
                        color: colorTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    OTPBox(
                      length: 4,
                      obscureText: true,
                      enabled: controller.passwordCount < 5,
                      controller: controller.pinCodeController,
                      onChanged: (String value) {},
                      onCompleted: controller.completedWithdraw,
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.passwordCount > 0 &&
                            controller.passwordCount < 5,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Wrong password ! Please Try again.\nleft ${5 - controller.passwordCount.value} Times',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 14.sp, color: colorRed),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.passwordCount >= 5,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${localized(homePasswordMaxWrong)} \n${localized(homePasswordTryAfter)}',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 14.sp, color: colorRed),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (controller.isLoading.value)
            const Opacity(
              opacity: 0.5,
              child: ModalBarrier(dismissible: false, color: Colors.grey),
            ),
          if (controller.isLoading.value)
            WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
