import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/login/components/email_text_field.dart';
import 'package:jxim_client/views/login/components/phone_text_field.dart';
import 'package:jxim_client/views/login/login_controller.dart';

class DesktopOthersLoginView extends StatefulWidget {
  const DesktopOthersLoginView({super.key});

  @override
  State<DesktopOthersLoginView> createState() => _DesktopOthersLoginViewState();
}

class _DesktopOthersLoginViewState extends State<DesktopOthersLoginView>
    with TickerProviderStateMixin {
  late LoginController controller;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LoginController>();

    tabController = TabController(
      animationDuration: const Duration(milliseconds: 0),
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

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
                SizedBox(
                  width: 320,
                  child: TabBar(
                    controller: tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: Colors.blue,
                    unselectedLabelColor: ImColor.black60,
                    labelColor: Colors.blue,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent,
                    ),
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
                      ),
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
                    controller: tabController,
                    children: [
                      Column(
                        children: [
                          PopupMenuButton(
                            position: PopupMenuPosition.under,
                            offset: const Offset(0, 9),
                            color: Colors.white,
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
                            itemBuilder: (BuildContext context) => controller
                                .updatedCountryList
                                .map(
                                  (element) => PopupMenuItem(
                                    padding: EdgeInsets.zero,
                                    onTap: () {
                                      controller.country.value = element;
                                      objectMgr.loginMgr.countryCode =
                                          controller.country.value?.dialCode;
                                      controller.phoneController.clear();
                                      controller.wrongPhone.value = true;
                                    },
                                    child: SizedBox(
                                      width: 300,
                                      child: Row(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: colorBackground6,
                                              ),
                                            ),
                                            child: Image.asset(
                                              element.flagUri ?? '',
                                              package: 'country_list_pick',
                                              width: 24,
                                            ),
                                          ),
                                          Text(
                                            element.name ?? '',
                                            style: const TextStyle(
                                              color: colorTextPrimary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            element.dialCode ?? '',
                                            style: const TextStyle(
                                              color: colorTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            // padding: EdgeInsets.zero,
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorBackground6),
                              ),
                              child: Obx(
                                () => Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1,
                                          color: colorBackground6,
                                        ),
                                      ),
                                      child: Image.asset(
                                        controller.country.value?.flagUri ??
                                            controller.defaultCountry!.flagUri!,
                                        package: 'country_list_pick',
                                        width: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      controller.country.value?.name ?? '',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorBackground6),
                            ),
                            child: Row(
                              children: [
                                Obx(
                                  () => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      controller.country.value?.dialCode ?? '',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    cursorColor: themeColor,
                                    controller: controller.phoneController,
                                    onChanged: (phoneNumber) => controller
                                        .checkPhoneNumber(phoneNumber),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      PhoneNumberInputFormatter(),
                                    ],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: MFontWeight.bold4.value,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: localized(phoneNumber),
                                      hintStyle: const TextStyle(
                                        color: colorTextSupporting,
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
                                      ? themeColor.withOpacity(0.2)
                                      : themeColor,
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
                      Column(
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorBackground6),
                            ),
                            child: Center(
                              child: EmailTextField(
                                // focusNode: controller.emailFocusNode,
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
                                      ? themeColor.withOpacity(0.2)
                                      : themeColor,
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
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.offNamed(RouteName.desktopLoginQR);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Login with QR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: MFontWeight.bold5.value,
                        color: themeColor,
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
                      style: jxTextStyle.textStyle14(),
                      children: [
                        TextSpan(
                          text: localized(termOfService),
                          style: jxTextStyle.textStyle14(
                            color: themeColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = ()=> controller.showDesktopTermService(),
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
