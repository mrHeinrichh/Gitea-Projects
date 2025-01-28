import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/setting/Notification/notification_controller.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../main.dart';
import '../../object/chat/chat.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/saved_message_icon.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../../views/component/new_appbar.dart';

class NotificationSettingView extends GetView<NotificationController> {
  const NotificationSettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
              /// show notification
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
                        activeColor: accentColor,
                        onChanged: controller.setNotification,
                      ),
                    ),
                  ),
                ),
              ),

              /// message preview and notification type
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
                                activeColor: accentColor,
                                onChanged: controller.setPreview,
                              ),
                            ),
                          ),
                          SettingItem(
                            onTap: () {
                              if (controller.getShowNotificationVariable()) {
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(RouteName.notificationType,
                                      id: 3);
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
                            withBorder: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// mute list and delete all mute
              Flexible(
                child: Visibility(
                  visible: controller.getExceptionList().length > 0,
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
                                      imgWidget = Image.asset(
                                        'assets/images/message_new/secretary.png',
                                        width: 40,
                                        height: 40,
                                      );
                                    } else if (controller
                                            .getExceptionList()[index]
                                            .chatType ==
                                        chatTypeSaved) {
                                      imgWidget = const SavedMessageIcon(
                                        size: 40,
                                      );
                                    } else {
                                      imgWidget = CustomAvatar(
                                        key: UniqueKey(),
                                        uid:
                                            controller.getGroupInfoValue(index),
                                        isGroup:
                                            controller.notificationSection ==
                                                NotificationSection.groupChat,
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
                                    } else {
                                      titleWidget = NicknameText(
                                        key: UniqueKey(),
                                        uid:
                                            controller.getGroupInfoValue(index),
                                        fontWeight: MFontWeight.bold5.value,
                                        isGroup:
                                            controller.notificationSection ==
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
                                            backgroundColor: JXColors.red,
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
                                        confirmButtonColor: errorColor,
                                        confirmCallback: () =>
                                            controller.deleteAllException(),
                                        cancelCallback: () =>
                                            Navigator.of(context).pop(),
                                        cancelButtonColor: accentColor,
                                      );
                                    },
                                  );
                                },
                                iconName: 'delete_icon',
                                title: localized(notifDeleteAllMute),
                                titleColor: errorColor,
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

              /// mute list
              // SliverVisibility(
              //   visible: controller.getExceptionList().length > 0,
              //   sliver: SliverToBoxAdapter(
              //     child: Container(
              //       width: double.infinity,
              //       padding: const EdgeInsets.symmetric(
              //           vertical: 10, horizontal: 20),
              //       decoration: BoxDecoration(
              //         border: customBorder,
              //       ),
              //       child: Text(localized(notifMuteList),
              //           style: jxTextStyle.textStyle14(
              //               color: JXColors.secondaryTextBlack)),
              //     ),
              //   ),
              // ),

              // SliverVisibility(
              //   visible: controller.showExceptionList(),
              //   sliver: SliverList(
              //     delegate: SliverChildBuilderDelegate(
              //       childCount: controller.getExceptionList().length,
              //       (context, index) {
              //         return Slidable(
              //           key: UniqueKey(),
              //           closeOnScroll: true,
              //           endActionPane: ActionPane(
              //             motion: const StretchMotion(),
              //             extentRatio: 0.25,
              //             children: [
              //               CustomSlidableAction(
              //                 onPressed: (context) {
              //                   controller.unMuteSpecificChat(index);
              //                 },
              //                 backgroundColor: JXColors.red,
              //                 foregroundColor: Colors.white,
              //                 child: Text(
              //                   localized(buttonDelete),
              //                   maxLines: 1,
              //                   overflow: TextOverflow.ellipsis,
              //                 ),
              //               ),
              //             ],
              //           ),
              //           child: Container(
              //             padding: const EdgeInsets.symmetric(
              //                 horizontal: 20, vertical: 10),
              //             decoration: const BoxDecoration(
              //               border: Border(
              //                 bottom: BorderSide(
              //                     color: JXColors.lightGrey, width: 1),
              //               ),
              //             ),
              //             child: Row(
              //               children: [
              //                 if (controller
              //                         .getExceptionList()[index]
              //                         .chatType ==
              //                     chatTypeSmallSecretary) ...{
              //                   Image.asset(
              //                     'assets/images/message_new/secretary.png',
              //                     width: 50,
              //                     height: 50,
              //                   )
              //                 } else if (controller
              //                         .getExceptionList()[index]
              //                         .chatType ==
              //                     chatTypeSaved) ...{
              //                   const SavedMessageIcon(
              //                     size: 50,
              //                   )
              //                 } else ...{
              //                   CustomAvatar(
              //                     key: UniqueKey(),
              //                     uid: controller.getGroupInfoValue(index),
              //                     isGroup: controller.notificationSection ==
              //                         NotificationSection.groupChat,
              //                     size: 50,
              //                   ),
              //                 },
              //                 Padding(
              //                   padding: const EdgeInsets.symmetric(
              //                       horizontal: 10.0),
              //                   child: Column(
              //                     crossAxisAlignment: CrossAxisAlignment.start,
              //                     children: [
              //                       if (controller
              //                               .getExceptionList()[index]
              //                               .chatType ==
              //                           chatTypeSmallSecretary) ...{
              //                         Text(
              //                           localized(chatSecretary),
              //                           maxLines: 1,
              //                           overflow: TextOverflow.ellipsis,
              //                           style: const TextStyle(
              //                             fontWeight: MFontWeight.bold5.value,
              //                           ),
              //                         )
              //                       } else if (controller
              //                               .getExceptionList()[index]
              //                               .chatType ==
              //                           chatTypeSaved) ...{
              //                         Text(
              //                           localized(homeSavedMessage),
              //                           maxLines: 1,
              //                           overflow: TextOverflow.ellipsis,
              //                           style: const TextStyle(
              //                             fontWeight: MFontWeight.bold5.value,
              //                           ),
              //                         )
              //                       } else ...{
              //                         NicknameText(
              //                           key: UniqueKey(),
              //                           uid:
              //                               controller.getGroupInfoValue(index),
              //                           fontWeight: MFontWeight.bold5.value,
              //                           isGroup:
              //                               controller.notificationSection ==
              //                                   NotificationSection.groupChat,
              //                           isTappable: false,
              //                         ),
              //                       },
              //                       const SizedBox(height: 5),
              //                       Text(
              //                         '${controller.getMuteDetail(index)}',
              //                         style: const TextStyle(
              //                           fontSize: 14,
              //                           color: JXColors.darkGrey,
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                 )
              //               ],
              //             ),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
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
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }
}
