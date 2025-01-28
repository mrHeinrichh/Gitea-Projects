import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/views/login/components/email_text_field.dart';
import 'package:jxim_client/views/login/login_controller.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../views/login/components/phone_text_field.dart';

class DesktopOthersLoginView extends GetView<LoginController> {
  const DesktopOthersLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Padding(
                //   padding: const EdgeInsets.only(
                //     top: 10,
                //   ),
                //   child:
                // ),
                Text(
                  'Welcome to Hey!Talk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 320,
                  child: TabBar(
                    controller: controller.tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: Colors.blue,
                    unselectedLabelColor: ImColor.black60,
                    labelColor: Colors.blue,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateColor.resolveWith(
                        (states) => Colors.transparent),
                    onTap: (int index) {
                      pdebug(index);
                      if (index == 0) {
                        controller.selectMode.value = PHONE_NUMBER;
                        controller.checkPhoneNumber('');
                        controller.emailController.clear();
                      } else {
                        controller.selectMode.value = EMAIL_ADDRESS;
                        controller.checkEmailFormat('');
                        controller.phoneController.clear();
                      }
                    },
                    tabs: [
                      Tab(
                        text: localized(phoneNumber),
                      ),
                      Tab(
                        text: localized(emailAddress),
                      )
                    ],
                  ),
                ),
                Container(
                  width: 320,
                  height: 300,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      Container(
                        child: Column(
                          children: [
                            PopupMenuButton(
                                position: PopupMenuPosition.under,
                                offset: const Offset(0, 9),
                                color: Colors.white,
                                // padding: EdgeInsets.zero,
                                child: Container(
                                  height: 48,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: JXColors.outlineColor)),
                                  child: Obx(
                                    () => Row(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 1,
                                              color: JXColors.outlineColor,
                                            ),
                                          ),
                                          child: Image.asset(
                                            controller.country.value?.flagUri ??
                                                controller
                                                    .defaultCountry!.flagUri!,
                                            package: 'country_list_pick',
                                            width: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(controller.country.value?.name ??
                                            '')
                                      ],
                                    ),
                                  ),
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 300,
                                  maxWidth: 320,
                                  maxHeight: 300,
                                ),
                                itemBuilder: (BuildContext context) =>
                                    controller.updatedCountryList
                                        .map(
                                          (element) => PopupMenuItem(
                                              padding: EdgeInsets.zero,
                                              onTap: () {
                                                controller.country.value =
                                                    element;
                                                objectMgr.loginMgr.countryCode =
                                                    controller.country.value
                                                        ?.dialCode;
                                                controller.phoneController
                                                    .clear();
                                                controller.wrongPhone.value =
                                                    true;
                                              },
                                              child: Container(
                                                width: 300,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          width: 1,
                                                          color: JXColors
                                                              .outlineColor,
                                                        ),
                                                      ),
                                                      child: Image.asset(
                                                        element.flagUri ?? '',
                                                        package:
                                                            'country_list_pick',
                                                        width: 24,
                                                      ),
                                                    ),
                                                    Text(
                                                      element.name ?? '',
                                                      style: const TextStyle(
                                                        color: JXColors
                                                            .primaryTextBlack,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      element.dialCode ?? '',
                                                      style: const TextStyle(
                                                        color: JXColors
                                                            .secondaryTextBlack,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        )
                                        .toList()),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: JXColors.outlineColor)),
                              child: Row(
                                children: [
                                  Obx(
                                    () => Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                          controller.country.value?.dialCode ??
                                              ''),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      cursorColor: JXColors.blue,
                                      controller: controller.phoneController,
                                      onChanged: (phoneNumber) => controller
                                          .checkPhoneNumber(phoneNumber),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        PhoneNumberInputFormatter(),
                                      ],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:MFontWeight.bold4.value,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: localized(phoneNumber),
                                        hintStyle: const TextStyle(
                                          color: JXColors.supportingTextBlack,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            termServiceView(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero, // Set padding to zero
                              ),
                              onPressed: () {
                                if (controller.validInformation.value) {
                                  controller.successVerification();
                                }
                              },
                              child: Obx(
                                () => Container(
                                  height: 36,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: !controller.validInformation.value
                                        ? accentColor.withOpacity(0.2)
                                        : accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      localized(buttonNext),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: MFontWeight.bold5.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: JXColors.outlineColor)),
                              child: Center(
                                child: EmailTextField(
                                  focusNode: controller.emailFocusNode,
                                  textEditingController:
                                      controller.emailController,
                                  onChanged: (email) =>
                                      controller.checkEmailFormat(email),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            termServiceView(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero, // Set padding to zero
                              ),
                              onPressed: () {
                                if (controller.validInformation.value) {
                                  controller.successVerification();
                                }
                              },
                              child: Obx(
                                () => Container(
                                  height: 36,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: !controller.validInformation.value
                                        ? accentColor.withOpacity(0.2)
                                        : accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      localized(buttonNext),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: MFontWeight.bold5.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Login with QR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: MFontWeight.bold5.value,
                        color: JXColors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
                        color: accentColor,
                      )
                    : const Icon(
                        key: ValueKey('uncheck'),
                        Icons.circle_outlined,
                        size: 20,
                        color: JXColors.supportingTextBlack,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: RichText(
                    text: TextSpan(
                      text: localized(iHaveReadAndAgree),
                      style: jxTextStyle.textStyle14(),
                      children: [
                        TextSpan(
                          text: localized(termOfService),
                          style: jxTextStyle.textStyle14(
                            color: accentColor,
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
