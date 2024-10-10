import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/views/message/chat/items/chat_black_item.dart';

class MessageItemUIGroupChatBlack extends MessageItemUIComponent {
  const MessageItemUIGroupChatBlack(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return ChatBlackItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      msg: message.content,
      index: index,
    );
  }
}
