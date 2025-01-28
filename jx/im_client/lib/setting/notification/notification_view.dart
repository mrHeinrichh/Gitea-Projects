import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(notifSound),
        onPressedBackBtn: objectMgr.loginMgr.isDesktop
            ? () {
                Get.back(id: 3);
                Get.find<SettingController>().desktopSettingCurrentRoute = '';
                Get.find<SettingController>().selectedIndex.value = 101010;
              }
            : null,
      ),
      body: Column(
        children: [
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
                          subtitleStyle: jxTextStyle.normalSmallText(
                            color: colorTextSecondary,
                          ),
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
                          subtitleStyle: jxTextStyle.normalSmallText(
                            color: colorTextSecondary,
                          ),
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
                              rightWidget: CustomCupertinoSwitch(
                                value:
                                    controller.messageSoundNotification.value,
                                callBack:
                                    controller.setMessageSoundStatusRemote,
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
      child: Text(title,
          style: jxTextStyle.normalSmallText(
            color: colorTextLevelTwo,
          )),
    );
  }
}
