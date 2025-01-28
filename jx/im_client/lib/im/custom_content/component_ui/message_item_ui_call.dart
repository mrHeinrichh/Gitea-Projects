import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/views/message/chat/items/call_state_item.dart';

class MessageItemUICall extends MessageItemUIComponent {
  const MessageItemUICall(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return CallStateItem(
        key: ValueKey('chat_${message.create_time}_${message.id}'),
        chatContentController: controller,
        index: index,
        isPrevious: isPrevious,
        chat: controller.chatController.chat,
        message: message,
        messageCall:
            message.decodeContent(cl: MessageCall.creator, v: message.content));
  }
}
