import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_text_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_text_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupText extends MessageItemUIComponent {
  const MessageItemUIGroupText(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageText messageText = message.decodeContent(cl: MessageText.creator);
    return (isSaveChat ? messageText.forward_user_id == 0 : isMeBubble)
        ? GroupTextMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            messageText: messageText,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupTextSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            messageText: messageText,
            index: index,
            isPrevious: isPrevious,
            isPinOpen: isPinOpen,
          );
  }
}
