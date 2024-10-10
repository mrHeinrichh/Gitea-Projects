import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/login/components/email_text_field.dart';
import 'package:jxim_client/views/login/components/phone_text_field.dart';
import 'package:jxim_client/views/login/login_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/country_picker.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const ValueKey('LoginView'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 1) {
          if (controller.selectMode.value == PHONE_NUMBER) {
            controller.phoneFocusNode.requestFocus();
          } else if (controller.selectMode.value == EMAIL_ADDRESS) {
            controller.emailFocusNode.requestFocus();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        appBar: const PrimaryAppBar(),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: controller.phoneFocusNode.hasFocus ? 12 : 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Obx(
                        () => AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.only(
                            top: controller.topPadding.value,
                          ),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          child: Text(
                            localized(
                              welcomeToHeyTalk,
                              params: [Config().appName],
                            ),
                            style: jxTextStyle.textStyleBold28(
                              fontWeight: MFontWeight.bold6.value,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 32,
                        ),
                        child: Text(
                          localized(loginOrSignUpWith),
                          style: jxTextStyle.textStyle16(),
                        ),
                      ),
                      Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LoginModeButton(
                              title: localized(phoneNumber),
                              selectedCondition:
                                  controller.selectMode.value == PHONE_NUMBER,
                              onPressed: () {
                                if (controller.selectMode.value !=
                                    PHONE_NUMBER) {
                                  controller.selectMode.value = PHONE_NUMBER;
                                  controller.checkPhoneNumber('');
                                  controller.emailController.clear();
                                  controller.isCheckTermService.value = false;
                                }
                              },
                            ),
                            LoginModeButton(
                              title: localized(emailAddress),
                              selectedCondition:
                                  controller.selectMode.value == EMAIL_ADDRESS,
                              onPressed: () {
                                if (controller.selectMode.value !=
                                    EMAIL_ADDRESS) {
                                  controller.selectMode.value = EMAIL_ADDRESS;
                                  controller.checkEmailFormat('');
                                  controller.phoneController.clear();
                                  controller.isCheckTermService.value = false;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => controller.selectMode.value == 1
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.countryController.text = "";
                                        controller.updatedCountryList.value =
                                            controller.countryCodeList;
                                        showModalBottomSheet(
                                          isScrollControlled: true,
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(20),
                                              topLeft: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (context) {
                                            //选择国家的主键
                                            return CountryPicker(
                                              countryController:
                                                  controller.countryController,
                                              searchCountry:
                                                  controller.searchCountry,
                                              selectCountry:
                                                  controller.selectCountry,
                                              updatedCountryList:
                                                  controller.updatedCountryList,
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                            left: 16,
                                          ),
                                          child: Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      width: 1,
                                                      color: colorBorder,
                                                    ),
                                                  ),
                                                  child: Image.asset(
                                                    controller.country.value
                                                            ?.flagUri ??
                                                        controller
                                                            .defaultCountry!
                                                            .flagUri!,
                                                    package:
                                                        'country_list_pick',
                                                    width: 32,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16,
                                                  ),
                                                  child: Text(
                                                    textAlign: TextAlign.center,
                                                    (!controller.isEnglish
                                                            ? controller.country
                                                                .value?.zhName
                                                            : controller.country
                                                                .value?.name) ??
                                                        (!controller.isEnglish
                                                            ? controller
                                                                .defaultCountry!
                                                                .zhName!
                                                            : controller
                                                                .defaultCountry!
                                                                .name!),
                                                    style: jxTextStyle
                                                        .textStyle16(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 18,
                                                  ),
                                                  child: Text(
                                                    textAlign: TextAlign.center,
                                                    controller.country.value
                                                            ?.dialCode ??
                                                        controller
                                                            .defaultCountry!
                                                            .dialCode!,
                                                    style: jxTextStyle
                                                        .textStyle16(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .keyboard_arrow_right_sharp,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: PhoneTextField(
                                      focusNode: controller.phoneFocusNode,
                                      textEditingController:
                                          controller.phoneController,
                                      onChanged: (phoneNumber) => controller
                                          .checkPhoneNumber(phoneNumber),
                                    ),
                                  ),
                                  Obx(
                                    () => Visibility(
                                      visible:
                                          notBlank(controller.phoneError.value),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          left: 16,
                                        ),
                                        child: Text(
                                          controller.phoneError.value,
                                          style: jxTextStyle.textStyle14(
                                            color: colorRed,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: EmailTextField(
                                      focusNode: controller.emailFocusNode,
                                      textEditingController:
                                          controller.emailController,
                                      onChanged: (email) =>
                                          controller.checkEmailFormat(email),
                                    ),
                                  ),
                                  Obx(
                                    () => Visibility(
                                      visible:
                                          notBlank(controller.emailError.value),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          left: 16,
                                        ),
                                        child: Text(
                                          controller.emailError.value,
                                          style: jxTextStyle.textStyle14(
                                            color: colorRed,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      termServiceView(),
                    ],
                  ),
                ),
                Obx(
                  () => controller.isLoading.value
                      ? Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: BallCircleLoading(
                              radius: 10,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 2,
                                borderColor: themeColor,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (controller.validInformation.value) {
                              controller.successVerification();
                            }
                          },
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: !controller.validInformation.value
                                  ? themeColor.withOpacity(0.2)
                                  : themeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                localized(buttonNext),
                                style: jxTextStyle.textStyleBold14(
                                  color: Colors.white,
                                  fontWeight: MFontWeight.bold6.value,
                                ),
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
    );
  }

  Widget termServiceView() {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.checkTermService(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: controller.isCheckTermService.value
                    ? Icon(
                        key: const ValueKey('check'),
                        Icons.check_circle,
                        size: 20,
                        color: themeColor,
                      )
                    : const Icon(
                        key: ValueKey('uncheck'),
                        Icons.circle_outlined,
                        size: 20,
                        color: colorTextSupporting,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: RichText(
                    text: TextSpan(
                      text: localized(iHaveReadAndAgree),
                      style: jxTextStyle
                          .textStyle14()
                          .copyWith(fontFamily: appFontfamily),
                      children: [
                        TextSpan(
                          text: localized(termOfService),
                          style: jxTextStyle.textStyle14(
                            color: themeColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              controller.showTermService();
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginModeButton extends StatelessWidget {
  const LoginModeButton({
    super.key,
    required this.title,
    required this.selectedCondition,
    required this.onPressed,
  });

  final String title;
  final bool selectedCondition;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 24,
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero, // Set padding to zero
        ),
        onPressed: onPressed,
        child: Container(
          height: 40,
          width: (ObjectMgr.screenMQ!.size.width - 48) / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: selectedCondition ? themeColor : colorBorder,
          ),
          child: Center(
            child: Text(
              title,
              style: jxTextStyle.textStyleBold14(
                color: selectedCondition ? Colors.white : colorTextSecondary,
                fontWeight: selectedCondition
                    ? MFontWeight.bold6.value
                    : MFontWeight.bold4.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
