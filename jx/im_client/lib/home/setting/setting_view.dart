import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar_static.dart';
import 'package:jxim_client/views/component/component.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: colorWhite,
      borderRadius: BorderRadius.circular(10),
    );

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        isBackButton: false,
        titleWidget: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OpacityEffect(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.toNamed(RouteName.qrCodeView,
                    arguments: {"user": controller.user.value}),
                child: Container(
                  alignment: Alignment.topCenter,
                  // padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SvgPicture.asset(
                    'assets/svgs/qrCode.svg',
                    width: 24,
                    height: 24,
                    color: themeColor,
                  ),
                ),
              ),
            ),
            OpacityEffect(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.toNamed(RouteName.userBioSetting),
                child: Container(
                  alignment: Alignment.topCenter,
                  // padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localized(buttonEdit),
                    style: jxTextStyle.textStyle17(
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            /// 用户资料
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  /// 头像
                  GestureDetector(
                      onTap: () => showProfileAvatar(controller.user.value?.id,
                          controller.user.value?.id, false),
                      child: Hero(
                        tag: '${controller.user.value?.uid}',
                        child: CustomAvatarStatic(
                          uid: controller.user.value?.uid ?? 0,
                          size: 100,
                        ),
                      )),
                  ImGap.vGap16,
                  Obx(
                    () => Text(
                      controller.nickname.value,
                      style: jxTextStyle.titleText(
                        fontWeight: MFontWeight.bold5.value,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ImGap.vGap4,
                  Obx(
                    () => Text(
                      textAlign: TextAlign.center,
                      '${controller.countryCode.value} ${controller.contactNumber.value} ·${(controller.username.value.length > 12) ? '\n' : ''} @${controller.username.value}',
                      style: jxTextStyle.headerText(
                        color: colorTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                return Column(
                  children: [
                    /// 钱包
                    if (controller.showWallet.value || isWalletEnable())
                      Container(
                        clipBehavior: Clip.hardEdge,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: boxDecoration,
                        child: SettingItem(
                          onTap: () => controller.onSettingOptionTap(
                              context, SettingOption.myWallet.type),
                          iconName: 'my_wallet',
                          title: localized(myWallet),
                          withBorder: false,
                        ),
                      ),

                    Container(
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: boxDecoration,
                      child: Column(
                        children: [
                          /// Favourite
                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.favourite.type),
                            iconName: 'favourite',
                            title: localized(favouriteTitle),
                          ),

                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.settingRecentCall.type),
                            iconName: 'recent_call',
                            title: localized(recentCalls),
                          ),

                          /// link device
                          if (Config().enableDeviceLink)
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.linkDevices.type),
                              iconName: 'linked_devices',
                              title: localized(linkedDevices),
                              rightTitle: localized(scanQRCodeTitle),
                              rightTitleColor: colorTextSecondary,
                              withBorder: true,
                            ),

                          if (Config().enableChatCategory)
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context,
                                  SettingOption.chatCategoryFolder.type),
                              iconName: 'folder',
                              title: localized(chatCategoryFolder),
                              withBorder: false,
                            ),
                        ],
                      ),
                    ),

                    /// Preference
                    Container(
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: boxDecoration,
                      child: Column(
                        children: [
                          /// notification
                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(context,
                                SettingOption.notificationAndSound.type),
                            iconName: 'notification',
                            title: localized(notifSound),
                          ),

                          /// privacy and security
                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.privacyAndSecurity.type),
                            iconName: 'privacy_and_security',
                            title: localized(privacySecurity),
                          ),

                          /// Data and Storage
                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.dataAndStorage.type),
                            iconName: 'data_and_storage',
                            title: localized(dataStorage),
                          ),

                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.generalSettings.type),
                            iconName: 'general_settings',
                            title: localized(generalSettings),
                          ),

                          SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.networkDiagnose.type),
                            iconName: 'network_diagnose',
                            title: localized(networkDiagnose),
                          ),

                          /// Language
                          Obx(
                            () => SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.language.type),
                              iconName: 'language',
                              title: localized(language),
                              rightTitle: controller.languageText.value,
                              rightTitleColor: colorTextSecondary,
                              withBorder: false,
                            ),
                          ),

                          /// Date and time
                          // SettingItem(
                          //   onTap: () => controller.onSettingOptionTap(
                          //       context, SettingOption.dateTime.type),
                          //   iconName: 'date_time',
                          //   title: localized(dateTime),
                          //   withBorder: false,
                          // ),
                        ],
                      ),
                    ),

                    /// App and Device info
                    Container(
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: boxDecoration,
                      child: Column(children: settingItemList(context)),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> settingItemList(BuildContext context) {
    List<Widget> list = [
      SettingItem(
        onTap: () => controller.onSettingOptionTap(
            context, SettingOption.inviteFriends.type),
        iconName: 'Heart',
        title: localized(inviteFriends),
      ),

      /// app info
      SettingItem(
        onTap: () =>
            controller.onSettingOptionTap(context, SettingOption.appInfo.type),
        iconName: 'app_info',
        title: localized(appInfo),
        rightWidget: Obx(
          () => Visibility(
            visible: controller.isVersionUpdate.value,
            child: const Icon(
              Icons.circle,
              color: colorRed,
              size: 8,
            ),
          ),
        ),
      ),

      /// log out
      SettingItem(
        onTap: () =>
            controller.onSettingOptionTap(context, SettingOption.logout.type),
        iconName: 'log_out',
        title: localized(mySettingLogout),
        withBorder: false,
        titleColor: colorRed,
      ),
    ];
    // 增加测试页面
    if (Config().isDebug) {
      list.add(SettingItem(
        onTap: () =>
            controller.onSettingOptionTap(context, SettingOption.testPage.type),
        iconName: 'log_out',
        title: 'test page',
        withBorder: false,
        titleColor: colorRed,
      ));
    }
    return list;
  }
}
