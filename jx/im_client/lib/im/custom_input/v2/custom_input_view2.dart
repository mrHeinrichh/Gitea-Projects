import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/chat_edit_view.dart';
import 'package:jxim_client/im/custom_input/chat_link_preview.dart';
import 'package:jxim_client/im/custom_input/chat_reply_view.dart';
import 'package:jxim_client/im/custom_input/chat_translate_bar.dart';
import 'package:jxim_client/im/custom_input/choose_more_field.dart';
import 'package:jxim_client/im/custom_input/component/media_selector_view.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/searching_bottom_bar.dart';
import 'package:jxim_client/im/custom_input/text_input_field_factory.dart';
import 'package:jxim_client/im/sticker/attachment_keyboard_component.dart';
import 'package:jxim_client/im/sticker/facial_expression_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';

class CustomInputViewV2 extends StatelessWidget {
  final String tags;
  final CustomInputController controller;

  CustomInputViewV2(this.tags, {super.key})
      : controller = Get.find<CustomInputController>(tag: tags);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return WillPopScope(
        onWillPop: controller.isRecording.value
            ? () async {
                ///停止錄音
                controller.toggleRecordingState(false, false);
                controller.resetRecordingState();
                return false;
              }
            : controller.chatController.showFaceView.value && Platform.isAndroid
                ? () async {
                    /// 关闭表情面板
                    controller.chatController.showFaceView.value = false;
                    controller.chatController.update();
                    return false;
                  }
                : onOtherClick(),
        child: buildContent(context),
      );
    });
  }

  Widget buildContent(BuildContext context) {
    return GetBuilder<CustomInputController>(
        init: controller,
        tag: tags,
        builder: (_) {
          return GestureDetector(
            onTap: () {
              controller.chatController.removeShortcutImage();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ///顯示输入框组件(最多3層)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 233),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: !controller.chatController.showFaceView.value &&
                            !controller.inputFocusNode.hasFocus &&
                            !controller
                                .chatController.searchFocusNode.hasFocus &&
                            !controller.chatController.showAttachmentView.value
                        ? MediaQuery.of(context).viewPadding.bottom
                        : 0.0,
                  ),
                  width: double.infinity,
                  color: colorBackground,
                  child: controller.chatController.chooseMore.value
                      ? ChooseMoreField(controller: controller)
                      : controller.chatController.isSearching.value &&
                              !objectMgr.loginMgr.isDesktop
                          ? SearchingBottomBar(
                              listIdx:
                                  controller.chatController.listIndex.value,
                              controller: controller,
                            )
                          : controller.chatController.chatIsDeleted.value ||
                                  (controller.user.value?.deletedAt != null &&
                                      controller.user.value?.deletedAt != 0)
                              ? buildDisallowChat(
                                  context,
                                  controller.chatController.chat,
                                )
                              : buildInputField(context),
                ),

                ///輸入框下方的鍵盤部分，需要判斷顯示系統鍵盤，還是顯示app內部的表情鍵盤
                buildMoreWidget(),
              ],
            ),
          );
        });
  }

  Widget buildMoreWidget() {
    if (objectMgr.loginMgr.isDesktop) return const SizedBox();

    Widget result = Stack(
      children: [
        FacialExpressionComponent(
          isShowAttachment: controller.chatController.showAttachmentView.value,
          chat: controller.chatController.chat,
          isShowSticker: controller.chatController.showFaceView.value,
          isShowStickerPermission:
              controller.chatController.showTextStickerEmoji,
          isFocus: controller.inputFocusNode.hasFocus,
          onDeleteLastOne: () {
            final originalText = controller.inputController.text;
            final newText = originalText.characters.skipLast(1).string;
            controller.inputController.text = newText;
          },
        ),
        AttachmentKeyboardComponent(
          tag: tags,
          chat: controller.chatController.chat,
          isShowSticker: controller.chatController.showFaceView.value,
          isFocus: controller.inputFocusNode.hasFocus,
          isShowAttachment: controller.chatController.showAttachmentView.value,
          options: controller.chatController.attachmentOptions,
          onHideAttachmentView: () =>
              controller.chatController.showAttachmentView.value = false,
        ),
      ],
    );

    if (!Platform.isAndroid) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 133),
        curve: Curves.easeOut,
        height: controller.chatController.showFaceView.value ||
                controller.chatController.showAttachmentView.value
            ? getPanelFixHeight
            : controller.inputFocusNode.hasFocus
                ? getKeyboardHeight
                : 0,
        color: colorBackground,
        child: result,
      );
    } else {
      return Container(
        height: controller.chatController.showFaceView.value ||
                controller.chatController.showAttachmentView.value
            ? getPanelFixHeight
            : controller.inputFocusNode.hasFocus
                ? getKeyboardHeight
                : 0,
        color: colorBackground,
        child: result,
      );
    }
  }

  /// 输入框组件
  /// 最多3個匡：
  ///   1.最底部，輸入框
  ///   2.中間，翻譯框
  ///   3.最上方，鏈結、回覆、編輯框
  Widget buildInputField(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        /// 3.最上方，鏈結、回覆、編輯框
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final isSizedBox = child.key == const ValueKey('input_sized_box');

            /// SizeTransition下到上，上到下動畫.
            return SizeTransition(
              axisAlignment: 1.0,
              sizeFactor: Tween(
                begin: isSizedBox ? 1.0 : 0.0,
                end: isSizedBox ? 0.0 : 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
              ),
              child: child,
            );
          },
          layoutBuilder: (Widget? currentChild, List<Widget> prevChildren) {
            final hasLink =
                notBlank(objectMgr.chatMgr.linkPreviewData[controller.chatId]);
            final hasReply =
                notBlank(objectMgr.chatMgr.replyMessageMap[controller.chatId]);
            final hasEdit =
                notBlank(objectMgr.chatMgr.editMessageMap[controller.chatId]);

            return Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                if (hasLink || hasReply || hasEdit)
                  SizedBox(
                    height: 46.0,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: prevChildren,
                    ),
                  )
                else
                  ...prevChildren,
                if (currentChild != null) currentChild,
                if (currentChild != null &&
                    prevChildren.isNotEmpty &&
                    !hasLink &&
                    hasReply)
                  ...prevChildren,
              ],
            );
          },
          child: notBlank(objectMgr.chatMgr.linkPreviewData[controller.chatId])
              ? ChatLinkPreview(
                  // key: const ValueKey('chat_link_preview'),
                  key: const ValueKey('same_key'),
                  metadata:
                      objectMgr.chatMgr.linkPreviewData[controller.chatId]!,
                  controller: controller,
                )
              : notBlank(objectMgr.chatMgr.replyMessageMap[controller.chatId])
                  ? ChatReplyView(
                      // key: const ValueKey('chat_reply_view'),
                      key: const ValueKey('same_key'),
                      chat: controller.chatController.chat,
                      controller: controller,
                    )
                  : notBlank(
                          objectMgr.chatMgr.editMessageMap[controller.chatId])
                      ? ChatEditView(
                          // key: const ValueKey('chat_edit_view'),
                          key: const ValueKey('same_key'),
                          chat: controller.chatController.chat,
                          controller: controller,
                        )
                      : const SizedBox(key: ValueKey('input_sized_box')),
        ),

        ///2.中間，翻譯框
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

        ///1.最底部，聊天框
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
    return TextInputFieldFactory.createComponent(
      tag: tags,
      isShowAttachment: isShowAttachment,
      isShowSticker: isShowSticker,
      isTextingAllowed: isTextingAllowed,
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
          tag: tags,
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
    controller.chatController.fetchRecentAssets();
    controller.chatController.showFaceView.value = false;

    if (controller.inputFocusNode.hasFocus) {
      controller.inputState = 1;
    } else {
      controller.inputState = 2;
    }

    try {
      bool status = await controller.onPrepareMediaPicker();
      controller.inputFocusNode.unfocus();
      showBottomPopup(status);
    } on StateError catch (_) {
      showBottomPopup(false);
    }
  }

  void showBottomPopup(bool permissionStatus) {
    showModalBottomSheet(
      context: Get.context!,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return MediaSelectorView(tags, permissionStatus);
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

  onOtherClick() {
    return null;
  }
}
