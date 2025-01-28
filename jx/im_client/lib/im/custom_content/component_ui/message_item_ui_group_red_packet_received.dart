import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_red_packet_received_item.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupRedPacketReceived extends MessageItemUIComponent {
  const MessageItemUIGroupRedPacketReceived(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return GroupRedPacketReceivedItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      message: message,
      messageRed: message.decodeContent(cl: MessageRed.creator),
      chat: controller.chatController.chat,
      index: index,
      isPrevious: isPrevious,
    );
  }
}
