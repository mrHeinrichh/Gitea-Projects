import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              bgColor: Colors.transparent,
              title: localized(notifSound),
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                color: colorBackground,
                border: Border(
                  bottom: BorderSide(
                    color: colorBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
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
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: TextStyle(
                                fontSize: 13,
                                color: themeColor,
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
                      color: colorTextPrimary,
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          Obx(
            () => Expanded(
              child: CustomScrollableListView(
                children: [
                  // Private Chat & Group Chat
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
                              Get.toNamed(
                                RouteName.notificationSetting,
                                id: 3,
                              );
                            } else {
                              Get.toNamed(RouteName.notificationSetting);
                            }
                          },
                          iconName: 'setting_user',
                          title: localized(notifPrivatesChat),
                          subtitle:
                              '${controller.privateChatMuteList.length} ${localized(notifExceptions)}',
                          rightTitle:
                              controller.privateChatMute.value.getStatus,
                        ),
                        SettingItem(
                          onTap: () {
                            controller.notificationSection.value =
                                NotificationSection.groupChat;
                            if (objectMgr.loginMgr.isDesktop) {
                              Get.toNamed(
                                RouteName.notificationSetting,
                                id: 3,
                              );
                            } else {
                              Get.toNamed(RouteName.notificationSetting);
                            }
                          },
                          iconName: 'setting_group_chat',
                          title: localized(notifGroupChats),
                          subtitle:
                              '${controller.groupChatMuteList.length}  ${localized(notifExceptions)}',
                          rightTitle: controller.groupChatMute.value.getStatus,
                          withBorder: false,
                        ),
                      ],
                    ),
                  ),

                  // Prompt Sound
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(localized(notificationSound)),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            SettingItem(
                              withEffect: false,
                              title: localized(sendingAMessage),
                              withArrow: false,
                              withBorder: true,
                              rightWidget: SizedBox(
                                height: 28,
                                width: 48,
                                child: CupertinoSwitch(
                                  value:
                                      controller.messageSoundNotification.value,
                                  activeColor: themeColor,
                                  onChanged:
                                      controller.setMessageSoundStatusRemote,
                                ),
                              ),
                            ),
                            SettingItem(
                              onTap: () => controller.changeSound(
                                SoundTrackType.SoundTypeSendMessage.value,
                              ),
                              title: localized(notifSoundType),
                              withBorder: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Notification
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              visible: isWalletEnable(),
                              child: SettingItem(
                                onTap: () {
                                  controller.notificationSection.value =
                                      NotificationSection.wallet;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.notificationSetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(RouteName.notificationSetting);
                                  }
                                },
                                title: localized(notifWalletFund),
                                rightTitle:
                                    controller.walletMute.value.getStatus,
                                rightTitleFlex: 0,
                              ),
                            ),
                            SettingItem(
                              onTap: () {
                                controller.notificationSection.value =
                                    NotificationSection.friend;
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(
                                    RouteName.notificationSetting,
                                    id: 3,
                                  );
                                } else {
                                  Get.toNamed(RouteName.notificationSetting);
                                }
                              },
                              title: localized(contactFriendRequestAccept),
                              rightTitle: controller.friendMute.value.getStatus,
                              rightTitleFlex: 0,
                              withBorder: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
          color: colorTextSecondary,
        ),
      ),
    );
  }
}
