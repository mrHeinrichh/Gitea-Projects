import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/chat_edit_view.dart';
import 'package:jxim_client/im/custom_input/chat_reply_view.dart';
import 'package:jxim_client/im/custom_input/chat_translate_bar.dart';
import 'package:jxim_client/im/custom_input/component/media_selector_view.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/text_input_field_factory.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';

abstract class CustomInputViewComponent extends StatelessWidget {
  final String tag;
  late final CustomInputController controller;

  CustomInputViewComponent({super.key, required this.tag}) {
    controller = Get.find<CustomInputController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CustomInputController>(
      init: controller,
      tag: tag,
      builder: (_) {
        return Obx(() {
          return WillPopScope(
            onWillPop: controller.isRecording.value
                ? () async {
                    controller.toggleRecordingState(false, false);
                    controller.resetRecordingState();
                    return false;
                  }
                : controller.chatController.showFaceView.value &&
                        Platform.isAndroid
                    ? () async {
                        controller.chatController.showFaceView.value = false;
                        controller.chatController.update();
                        return false;
                      }
                    : onOtherClick(),
            child: buildContent(controller, context),
          );
        });
      },
    );
  }

  Widget buildContent(CustomInputController controller, BuildContext context);

  /// 输入框组件
  Widget buildInputField(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        /// 回复消息
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: notBlank(objectMgr.chatMgr.replyMessageMap[controller.chatId])
              ? ChatReplyView(
                  chat: controller.chatController.chat,
                  controller: controller,
                )
              : notBlank(objectMgr.chatMgr.editMessageMap[controller.chatId])
                  ? ChatEditView(
                      chat: controller.chatController.chat,
                      controller: controller,
                    )
                  : const SizedBox(),
        ),

        Obx(() {
          return Visibility(
            visible: controller.showTranslateBar.value,
            child: ChatTranslateBar(
              isTranslating: controller.isTranslating.value,
              translatedText: controller.translatedText.value,
              chat: controller.chat!,
              translateLocale: controller.translateLocale.value,
            ),
          );
        }),

