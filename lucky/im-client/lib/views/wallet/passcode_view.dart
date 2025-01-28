import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import '../../utils/lang_util.dart';
import '../../utils/theme/text_styles.dart';
import '../component/new_appbar.dart';
import 'package:get/get.dart';

import '../login/components/otp_box.dart';

class PasscodeView extends GetView<WithdrawController> {
  const PasscodeView({Key? key}) : super(key: key);

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
                  children: [Text(
                      'Enter your passcode',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight:MFontWeight.bold4.value,
                          color: JXColors.darkGrey),
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
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            'Wrong password ! Please Try again.\nleft ${5 - controller.passwordCount.value} Times',
                            textAlign: TextAlign.left,
                            style:
                                TextStyle(fontSize: 14.sp, color: JXColors.red),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.passwordCount >= 5,
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            '${localized(homePasswordMaxWrong)} \n${localized(homePasswordTryAfter)}',
                            textAlign: TextAlign.left,
                            style:
                                TextStyle(fontSize: 14.sp, color: JXColors.red),
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
