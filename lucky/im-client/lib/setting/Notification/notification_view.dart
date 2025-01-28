import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import '../../home/setting/setting_controller.dart';
import '../../home/setting/setting_item.dart';
import '../../main.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../views/component/click_effect_button.dart';
import 'notification_controller.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              bgColor: Colors.transparent,

              /// TODO: update to local text
              title: localized(notifSound),
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    color: JXColors.outlineColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                /// 普通界面
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(id: 3);
                        Get.find<SettingController>()
                            .desktopSettingCurrentRoute = '';
                        Get.find<SettingController>().selectedIndex.value =
                            101010;
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/Back.svg',
                              width: 18,
                              height: 18,
                              color: JXColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JXColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(notifSound),
                    style: const TextStyle(
                      fontSize: 16,
                      color: JXColors.black,
                    ),
                  ),
                  const SizedBox()
                ],
              ),
            ),
          SingleChildScrollView(
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// chat
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SettingItem(
                            onTap: () {
                              controller.notificationSection.value =
                                  NotificationSection.privateChat;
                              if (objectMgr.loginMgr.isDesktop) {
                                Get.toNamed(RouteName.notificationSetting,
                                    id: 3);
                              } else {
                                Get.toNamed(RouteName.notificationSetting);
                              }
                            },
                            iconName: 'setting_user',
                            title: localized(notifPrivatesChat),
                            subtitle:
                                '${controller.privateChatMuteList.length} ${localized(notifExceptions)}',
                            rightTitle:
                                '${controller.privateChatMute.value.getStatus}',
                          ),
                          SettingItem(
                            onTap: () {
                              controller.notificationSection.value =
                                  NotificationSection.groupChat;
                              if (objectMgr.loginMgr.isDesktop) {
                                Get.toNamed(RouteName.notificationSetting,
                                    id: 3);
                              } else {
                                Get.toNamed(RouteName.notificationSetting);
                              }
                            },
                            iconName: 'setting_group_chat',
                            title: localized(notifGroupChats),
                            subtitle:
                                '${controller.groupChatMuteList.length}  ${localized(notifExceptions)}',
                            rightTitle:
                                '${controller.groupChatMute.value.getStatus}',
                            withBorder: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildTitle(localized(mySettingNotification)),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Visibility(
                            visible: Config().enableWallet,
                            child: SettingItem(
                              onTap: () {
                                controller.notificationSection.value =
                                    NotificationSection.wallet;
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(RouteName.notificationSetting,
                                      id: 3);
                                } else {
                                  Get.toNamed(RouteName.notificationSetting);
                                }
                              },
                              title: localized(notifWalletFund),
                              rightTitle:
                                  '${controller.walletMute.value.getStatus}',
                            ),
                          ),
                          SettingItem(
                            onTap: () {
                              controller.notificationSection.value =
                                  NotificationSection.friend;
                              if (objectMgr.loginMgr.isDesktop) {
                                Get.toNamed(RouteName.notificationSetting,
                                    id: 3);
                              } else {
                                Get.toNamed(RouteName.notificationSetting);
                              }
                            },
                            title: localized(contactFriendRequestAccept),
                            rightTitle:
                                '${controller.friendMute.value.getStatus}',
                            withBorder: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildTitle(localized(notificationSound)),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SettingItem(
                        withEffect: false,
                        title: localized(sendingAMessage),
                        withArrow: false,
                        withBorder: false,
                        rightWidget: SizedBox(
                          height: 28,
                          width: 48,
                          child: CupertinoSwitch(
                            value: controller.messageSoundNotification.value,
                            activeColor: accentColor,
                            onChanged: controller.setMessageSoundStatusRemote,
                          ),
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
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: objectMgr.loginMgr.isDesktop
          ? const EdgeInsets.only(left: 16, bottom: 4)
          : const EdgeInsets.only(left: 16, bottom: 4).w,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }
}
