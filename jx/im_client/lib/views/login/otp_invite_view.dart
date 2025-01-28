import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/otp_box.dart';
import 'package:jxim_client/views/login/otp_invite_controller.dart';

class OTPInviteView extends GetView<OtpInviteController> {
  const OTPInviteView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget otpBox = Column(
      children: [
        Obx(
          () => SizedBox(
            width: objectMgr.loginMgr.isDesktop ? 260 : 44 * 6 + 25,
            child: OTPBox(
              autoFocus: false,
              length: 6,
              keyboardType: TextInputType.name,
              enabled: controller.otpAttempts.value != 0,
              focusNode: controller.otpFocus,
              controller: controller.otpController,
              pinBoxColor: objectMgr.loginMgr.isDesktop ? colorWhite : null,
              onChanged: (String value) {
                pdebug(value);
              },
              onCompleted: (_) {
                controller.accountChecking();
              },
              error: controller.redBorder.value,
              correct: controller.greenBorder.value,
              boxHeight: 48,
              boxWidth: 44,
            ),
          ),
        ),
        Obx(
          () => Container(
            child: controller.wrongOTP.value
                ? Text(
                    controller.otpAttempts.value == 0 ||
                            controller.otpAttempts.value == 5
                        ? " "
                        // : "${localized(homeWrongCode)}${localized(homeYouHave)}${controller.otpAttempts.value}${localized(homeAttemptRemain)}",
                        : localized(inviteFriendRemainAttemptsTimes,
                            params: ['${controller.otpAttempts.value}']),
                    style: jxTextStyle.textStyle12(color: colorRed),
                  )
                : const SizedBox(),
          ),
        ),
      ],
    );
    if (objectMgr.loginMgr.isDesktop) {
      otpBox = SizedBox(height: 170, child: otpBox);
    } else {
      otpBox = Expanded(child: otpBox);
    }
    return Scaffold(
      backgroundColor: objectMgr.loginMgr.isDesktop ? null : colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        onPressedBackBtn: () => controller.backToLogin(),
      ),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: objectMgr.loginMgr.isDesktop ? 0 : 35,
            right: objectMgr.loginMgr.isDesktop ? 0 : 35,
            bottom: 24,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 24,
                ),
                child: objectMgr.loginMgr.isDesktop
                    ? Image.asset(
                        'assets/images/otp_invite_icon_desktop.png',
                        width: 100,
                        height: 100,
                      )
                    : Image.asset(
                        'assets/images/otp_invite_icon.png',
                        width: 84,
                        height: 84,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      localized(inviteFriendEnterCode),
                      style: jxTextStyle.textStyleBold18(
                        color: objectMgr.loginMgr.isDesktop
                            ? themeColor
                            : colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localized(enterInvitationCode),
                      style: jxTextStyle.textStyle17(
                        color: Colors.black.withOpacity(0.44),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              otpBox,
            ],
          ),
        ),
      ),
    );
  }
}
