import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/unread_bar.dart';

class MessageItemUIUnreadBar extends MessageItemUIComponent {
  const MessageItemUIUnreadBar(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return UnreadBar(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
    );
  }
}
