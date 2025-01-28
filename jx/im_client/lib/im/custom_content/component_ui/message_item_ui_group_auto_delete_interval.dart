import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_auto_delete_interval.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupAutoDeleteInterval extends MessageItemUIComponent {
  const MessageItemUIGroupAutoDeleteInterval(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return GroupAutoDeleteInterval(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      messageInterval: message.decodeContent(cl: MessageInterval.creator),
      message: message,
      chat: controller.chatController.chat,
      isPrevious: isPrevious,
      index: index,
    );
  }
}
