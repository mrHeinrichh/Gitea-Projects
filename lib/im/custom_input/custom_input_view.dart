import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/choose_more_field.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_view_component.dart';
import 'package:jxim_client/im/custom_input/searching_bottom_bar.dart';
import 'package:jxim_client/im/sticker/attachment_keyboard_component.dart';
import 'package:jxim_client/im/sticker/facial_expression_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CustomInputView extends CustomInputViewComponent {
  CustomInputView({super.key, required super.tag});

  @override
  Widget buildContent(CustomInputController controller, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: !controller.chatController.showFaceView.value &&
                    !controller.inputFocusNode.hasFocus &&
                    !controller.chatController.searchFocusNode.hasFocus &&
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
                      listIdx: controller.chatController.listIndex.value,
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
        buildMoreWidget(controller),
      ],
    );
  }

  @override
  Widget buildMoreWidget(CustomInputController controller) {
    if (objectMgr.loginMgr.isDesktop) return const SizedBox();
    return AnimatedContainer(
      color: colorBackground,
      duration: const Duration(milliseconds: 233),
      curve: Curves.easeOut,
      height: (controller.chatController.showFaceView.value ||
              controller.chatController.showAttachmentView.value)
          ? getPanelFixHeight
          : controller.inputFocusNode.hasFocus
              ? getKeyboardHeight
              : 0,
      child: Stack(
        children: [
          FacialExpressionComponent(
            isShowAttachment:
                controller.chatController.showAttachmentView.value,
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
            tag: tag,
            chat: controller.chatController.chat,
            isShowSticker: controller.chatController.showFaceView.value,
            isFocus: controller.inputFocusNode.hasFocus,
            isShowAttachment:
                controller.chatController.showAttachmentView.value,
            options: controller.chatController.attachmentOptions,
            onHideAttachmentView: () =>
                controller.chatController.showAttachmentView.value = false,
          ),
        ],
      ),
    );
  }

  @override
  onOtherClick() {
    return null;
  }
}
