import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/login/components/otp_box.dart';

class SetupPasscodeView extends GetView<SetupPasscodeController> {
  const SetupPasscodeView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(paymentPassword),
        onPressedBackBtn: () {
          controller.passcodeController.clear();
          if (objectMgr.loginMgr.isDesktop) {
            Get.back(id: 3);
          } else {
            Get.back();
          }
        },
      ),
      body: Center(
        child: Container(
          // width: 300,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 68,
              // left: 40,
              // right: 40,
            ),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SvgPicture.asset(
                //   'assets/svgs/lock_icon.svg',
                //   width: 60,
                //   height: 60,
                // ),
                Image.asset(
                  'assets/images/lock_secondary_verification.png',
                  width: 84.0,
                  height: 84.0,
                ),
                const SizedBox(height: 24),
                Text(
                  localized(setUpPaymentPasword),
                  style: jxTextStyle.textStyleBold28(),
                ),
                const SizedBox(height: 8),

                Text(
                  localized(pleaseSetANewPaymentPassword),
                  style: jxTextStyle.textStyle17(
                    color: colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.sw * 0.20,
                  ),
                  child: OTPBox(
                    obscureText: true,
                    onChanged: (String value) {},
                    onCompleted: (String value) {
                      controller.toConfirmPasscodeView();
                    },
                    controller: controller.passcodeController,
                    autoDismissKeyboard: false,
                    boxHeight: 48,
                    boxWidth: 44,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
