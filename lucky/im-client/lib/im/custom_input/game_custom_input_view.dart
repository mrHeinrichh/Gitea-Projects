

import 'package:flutter/cupertino.dart';
import 'package:im/im_plugin.dart';

import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/searching_bottom_bar.dart';

import '../../main.dart';
import '../../object/chat/chat.dart';
import '../../utils/color.dart';
import '../sticker/attachment_keyboard_component.dart';
import '../sticker/facial_expression_component.dart';
import '../sticker/game_keyboard_component.dart';
import '../sticker/shorttalk_component.dart';
import 'choose_more_field.dart';
import 'custom_input_view_component.dart';

class GameCustomInputView extends CustomInputViewComponent {
  GameCustomInputView({super.key, required super.tag});

  @override
  Widget buildContent(CustomInputController controller, BuildContext context) {
  return SlideTransition(
    position: controller.offset,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 0.1, color: Color(0x33121212))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // duration: const Duration(milliseconds: 233),
            // curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: (!controller.chatController.showFaceView.value &&
                  !controller.inputFocusNode.hasFocus &&
                  !controller
                      .chatController.searchFocusNode.hasFocus &&
                  !controller.isShowShortTalk.value&&
                  !controller.isCurrentShowGamePanel.value
                  ? MediaQuery.of(context).viewPadding.bottom
                  : 0.0) + 0,
              top: 0.0,
            ),
            width: double.infinity,
            color: surfaceBrightColor,
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
                    controller.user.value?.deletedAt !=
                        0) ||
                ((objectMgr.userMgr.mainUser.email
                    .isEmpty &&
                    controller
                        .chatController.chat.typ ==
                        chatTypeSmallSecretary) ||
                    controller.chatController.chat.isSystem)
                ? buildDisallowChat(
              context,
              controller.chatController.chat,
            )
                : buildInputField(context),
          ),
          buildMoreWidget(controller),
        ],
      ),
    ),
  );
  }

  @override
  Widget buildMoreWidget(CustomInputController controller) {
    return  Stack(
      children: [
        FacialExpressionComponent(
          isShowAttachment:
          controller.chatController.showAttachmentView.value,
          chat: controller.chatController.chat,
          isShowSticker: controller.chatController.showFaceView.value,
          isShowStickerPermission: controller.chatController.showTextStickerEmoji,
          isFocus: controller.inputFocusNode.hasFocus,
          onDeleteLastOne: () {
            final originalText = controller.inputController.text;
            final newText = originalText.characters.skipLast(1).string;
            controller.inputController.text = newText;
          },
        ),
        //快捷短語
        controller.isShowGameKeyboard.value && controller.isNormalUser.value ?
        ShortTalkComponent(
          chat: controller.chatController.chat,
          isShowShortTalk: controller.isShowShortTalk.value,
          isFocus: controller.inputFocusNode.hasFocus,
        ) : const SizedBox(),

        GameKeyboardComponent(
          tag: tag,
          chat: controller.chatController.chat,
          isShowGameKeyboard: controller.isCurrentShowGamePanel.value,
          isShowSticker: controller.chatController.showFaceView.value,
          isShowShortTalk: controller.isShowShortTalk.value,
          isFocus: controller.inputFocusNode.hasFocus,
        ),
        // if (controller.chatController.isShowAttachmentView)
        AttachmentKeyboardComponent(
          tag: tag,
          chat: controller.chatController.chat,
          isShowGameKeyboard: controller.isCurrentShowGamePanel.value,
          isShowSticker: controller.chatController.showFaceView.value,
          isShowShortTalk: controller.isShowShortTalk.value,
          isFocus: controller.inputFocusNode.hasFocus,
          isShowAttachment:
          controller.chatController.showAttachmentView.value,
          options:
          controller.chatController.attachmentOptions ?? [],
          onHideAttachmentView: () => controller
              .chatController.showAttachmentView.value = false,
        ),
      ],
    );
  }

  @override
  onOtherClick() {
   return controller.isCurrentShowGamePanel.value
       ? () async {
     //關閉遊戲鍵盤
     gameManager.panelController(
         entrance: ImConstants.gameBetsOptionList, control: false);
     return false;
   } : controller.isShowShortTalk.value
       ? () async {
     controller.isShowShortTalk.value = false;
     return false;
   }
       : null;
  }

}