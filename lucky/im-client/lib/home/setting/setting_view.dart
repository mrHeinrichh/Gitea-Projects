import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../utils/theme/text_styles.dart';
import '../../utils/utility.dart';

class SettingView extends GetView<SettingController> {
  SettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 7),
              children: [
                /// 用户资料
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      /// 头像
                      GestureDetector(
                        onTap: () =>
                            showProfileAvatar(controller.user.value?.id,controller.user.value?.id, false),
                        child: Hero(
                          tag: 'avatarHero', //
                          child: CustomAvatar(
                            uid: controller.user.value?.uid ?? 0,
                            size: 100,
                            headMin: Config().messageMin,
                          ),
                        ),
                      ),
                      ImGap.vGap16,
                      Obx(
                        () => Text(
                          controller.nickname.value,
                          style: jxTextStyle.textStyleBold24(
                            fontWeight: MFontWeight.bold6.value,
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
                          style: jxTextStyle.textStyle16(
                            color: JXColors.secondaryTextBlack,
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
                  child: Column(
                    children: [
                      /// 钱包
                      if (Config().enableWallet)
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

                      /// 视频号
                      if (Config().enableReel)
                        Container(
                          clipBehavior: Clip.hardEdge,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: boxDecoration,
                          child: SettingItem(
                            onTap: () => controller.onSettingOptionTap(
                                context, SettingOption.channel.type),
                            iconName: 'video_play_icon',
                            title: localized(channel),
                            withBorder: false,
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
                              onTap: () => controller.onSettingOptionTap(
                                  context,
                                  SettingOption.notificationAndSound.type),
                              iconName: 'notification',
                              title: localized(notifSound),
                            ),

                            /// privacy and security
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context,
                                  SettingOption.privacyAndSecurity.type),
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

                            /// Language
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.language.type),
                              iconName: 'language',
                              title: localized(language),
                            ),

                            /// Date and time
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.dateTime.type),
                              iconName: 'date_time',
                              title: localized(dateTime),
                              withBorder: false,
                            ),
                          ],
                        ),
                      ),

                      /// App and Device info
                      Container(
                        clipBehavior: Clip.hardEdge,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: boxDecoration,
                        child: Column(children: SettingItemList(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 5,
              left: 0,
              child: OpacityEffect(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(RouteName.qrCodeView,
                      arguments: {"user": controller.user.value}),
                  child: Container(
                    height: 44.w,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SvgPicture.asset(
                      'assets/svgs/qrCode.svg',
                      width: 24,
                      height: 24,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 0,
              child: OpacityEffect(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(RouteName.userBioSetting),
                  child: Container(
                    height: 44.w,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      localized(buttonEdit),
                      style: jxTextStyle.textStyle17(
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> SettingItemList(BuildContext context) {
    List<Widget> list = [
      /// link device
      if (Config().enableDeviceLink)
        SettingItem(
          onTap: () => controller.onSettingOptionTap(
              context, SettingOption.linkDevices.type),
          iconName: 'linked_devices',
          title: localized(linkedDevices),
        ),

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
            child: Icon(
              Icons.circle,
              color: errorColor,
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
        titleColor: JXColors.red,
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
        titleColor: JXColors.red,
      ));
    }
    return list;
  }
}
