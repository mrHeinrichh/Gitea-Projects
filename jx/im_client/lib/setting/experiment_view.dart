import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/experiment_controller.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/otp_box.dart';

class ExperimentView extends GetView<ExperimentController> {
  const ExperimentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        onPressedBackBtn: ()=> objectMgr.loginMgr.isDesktop
            ? Get.back(id:3) : Get.back(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svgs/get_invitation_code.svg',
                width: 60,
                height: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  localized(invitationCode),
                  style: jxTextStyle.headerText(
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ),
              Text(
                localized(enterInvitationCode),
                style: jxTextStyle.headerText(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 10),
                child: Obx(() {
                  return OTPBox(
                    length: 6,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (String value) {},
                    onCompleted: (String value) =>
                        controller.onCompleted(value, context),
                    controller: controller.otpController,
                    focusNode: controller.otpFocusNode,
                    error: controller.showRedBorder.value,
                    boxHeight: 48,
                    boxWidth: 48,
                  );
                }),
              ),
              Obx(() {
                return Visibility(
                  visible: controller.showError.value,
                  child: Text(
                    localized(invalidInvitationCode),
                    style: jxTextStyle.textStyle16(color: ImColor.red1),
                  ),
                );
              }),
              Obx(() {
                return Visibility(
                  visible: controller.isLoading.value,
                  child: CupertinoActivityIndicator(
                    radius: 12,
                    color: themeColor,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
