import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';
import '../../../main.dart';
import '../../../utils/color.dart';
import '../../login/components/otp_box.dart';

class SetupPasscodeView extends GetView<SetupPasscodeController> {
  const SetupPasscodeView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: controller.contentMap["toolbarTitle"]!,
        onPressedBackBtn: () {
          controller.passcodeController.clear();
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
                  controller.contentMap["setupPasscodeText"]!,
                  style: jxTextStyle.textStyleBold16(),
                ),
                const SizedBox(height: 24),
                OTPBox(
                  obscureText: true,
                  onChanged: (String value) {},
                  onCompleted: (String value) {
                    controller.toConfirmPasscodeView();
                  },
                  controller: controller.passcodeController,
                  boxWidth: 0.70,
                  autoDismissKeyboard: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
