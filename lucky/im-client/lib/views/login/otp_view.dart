import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/otp_controller.dart';
import '../../main.dart';
import '../../object/enums/enum.dart';
import 'components/otp_box.dart';

class OTPView extends GetView<OtpController> {
  const OTPView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget otpBox = Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ObjectMgr.screenMQ!.size.width *
                (objectMgr.loginMgr.isDesktop ? 0.25 : 0.15),
          ),
          child: Obx(
            () => Container(
              width: objectMgr.loginMgr.isDesktop ? 260 : null,
              child: OTPBox(
                autoFocus: false,
                length: 4,
                enabled: controller.otpAttempts.value != 0,
                focusNode: controller.otpFocus,
                controller: controller.otpController,
                pinBoxColor:
                    objectMgr.loginMgr.isDesktop ? JXColors.lightShade : null,
                onChanged: (String value) {
                  pdebug(value);
                },
                onCompleted: (_) {
                  controller.accountChecking();
                },
                error: controller.redBorder.value,
                correct: controller.greenBorder.value,
              ),
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
                        : "${localized(homeWrongCode)}${localized(homeYouHave)}${controller.otpAttempts.value}${localized(homeAttemptRemain)}",
                    style: jxTextStyle.textStyle12(color: errorColor),
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
      backgroundColor: objectMgr.loginMgr.isDesktop ? null : backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        onPressedBackBtn: () => controller.backToLogin(),
      ),
      body: Container(
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
                  bottom: 32,
                ),
                child: objectMgr.loginMgr.isDesktop
                    ? SvgPicture.asset(
                        'assets/svgs/otp_icon_desktop.svg',
                        width: 100,
                        height: 100,
                      )
                    : SvgPicture.asset(
                        'assets/svgs/otp_icon.svg',
                        width: 60,
                        height: 60,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    (controller.fromView.value ==
                            OtpPageType.deleteAccount.page)
                        ? Text(
                            localized(lastStepToDelete),
                            style: jxTextStyle.textStyleBold17(
                                color: errorColor, fontWeight: MFontWeight.bold6.value),
                          )
                        : Text(
                            localized(otp),
                            style: jxTextStyle.textStyleBold20(
                                color: objectMgr.loginMgr.isDesktop
                                    ? JXColors.blue
                                    : JXColors.primaryTextBlack),
                          ),
                    const SizedBox(height: 12),
                    Text(
                      controller.fromView.value ==
                              OtpPageType.deleteAccount.page
                          ? localized(validateYourAction)
                          : localized(homeOneTimePass),
                      style: jxTextStyle.textStyle16(),
                      textAlign: TextAlign.center,
                    ),
                    Obx(
                      () => Text(
                        ' ${controller.intPhoneFormat.isEmpty ? controller.emailAddress : controller.formatPhoneNumber(controller.intPhoneFormat.value)}',
                        style: jxTextStyle.textStyleBold16(
                            color: accentColor, fontWeight: MFontWeight.bold6.value),
                      ),
                    ),
                  ],
                ),
              ),
              otpBox,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localized(homeDidntReceiveOTP),
                    style: jxTextStyle.textStyle14(),
                  ),
                  const SizedBox(width: 4),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            if (!controller.otpResent.value) {
                              controller.resendOTP();
                            }
                          },
                          child: Text(
                            localized(homeResend),
                            style: jxTextStyle.textStyle14(
                                color: controller.otpResent.value ||
                                        controller.resendDisabled.value
                                    ? JXColors.supportingTextBlack
                                    : accentColor),
                          ),
                        ),
                        Visibility(
                          visible: controller.otpResent.value,
                          child: Text(
                            '\t(${controller.counterValue.value.toString()})',
                            style: jxTextStyle.textStyle14(
                              color: JXColors.supportingTextBlack,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
