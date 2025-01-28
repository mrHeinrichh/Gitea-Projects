import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/otp_box.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';

class ConfirmPasscodeView extends GetView<ConfirmPasscodeController> {
  const ConfirmPasscodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          bgColor: Colors.transparent,
          title: controller.title,
          onPressedBackBtn: () {
            if (controller.walletPasscodeOptionType ==
                WalletPasscodeOption.setPasscode.type) {
              SetupPasscodeController setupPasscodeController;
              if (Get.isRegistered<SetupPasscodeController>()) {
                setupPasscodeController = Get.find<SetupPasscodeController>();
              } else {
                setupPasscodeController = Get.put(SetupPasscodeController());
              }
              setupPasscodeController.clearPasscode();
            }

            controller.confirmPasscodeController.clear();
            controller.resetErrorModel();
            if (objectMgr.loginMgr.isDesktop) {
              Get.back(id: 3);
            } else {
              Get.back();
            }
          },
        ),
        body: Center(
          child: Container(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 68,
              ),
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/lock_secondary_verification.png',
                    width: 84.0,
                    height: 84.0,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localized(paymentPassword),
                    style: jxTextStyle.titleText(
                        fontWeight: MFontWeight.bold5.value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localized(setANewPaymentPassword),
                    style: jxTextStyle.textStyle17(color: colorTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.sw * 0.18,
                    ),
                    child: OTPBox(
                      length: 4,
                      obscureText: true,
                      autoDisposeControllers: true,
                      onChanged: (String value) {
                        controller.resetErrorModel();
                      },
                      onCompleted: (String value) {
                        controller.onConfirmClick(context, value);
                      },
                      controller: controller.confirmPasscodeController,
                      autoDismissKeyboard: false,
                      boxHeight: 48,
                      boxWidth: 44,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.errorModel.value.isError,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          controller.errorModel.value.errorMessage,
                          textAlign: TextAlign.center,
                          style: jxTextStyle.textStyle12(
                            color: controller.errorModel.value.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
