import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/otp_box.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';

import '../../../main.dart';

class ConfirmPasscodeView extends GetView<ConfirmPasscodeController> {
  const ConfirmPasscodeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
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
            if(objectMgr.loginMgr.isDesktop){
              Get.back(id: 3);
            }else{
              Get.back();
            }
          },
        ),
        body: Center(
          child: Container(
            width: 300,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 68,
                left: 40,
                right: 40,
              ),
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/lock_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    localized(confirmYourNewPasscode),
                    style: jxTextStyle.textStyleBold16(),
                  ),
                  const SizedBox(height: 24),
                  OTPBox(
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
                    boxWidth: 0.70,
                    autoDismissKeyboard: false,
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.errorModel.value.isError,
                      child: Container(
                        width: double.infinity,
                        child: Text(
                          controller.errorModel.value.errorMessage,
                          textAlign: TextAlign.center,
                          style: jxTextStyle.textStyle12(
                              color: controller.errorModel.value.color),
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
