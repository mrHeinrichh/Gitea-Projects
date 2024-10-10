import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/language/language_controller.dart';
import 'package:jxim_client/language/language_view.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/setting/data_storage_page.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/setting/user_bio/user_bio_view.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/login/otp_view.dart';

import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/setting/notification/notification_setting_view.dart';
import 'package:jxim_client/setting/notification/notification_type_view.dart';
import 'package:jxim_client/setting/notification/notification_view.dart';
import 'package:jxim_client/setting/user_bio/edit_phone_number.dart';
import 'package:jxim_client/setting/user_bio/edit_username.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/contact/qr_code_view.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/login/otp_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_intro_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_setting_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_setting_view.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_view.dart';
import 'package:jxim_client/home/chat/desktop/desktop_chat_empty_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/controller/app_info_controller.dart';
import 'package:jxim_client/home/setting/controller/linked_device_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/home/setting/view/app_info_view.dart';
import 'package:jxim_client/home/setting/view/linked_device_view.dart';

class DesktopSettingView extends GetView<SettingController> {
  const DesktopSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
    return Scaffold(
      backgroundColor: colorBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Container(
                width: constraints.maxWidth > 675
                    ? 320
                    : constraints.maxWidth - 1.5,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        color: colorBackground,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            localized(homeSetting),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: MFontWeight.bold5.value,
                                color: colorTextPrimary),
                          )
                          // const SizedBox(
                          //   width: 10,
                          // ),
                          // Expanded(
                          //   child: DesktopSearchingBar(
                          //     onChanged: (value) {
                          //       controller.searchParam.value = value;
                          //       controller.searchLocal();
                          //     },
                          //     controller: controller.searchController,
                          //     suffixIcon: Obx(
                          //       () => Visibility(
                          //         visible:
                          //             controller.searchParam.value.isNotEmpty,
                          //         child: DesktopGeneralButton(
                          //           onPressed: () {
                          //             controller.searchController.clear();
                          //             controller.searchParam.value = '';
                          //           },
                          //           child: Icon(
                          //             Icons.close,
                          //             color: Colors.grey.shade300,
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const DesktopContactDropdown(),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Obx(
                          () => Column(
                            children: <Widget>[
                              Container(
                                decoration: boxDecoration,
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  children: [
                                    ElevatedButtonTheme(
                                      data: ElevatedButtonThemeData(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              controller.selectedIndex.value ==
                                                      0
                                                  ? colorDesktopChatBlue
                                                  : colorWhite,
                                          disabledBackgroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          surfaceTintColor: colorBorder,
                                          padding: EdgeInsets.zero,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(0))),
                                          elevation: 0.0,
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (controller
                                                  .desktopSettingCurrentRoute !=
                                              RouteName.userBioSetting) {
                                            controller.selectedIndex.value = 0;
                                            Get.offAllNamed(
                                                RouteName.desktopChatEmptyView,
                                                predicate: (route) =>
                                                    route.settings.name ==
                                                    RouteName
                                                        .desktopChatEmptyView,
                                                id: 3);
                                            Get.toNamed(
                                                RouteName.userBioSetting,
                                                id: 3);
                                          }
                                        },
                                        child: Obx(
                                          () => Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8,
                                                    bottom: 8,
                                                    left: 10),
                                                child: Row(
                                                  children: [
                                                    /// 头像
                                                    if (controller.user.value !=
                                                        null)
                                                      CustomAvatar.user(
                                                        controller.user.value!,
                                                        size: 60,
                                                        headMin:
                                                            Config().messageMin,
                                                      ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Container(
                                                        height: 60,
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 16),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: <Widget>[
                                                                  Obx(
                                                                    () => Text(
                                                                      controller
                                                                          .nickname
                                                                          .value,
                                                                      style:
                                                                          TextStyle(
                                                                        color: controller.selectedIndex.value ==
                                                                                0
                                                                            ? colorWhite
                                                                            : colorTextPrimary,
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight: MFontWeight
                                                                            .bold5
                                                                            .value,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          2.0),
                                                                  Obx(
                                                                    () => Text(
                                                                      '${controller.countryCode.value} ${controller.contactNumber.value} • @${controller.username.value}',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        color: controller.selectedIndex.value ==
                                                                                0
                                                                            ? colorWhite
                                                                            : colorTextSecondary,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            SvgPicture.asset(
                                                              'assets/svgs/right_arrow_thick.svg',
                                                              color: controller
                                                                          .selectedIndex
                                                                          .value ==
                                                                      0
                                                                  ? colorWhite
                                                                  : colorTextSupporting,
                                                              width: 16,
                                                              height: 16,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              separateDivider(indent: 76.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    ElevatedButtonTheme(
                                      data: ElevatedButtonThemeData(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              controller.selectedIndex.value ==
                                                      1
                                                  ? colorDesktopChatBlue
                                                  : colorWhite,
                                          disabledBackgroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          surfaceTintColor: colorBorder,
                                          padding: EdgeInsets.zero,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(0))),
                                          elevation: 0.0,
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (controller
                                                  .desktopSettingCurrentRoute !=
                                              RouteName.qrCodeView) {
                                            controller.selectedIndex.value = 1;
                                            Get.offAllNamed(
                                                RouteName.desktopChatEmptyView,
                                                predicate: (route) =>
                                                    route.settings.name ==
                                                    RouteName
                                                        .desktopChatEmptyView,
                                                id: 3);
                                            Get.toNamed(RouteName.qrCodeView,
                                                arguments: {
                                                  "user": controller.user.value
                                                },
                                                id: 3);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                              top: 8, bottom: 8, left: 10),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.qr_code,
                                                color: controller.selectedIndex
                                                            .value ==
                                                        1
                                                    ? colorWhite
                                                    : themeColor,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 16),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text('My QR',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  MFontSize
                                                                      .size13
                                                                      .value,
                                                              fontWeight:
                                                                  MFontWeight
                                                                      .bold4
                                                                      .value,
                                                              color: controller
                                                                          .selectedIndex
                                                                          .value ==
                                                                      1
                                                                  ? colorWhite
                                                                  : colorTextPrimary,
                                                            )),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      SvgPicture.asset(
                                                        'assets/svgs/right_arrow_thick.svg',
                                                        color: controller
                                                                    .selectedIndex
                                                                    .value ==
                                                                1
                                                            ? colorWhite
                                                            : colorTextSupporting,
                                                        width: 16,
                                                        height: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                clipBehavior: Clip.hardEdge,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: boxDecoration,
                                child: Column(
                                  children: [
                                    /// notification
                                    SettingItem(
                                      onTap: () =>
                                          controller.onSettingOptionTap(
                                              context,
                                              SettingOption
                                                  .notificationAndSound.type),
                                      iconName: 'notification',
                                      title: localized(notifSound),
                                      titleColor:
                                          controller.selectedIndex.value == 2
                                              ? colorWhite
                                              : colorTextPrimary,
                                      arrowColor:
                                          controller.selectedIndex.value == 2
                                              ? colorWhite
                                              : colorTextSupporting,
                                      bgColor:
                                          controller.selectedIndex.value == 2
                                              ? colorDesktopChatBlue
                                              : colorWhite,
                                    ),

                                    /// privacy and security
                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption
                                                    .privacyAndSecurity.type),
                                        iconName: 'privacy_and_security',
                                        title: localized(privacySecurity),
                                        titleColor:
                                            controller.selectedIndex.value == 3
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 3
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 3
                                                ? colorDesktopChatBlue
                                                : colorWhite),

                                    /// Data and Storage
                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption
                                                    .dataAndStorage.type),
                                        iconName: 'data_and_storage',
                                        title: localized(dataStorage),
                                        titleColor:
                                            controller.selectedIndex.value == 4
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 4
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 4
                                                ? colorDesktopChatBlue
                                                : colorWhite),

                                    /// Language
                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption.language.type),
                                        iconName: 'language',
                                        title: localized(language),
                                        withBorder: false,
                                        titleColor:
                                            controller.selectedIndex.value == 5
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 5
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 5
                                                ? colorDesktopChatBlue
                                                : colorWhite),
                                  ],
                                ),
                              ),

                              /// App and Device info
                              Container(
                                clipBehavior: Clip.hardEdge,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: boxDecoration,
                                child: Column(
                                  children: [
                                    /// link device
                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption.linkDevices.type),
                                        iconName: 'linked_devices',
                                        title: localized(linkedDevices),
                                        titleColor:
                                            controller.selectedIndex.value == 7
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 7
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 7
                                                ? colorDesktopChatBlue
                                                : colorWhite),

                                    /// account
                                    // SettingItem(
                                    //   onTap: () => controller.onSettingOptionTap(
                                    //       context, SettingOption.accounts.type),
                                    //   iconName: 'accounts',
                                    //   title: localized(accounts),
                                    // ),

                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption
                                                    .inviteFriends.type),
                                        iconName: 'Heart',
                                        title: localized(inviteFriends),
                                        titleColor:
                                            controller.selectedIndex.value == 9
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 9
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 9
                                                ? colorDesktopChatBlue
                                                : colorWhite),

                                    /// app info
                                    SettingItem(
                                        onTap: () =>
                                            controller.onSettingOptionTap(
                                                context,
                                                SettingOption.appInfo.type),
                                        iconName: 'app_info',
                                        title: localized(appInfo),
                                        rightWidget: Obx(
                                          () => Visibility(
                                            visible: controller
                                                .isVersionUpdate.value,
                                            child: const Icon(
                                              Icons.circle,
                                              color: colorRed,
                                              size: 8,
                                            ),
                                          ),
                                        ),
                                        titleColor:
                                            controller.selectedIndex.value == 8
                                                ? colorWhite
                                                : colorTextPrimary,
                                        arrowColor:
                                            controller.selectedIndex.value == 8
                                                ? colorWhite
                                                : colorTextSupporting,
                                        bgColor:
                                            controller.selectedIndex.value == 8
                                                ? colorDesktopChatBlue
                                                : colorWhite),

                                    /// log out
                                    SettingItem(
                                      onTap: () =>
                                          controller.onSettingOptionTap(context,
                                              SettingOption.logout.type),
                                      iconName: 'log_out',
                                      title: localized(mySettingLogout),
                                      withBorder: false,
                                      titleColor: colorRed,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 45,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                color: Colors.grey.shade500,
                width: 1.5,
              ),

              ///Division
              if (constraints.maxWidth > 675)
                Expanded(
                  child: Navigator(
                    key: Get.nestedKey(3),
                    initialRoute: RouteName.desktopChatEmptyView,
                    onGenerateRoute: (settings) {
                      var destination = settings.name;
                      // var arg = settings.arguments ?? {};
                      controller.desktopSettingCurrentRoute = destination!;
                      switch (destination) {
                        case RouteName.desktopChatEmptyView:
                          return GetPageRoute(
                            page: () => const DesktopChatEmptyView(),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.userBioSetting:
                          return GetPageRoute(
                            page: () => const UserBioView(),
                            binding: BindingsBuilder(() {
                              Get.put(CommonAlbumController(),
                                  tag: commonAlbumTag);
                              Get.put(UserBioController());
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.editUsername:
                          return GetPageRoute(
                            page: () => const EditUsername(),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.editPhoneNumber:
                          return GetPageRoute(
                            page: () => const EditPhoneNumber(),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.otpView:
                          Map arguments = settings.arguments as Map;

                          return GetPageRoute(
                            page: () => const OTPView(),
                            binding: BindingsBuilder(() {
                              Get.put(OtpController.desktop(
                                  fromView: arguments['from_view'],
                                  countryCode: arguments['changed_countryCode'],
                                  phoneNumber: arguments['changed_number'],
                                  changePhone: arguments['change_phone']));
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.qrCodeView:
                          return GetPageRoute(
                            page: () => const QRCodeView(),
                            binding: BindingsBuilder(() {
                              Get.put(QRCodeViewController.create(
                                  controller.user.value!));
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.notification:
                          return GetPageRoute(
                            page: () => const NotificationView(),
                            binding: BindingsBuilder(() {
                              Get.put(NotificationController());
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.notificationSetting:
                          return GetPageRoute(
                            page: () => const NotificationSettingView(),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.notificationType:
                          return GetPageRoute(
                            page: () => const NotificationTypeView(),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.privacySecurity:
                          return GetPageRoute(
                            page: () => const PrivacySecurityView(),
                            binding: BindingsBuilder(
                              () {
                                Get.put(PrivacySecurityController());
                                Get.put(PasscodeController());
                              },
                            ),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.dataStorage:
                          return GetPageRoute(
                            page: () => const DataStoragePage(),
                            binding: BindingsBuilder(
                              () {},
                            ),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.passcodeIntroSetting:
                          return GetPageRoute(
                            page: () => PasscodeIntroView(),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.passcodeSetting:
                          return GetPageRoute(
                            page: () => const PasscodeSettingView(),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.currentPasscodeView:
                          return GetPageRoute(
                            page: () => const CurrentPasscodeView(),
                            binding: BindingsBuilder(() {
                              Get.put(CurrentPasscodeController());
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.setupPasscodeView:
                          Map arguments = settings.arguments as Map;
                          return GetPageRoute(
                            page: () => const SetupPasscodeView(),
                            binding: BindingsBuilder(() {
                              Get.put(SetupPasscodeController.desktop(
                                  fromView: arguments['form_view'],
                                  chat: arguments['chat'],
                                  walletPasscodeOptionType:
                                      arguments['passcode_type'],
                                  currentPasscode:
                                      arguments['current_passcode'],
                                  token: arguments['token']));
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.confirmPasscodeView:
                          Map arguments = settings.arguments as Map;
                          return GetPageRoute(
                            page: () => const ConfirmPasscodeView(),
                            binding: BindingsBuilder(() {
                              Get.put(ConfirmPasscodeController.desktop(
                                  walletPasscodeOptionType:
                                      arguments['passcode_type'],
                                  passcode: arguments['passcode'],
                                  currentPasscode:
                                      arguments['current_passcode'],
                                  token: arguments['token']));
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.privacySecuritySetting:
                          return GetPageRoute(
                            page: () => const PrivacySecuritySettingView(),
                            transition: Transition.rightToLeft,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          );
                        case RouteName.languageView:
                          return GetPageRoute(
                            page: () => const LanguageView(),
                            binding: BindingsBuilder(() {
                              Get.put(LanguageController());
                              Get.put(NotificationController());
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.linkedDevice:
                          return GetPageRoute(
                            page: () => const LinkedDeviceView(),
                            binding: BindingsBuilder(
                              () {
                                Get.put(LinkedDeviceController());
                              },
                            ),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.shareView:
                          return GetPageRoute(
                            page: () => const ShareView(),
                            binding: BindingsBuilder(() {
                              Get.put(ShareController());
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.appInfo:
                          return GetPageRoute(
                            page: () => const AppInfoView(),
                            binding: BindingsBuilder(
                              () {
                                Get.put(AppInfoController());
                              },
                            ),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        default:
                          return GetPageRoute(
                            page: () => Container(),
                            transition: Transition.leftToRight,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DesktopUserBioView extends StatelessWidget {
  const DesktopUserBioView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
