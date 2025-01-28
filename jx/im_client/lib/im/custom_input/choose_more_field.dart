import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';

class ChooseMoreField extends StatelessWidget {
  final CustomInputController controller;

  const ChooseMoreField({
    super.key,
    required this.controller,
  });

  bool deleteMessagePermissionCheck(Message message) {
    return objectMgr.userMgr.isMe(message.send_id) &&
        DateTime.now().millisecondsSinceEpoch - (message.create_time * 1000) <
            const Duration(days: 1).inMilliseconds;
  }

  CustomInputController get inputController => Get.find<CustomInputController>(
      tag: controller.chatController.chat.id.toString());

  @override
  Widget build(BuildContext context) {
    bool isDesktop = objectMgr.loginMgr.isDesktop;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 13.0 : 16.0),
      child: Obx(() {
        bool hasSelect =
            controller.chatController.chooseMessage.values.isNotEmpty;
        bool canDelete = hasSelect && controller.chatController.canDelete.value;
        bool canForward =
            hasSelect && controller.chatController.canForward.value;
        bool enableFavourite =
            hasSelect && controller.chatController.isEnableFavourite.value;

        return Row(
          children: <Widget>[
            /// 刪除
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!hasSelect) {
                        Toast.showToast(localized(toastSelectMessage));
                        return;
                      }

                      if (canDelete) {
                        bool showDeleteForEveryone = true;
                        for (Message message
                            in controller.chatController.chooseMessage.values) {
                          if (!controller.chatController.chat.isValid ||
                              controller.chatController.chat.isSaveMsg ||
                              message.typ == messageTypeSendRed ||
                              controller.chatController.chat.typ ==
                                  chatTypeSmallSecretary) {
                            showDeleteForEveryone = false;
                            break;
                          } else {
                            if (inputController.type == chatTypeGroup) {
                              final GroupChatController groupController =
                                  Get.find<GroupChatController>(
                                      tag: controller.chatController.chat.id
                                          .toString());
                              if (groupController.isOwner) {
                                if (objectMgr.userMgr.isMe(message.send_id)) {
                                  showDeleteForEveryone =
                                      deleteMessagePermissionCheck(message);
                                  if (!showDeleteForEveryone) break;
                                }
                              } else if (groupController.isAdmin) {
                                if (objectMgr.userMgr.isMe(message.send_id)) {
                                  showDeleteForEveryone =
                                      deleteMessagePermissionCheck(message);
                                  if (!showDeleteForEveryone) break;
                                } else if (groupController.group.value !=
                                        null &&
                                    groupController.group.value!.owner ==
                                        message.send_id) {
                                  showDeleteForEveryone = false;
                                  break;
                                }
                              } else {
                                showDeleteForEveryone =
                                    deleteMessagePermissionCheck(message);
                                if (!showDeleteForEveryone) break;
                              }
                            } else if (inputController.type == chatTypeSingle) {
                              showDeleteForEveryone =
                                  deleteMessagePermissionCheck(message);
                              if (!showDeleteForEveryone) break;
                            }
                          }
                        }

                        showCustomBottomAlertDialog(
                          context,
                          withHeader: false,
                          cancelTextColor: themeColor,
                          items: [
                            CustomBottomAlertItem(
                              text: localized(deleteForMe),
                              textColor: colorRed,
                              onClick: () {
                                controller.onDeleteMessage(
                                  context,
                                  controller.chatController.chooseMessage.values
                                      .toList(),
                                  isMore: true,
                                );
                              },
                            ),
                            if (showDeleteForEveryone)
                              CustomBottomAlertItem(
                                text: localized(deleteForEveryone),
                                textColor: colorRed,
                                onClick: () {
                                  controller.onDeleteMessage(
                                    context,
                                    controller
                                        .chatController.chooseMessage.values
                                        .toList(),
                                    isMore: true,
                                    isAll: true,
                                  );
                                },
                              ),
                          ],
                        );
                      }
                    },
                    child: OpacityEffect(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomImage(
                            'assets/svgs/muti_selected_del.svg',
                            size: isDesktop ? 20 : 24.0,
                            padding: EdgeInsets.only(
                              left: isDesktop ? 20.0 : 12.0,
                              right: isDesktop ? 8.0 : 16.0,
                            ),
                            color: canDelete
                                ? isDesktop
                                    ? colorRed
                                    : themeColor
                                : colorTextPlaceholder,
                          ),
                          if (isDesktop)
                            Text(
                              localized(delete),
                              style: jxTextStyle.textStyleBold14(
                                color:
                                    canDelete ? colorRed : colorTextPlaceholder,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// 收藏
            Expanded(
              child: Center(
                child: isDesktop
                    ? Text(
                        localized(
                          'selectedWithParam',
                          params: [
                            '${controller.chatController.chooseMessage.values.toList().length}',
                          ],
                        ),
                        style: jxTextStyle.textStyleBold15(),
                      )
                    : CustomImage(
                        onClick: () {
                          if (!hasSelect) {
                            Toast.showToast(localized(toastSelectMessage));
                            return;
                          }

                          if (enableFavourite) {
                            List<Message> listMessages = controller
                                .chatController.chooseMessage.values
                                .toList();
                            objectMgr.favouriteMgr.addMessageToFavourite(
                              listMessages,
                              controller.chat!,
                            );
                            controller.chatController.onChooseMoreCancel();
                          } else {
                            imBottomToast(
                              context,
                              title: localized(isWalletEnable()
                                  ? cannotFavouriteSelectedWallet
                                  : cannotFavouriteSelected),
                              icon: ImBottomNotifType.INFORMATION,
                            );
                          }
                        },
                        'assets/svgs/favourite_icon.svg',
                        size: 24.0,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        color:
                            enableFavourite ? themeColor : colorTextPlaceholder,
                      ),
              ),
            ),

            /// 轉發
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!hasSelect) {
                        Toast.showToast(localized(toastSelectMessage));
                        return;
                      }

                      if (canForward) {
                        controller.onForwardMessage(context: context);
                      } else {
                        imBottomToast(
                          context,
                          title: localized(isWalletEnable()
                              ? cannotForwardSelectedWallet
                              : cannotForwardSelected),
                          icon: ImBottomNotifType.INFORMATION,
                        );
                      }
                    },
                    child: OpacityEffect(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDesktop)
                            Text(
                              localized(forward),
                              style: jxTextStyle.textStyleBold14(
                                color: canForward
                                    ? themeColor
                                    : colorTextPlaceholder,
                              ),
                            ),
                          CustomImage(
                            'assets/svgs/muti_selected_forward.svg',
                            size: isDesktop ? 20 : 24.0,
                            padding: EdgeInsets.only(
                              left: isDesktop ? 8.0 : 16.0,
                              right: isDesktop ? 20.0 : 12.0,
                            ),
                            color:
                                canForward ? themeColor : colorTextPlaceholder,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
