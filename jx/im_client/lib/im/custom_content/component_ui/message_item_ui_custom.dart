import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/custom_system_item.dart';

class MessageItemUICustom extends MessageItemUIComponent {
  const MessageItemUICustom({
    super.key,
    required super.message,
    required super.index,
    super.isPrevious,
    super.isPinOpen,
    required super.tag,
  });

  @override
  Widget buildChild(BuildContext context) {
    return CustomSystemItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      message: message,
    );
  }
}
