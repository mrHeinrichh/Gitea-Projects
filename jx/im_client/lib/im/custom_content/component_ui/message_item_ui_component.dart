import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_base.dart';
import 'package:jxim_client/im/custom_content/message_widget/translation_ai_system_msg.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIComponent extends MessageItemUIBase<ChatContentController> {
  const MessageItemUIComponent(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious = true,
      super.isPinOpen = false,
      required super.tag});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () => controller.chatController.showFaceView.value = false,
            onHorizontalDragStart: objectMgr.loginMgr.isDesktop
                ? null
                : controller.onMessageHorizontalDragStart,
            onHorizontalDragDown: objectMgr.loginMgr.isDesktop
                ? null
                : controller.onMessageHorizontalDragDown,
            onHorizontalDragUpdate: objectMgr.loginMgr.isDesktop
                ? null
                : (details) {
                    if (!controller.chatController.chooseMore.value) {
                      controller.onMessageHorizontalDragUpdate(
                          details, message);
                    }
                  },
            onHorizontalDragEnd: objectMgr.loginMgr.isDesktop
                ? null
                : (details) {
                    if (!controller.chatController.chooseMore.value) {
                      controller.onMessageHorizontalDragEnd(details, message);
                    }
                  },
            onHorizontalDragCancel: objectMgr.loginMgr.isDesktop
                ? null
                : controller.onMessageHorizontalDragCancel,
            // remove offset effect
            child: Obx(() {
              final dragValue = controller.dragDiff.value;
              return Transform.translate(
                offset: Offset(
                  controller.dragMsgId == message.send_time &&
                          message.typ != messageTypeDate
                      ? dragValue
                      : 0.0,
                  0.0,
                ),
                child: buildChild(context),
              );
            })),
        TranslationAISystemMsg(
          chat: controller.chatController.chat,
          message: message,
        ),
      ],
    );
  }

  @override
  Widget buildChild(BuildContext context) {
    return const SizedBox();
  }
}
