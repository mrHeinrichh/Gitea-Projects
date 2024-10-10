import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_pin_message.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupPinMessage extends MessageItemUIComponent {
  const MessageItemUIGroupPinMessage(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return GroupPinMessage(
      message: message,
      messagePin: message.decodeContent(cl: MessagePin.creator),
      chat: controller.chatController.chat,
      isPrevious: isPrevious,
      index: index,
    );
  }
}
