import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class NotificationSettingView extends GetView<NotificationController> {
  const NotificationSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: controller.notificationSection.value.toTitle ?? "",
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
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
                    rightWidget: SizedBox(
                      height: 28,
                      width: 48,
                      child: CupertinoSwitch(
                        value: controller.getShowNotificationVariable(),
                        activeColor: themeColor,
                        onChanged: controller.setNotification,
                      ),
                    ),
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
                            rightWidget: SizedBox(
                              height: 28,
                              width: 48,
                              child: CupertinoSwitch(
                                value: controller.getShowPreviewVariable(),
                                activeColor: themeColor,
                                onChanged: controller.setPreview,
                              ),
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
                                      imgWidget = const SecretaryMessageIcon(size: 40);
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
                                                  .notificationSection.value ==
                                              NotificationSection.groupChat,
                                        ),
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
                                        style: TextStyle(
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
                                        style: TextStyle(
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
                                        style: TextStyle(
                                          fontWeight: MFontWeight.bold5.value,
                                        ),
                                      );
                                    } else {
                                      titleWidget = NicknameText(
                                        key: UniqueKey(),
                                        uid:
                                            controller.getGroupInfoValue(index),
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
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SettingItem(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return CustomConfirmationPopup(
                                        title: localized(notifDeleteAllText),
                                        confirmButtonText:
                                            localized(notifDeleteAll),
                                        cancelButtonText:
                                            localized(buttonCancel),
                                        confirmButtonColor: colorRed,
                                        confirmCallback: () =>
                                            controller.deleteAllException(),
                                        cancelCallback: () =>
                                            Navigator.of(context).pop(),
                                        cancelButtonColor: themeColor,
                                      );
                                    },
                                  );
                                },
                                iconName: 'delete_icon',
                                title: localized(notifDeleteAllMute),
                                titleColor: colorRed,
                                withArrow: false,
                                withBorder: false,
                              ),
                            ],
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
