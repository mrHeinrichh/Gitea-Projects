import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_encrypted_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_encrypted_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class MessageItemUIGroupEncrypted extends MessageItemUIComponent {
  const MessageItemUIGroupEncrypted(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    // bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    // MessageText messageText = message.decodeContent(cl: MessageText.creator);
    return (isMeBubble)
        ? GroupEncryptedMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupEncryptedSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            index: index,
            isPrevious: isPrevious,
            isPinOpen: isPinOpen,
          );
  }
}
