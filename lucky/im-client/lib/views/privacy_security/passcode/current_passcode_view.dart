import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_controller.dart';

import '../../../utils/color.dart';
import '../../login/components/otp_box.dart';

class CurrentPasscodeView extends GetView<CurrentPasscodeController> {
  const CurrentPasscodeView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(changePasscodeText),
        onPressedBackBtn: () {
          controller.currentPasscodeController.clear();
          controller.resetErrorModel();
          Get.back();
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
              children: [
                SvgPicture.asset(
                  'assets/svgs/lock_icon.svg',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 28),
                Text(
                  localized(enterYourCurrentPasscode),
                  style: jxTextStyle.textStyleBold16(),
                ),
                const SizedBox(height: 24),
                OTPBox(
                  obscureText: true,
                  onChanged: (String value) {
                    controller.resetErrorModel();
                  },
                  onCompleted: (String value) {
                    controller.checkPasscode(value);
                  },
                  controller: controller.currentPasscodeController,
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
    );
  }
}
