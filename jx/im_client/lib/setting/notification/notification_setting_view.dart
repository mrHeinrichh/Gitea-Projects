import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

class NotificationSettingView extends GetView<NotificationController> {
  const NotificationSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: controller.notificationSection.value.toTitle ?? "",
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SettingItem(
                  withEffect: false,
                  title: localized(notifShowNotification),
                  withArrow: false,
                  withBorder: false,
                  rightWidget: CustomCupertinoSwitch(
                    value: controller.getShowNotificationVariable(),
                    callBack: (value) => controller.setNotification(value),
                  ),
                ),
              ),
              Visibility(
                visible: controller.getShowNotificationVariable(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(localized(notifOptions)),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SettingItem(
                            withEffect: false,
                            onTap: () {},
                            title: localized(notifMessagePreview),
                            withArrow: false,
                            rightWidget: CustomCupertinoSwitch(
                              value: controller.getShowPreviewVariable(),
                              callBack: controller.setPreview,
                            ),
                          ),
                          SettingItem(
                            onTap: () {
                              if (controller.getShowNotificationVariable()) {
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(
                                    RouteName.notificationType,
                                    id: 3,
                                  );
                                } else {
                                  Get.toNamed(RouteName.notificationType);
                                }
                              } else {
                                Toast.showToast(localized(notifManageNT));
                              }
                            },
                            title: localized(notificationType),
                            rightTitle:
                                controller.getNotificationMode().toStatus,
                            withBorder: true,
                          ),
                          Visibility(
                            visible: controller.notificationSection.value ==
                                    NotificationSection.privateChat ||
                                controller.notificationSection.value ==
                                    NotificationSection.groupChat,
                            child: SettingItem(
                              onTap: () => controller.onClickChangeSound(),
                              title: localized(notifSoundType),
                              withBorder: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Visibility(
                  visible: controller.getExceptionList().isNotEmpty,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(localized(notifExceptions)),
                      Flexible(
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SlidableAutoCloseBehavior(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount:
                                        controller.getExceptionList().length,
                                    itemBuilder: (BuildContext context, index) {
                                      Widget imgWidget;
                                      if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSmallSecretary) {
                                        imgWidget = const SecretaryMessageIcon(
                                            size: 40);
                                      } else if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSaved) {
                                        imgWidget = const SavedMessageIcon(
                                          size: 40,
                                        );
                                      } else if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSystem) {
                                        imgWidget = const SystemMessageIcon(
                                          size: 40,
                                        );
                                      } else {
                                        imgWidget = CustomAvatar(
                                          key: UniqueKey(),
                                          dataProvider: DataProvider(
                                            uid: controller
                                                .getGroupInfoValue(index),
                                            isGroup: controller
                                                    .notificationSection
                                                    .value ==
                                                NotificationSection.groupChat,
                                          ),
                                          headMin: Config().headMin,
                                          size: 40,
                                        );
                                      }

                                      Widget titleWidget;
                                      if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSmallSecretary) {
                                        titleWidget = Text(
                                          localized(chatSecretary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: jxTextStyle.headerText(
                                            fontWeight: MFontWeight.bold5.value,
                                          ),
                                        );
                                      } else if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSaved) {
                                        titleWidget = Text(
                                          localized(homeSavedMessage),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: jxTextStyle.headerText(
                                            fontWeight: MFontWeight.bold5.value,
                                          ),
                                        );
                                      } else if (controller
                                              .getExceptionList()[index]
                                              .chatType ==
                                          chatTypeSystem) {
                                        titleWidget = Text(
                                          localized(homeSystemMessage),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: jxTextStyle.headerText(
                                            fontWeight: MFontWeight.bold5.value,
                                          ),
                                        );
                                      } else {
                                        titleWidget = NicknameText(
                                          key: UniqueKey(),
                                          uid: controller
                                              .getGroupInfoValue(index),
                                          fontSize: MFontSize.size17.value,
                                          fontWeight: MFontWeight.bold5.value,
                                          isGroup: controller
                                                  .notificationSection.value ==
                                              NotificationSection.groupChat,
                                          isTappable: false,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }

                                      return Slidable(
                                        key: UniqueKey(),
                                        closeOnScroll: true,
                                        endActionPane: ActionPane(
                                          motion: const StretchMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            CustomSlidableAction(
                                              onPressed: (context) {
                                                controller
                                                    .unMuteSpecificChat(index);
                                              },
                                              backgroundColor: colorRed,
                                              foregroundColor: Colors.white,
                                              child: Text(
                                                localized(buttonDelete),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: SettingItem(
                                          withEffect: false,
                                          imgWidget: imgWidget,
                                          titleWidget: titleWidget,
                                          subtitle:
                                              controller.getMuteDetail(index),
                                          withArrow: false,
                                          subtitleStyle:
                                              jxTextStyle.normalSmallText(
                                            color: colorTextSecondary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SettingItem(
                                  onTap: () {
                                    showCustomBottomAlertDialog(
                                      context,
                                      subtitle: localized(notifDeleteAllText),
                                      confirmText: localized(notifDeleteAll),
                                      confirmTextColor: colorRed,
                                      cancelTextColor: themeColor,
                                      onConfirmListener: () =>
                                          controller.deleteAllException(),
                                    );
                                  },
                                  imgWidget: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: SvgPicture.asset(
                                      'assets/svgs/delete_chat.svg',
                                      width: 28,
                                      height: 28,
                                      color: colorRed,
                                    ),
                                  ),
                                  title: localized(notifDeleteAllMute),
                                  titleColor: colorRed,
                                  withArrow: false,
                                  withBorder: false,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 4),
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