        /// 聊天框
        controller.type == 2
            ? Obx(
                () => controller.chatController.inputType.value == 0
                    ? normalTextingBar(context)
                    : buildDisallowChat(
                        context,
                        controller.chatController.chat,
                        isChatDeleted: false,
                      ),
              )
            : normalTextingBar(context),
      ],
    );
  }

  Widget normalTextingBar(
    BuildContext context, {
    bool isShowAttachment = true,
    bool isShowSticker = true,
    bool isTextingAllowed = true,
  }) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    return Container(
      decoration: isDesktop
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorBorder,
                  width: 1,
                ),
              ),
            )
          : null,
      child: TextInputFieldFactory.createComponent(
        tag: tag,
        isShowAttachment: isShowAttachment,
        isShowSticker: isShowSticker,
        isTextingAllowed: isTextingAllowed,
      ),
    );
  }

  /// 不允许用户输入
  Widget buildDisallowChat(
    BuildContext context,
    Chat chat, {
    bool isChatDeleted = true,
  }) {
    Widget child = Text(
      chat.typ == chatTypeSingle
          ? (controller.user.value?.deletedAt != 0)
              ? localized(thisUserIsNotLongerExits)
              : localized(messagingIsOnlyAllowedBetweenFriends)
          // : controller.chatController.chat.isSystem
          //     ? localized(cannotMessage)
          //     : chat.isDisband
          //         ? localized(chatThisGroupIsDisbanded)
          //         : localized(chatYouAreNotTheGroupMember),
          : chat.isDisband
              ? localized(chatThisGroupIsDisbanded)
              : localized(chatYouAreNotTheGroupMember),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: MFontWeight.bold6.value,
      ),
    );

    if (controller.user.value?.relationship == Relationship.blocked) {
      child = GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(
                  unblockUserName,
                  params: [
                    objectMgr.userMgr.getUserTitle(controller.user.value),
                  ],
                ),
                content: Text(
                  localized(unblockUserDesc),
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmText: localized(buttonUnblock),
                cancelText: localized(buttonNo),
                confirmCallback: () =>
                    objectMgr.userMgr.unblockUser(controller.user.value!),
              );
            },
          );
        },
        child: Text(
          localized(unblockUser),
          style: TextStyle(
            color: colorRed,
            fontWeight: MFontWeight.bold6.value,
          ),
        ),
      );
    }

    if (controller.user.value?.relationship == Relationship.blockByTarget) {
      child = Text(
        localized(blockedTextBar),
        style: jxTextStyle.textStyleBold14(color: Colors.grey.shade600),
      );
    }

    if (!isChatDeleted) {
      if (controller.chatController.inputType.value == 1) {
        child = TextInputFieldFactory.createComponent(
          tag: tag,
          isTextingAllowed: false,
        );
      } else if (controller.chatController.inputType.value == 2) {
        child = GestureDetector(
          onTap: () {
            onMore(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: themeColor,
                size: 24,
              ),
              const SizedBox(width: 5),
              Text(
                localized(addAttachment),
                style: TextStyle(
                  color: themeColor,
                  fontSize: 16,
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ],
          ),
        );
      } else if (controller.chatController.inputType.value == 3) {
        child = GestureDetector(
          onTap: () async {
            if (controller.chatController.showFaceView.value) {
              controller.inputState = 1;
              controller.chatController.showFaceView.value = false;
              controller.assetPickerProvider?.selectedAssets = [];
              controller.inputFocusNode.requestFocus();

              controller.inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.inputController.text.length),
              );
            } else {
              controller.chatController.showFaceView.value = true;

              /// 移除输入法焦点
              if (controller.inputFocusNode.hasFocus) {
                controller.inputState = 1;
              } else {
                controller.inputState = 2;
              }
              controller.inputFocusNode.unfocus();
            }
            controller.chatController.update();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/sticker_icon.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 5),
              Text(
                localized(addSticker),
                style: TextStyle(
                  color: themeColor,
                  fontSize: 16,
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ],
          ),
        );
      } else if (controller.chatController.inputType.value == 4) {
        child = Text(
          localized(sendingMessagesIsNotAllowed),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: MFontWeight.bold6.value,
          ),
        );
      } else if (controller.chatController.inputType.value == 5) {
        child = normalTextingBar(context, isShowSticker: false);
      } else if (controller.chatController.inputType.value == 6) {
        child = normalTextingBar(context, isShowAttachment: false);
      } else {
        child = normalTextingBar(
          context,
          isShowAttachment: false,
          isShowSticker: false,
        );
      }
    }

    return SizedBox(
      height: 54,
      child: Center(child: child),
    );
  }

  void onMore(BuildContext context) async {
    /// {{更多}} 选项已经开启 并且 键盘没有出现

    controller.onShowScreenShotsImg(context);
    controller.chatController.showFaceView.value = false;

    if (controller.inputFocusNode.hasFocus) {
      controller.inputState = 1;
    } else {
      controller.inputState = 2;
    }

    try {
      await controller.onPrepareMediaPicker();
      controller.inputFocusNode.unfocus();
      showBottomPopup(true);
    } on StateError catch (_) {
      showBottomPopup(false);
    }
  }

  void showBottomPopup(bool permissionStatus) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return MediaSelectorView(tag, permissionStatus);
      },
    ).then((value) {
      if (value != null &&
          value['fromViewer'] != null &&
          value['assets'] != null &&
          value['assets'].isNotEmpty) {
        controller.onSendAsset(value['assets'], controller.chatId);
      }
    }).whenComplete(() {
      controller.assetPickerProvider
          ?.removeListener(controller.onAssetPickerChanged);
      controller.assetPickerProvider?.selectedAssets.clear();
      controller.inputController.clear();
      controller.sendState.value = false;
      Get.findAndDelete<FilePickerController>();
      Get.findAndDelete<RedPacketController>();
      Get.findAndDelete<LocationController>();

      Future.delayed(const Duration(milliseconds: 200), () {
        controller.chatController.clearContactSearching();
      });
    });
  }

  onOtherClick();

  Widget buildMoreWidget(CustomInputController controller);
}
