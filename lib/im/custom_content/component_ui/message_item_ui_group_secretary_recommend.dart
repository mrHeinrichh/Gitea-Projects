import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_secretary_recommend_item.dart';

class MessageItemUIGroupSecretaryRecommend extends MessageItemUIComponent {
  const MessageItemUIGroupSecretaryRecommend(
      {super.key,
      required super.message,
      super.index = 0,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return ChatSecretaryRecommendItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      chat: controller.chatController.chat,
      message: message,
      messageSecretary:
          message.decodeContent(cl: MessageSecretaryRecommend.creator),
    );
  }
}
