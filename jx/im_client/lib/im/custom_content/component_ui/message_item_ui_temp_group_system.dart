import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/temp_group_system_item.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUITempGroupSystem extends MessageItemUIComponent {
  const MessageItemUITempGroupSystem(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    return TempGroupSystemItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      message: message,
      messageTemp: message.decodeContent(cl: MessageTempGroupSystem.creator),
      chat: controller.chatController.chat,
      index: index,
      isPrevious: isPrevious,
    );
  }
}
