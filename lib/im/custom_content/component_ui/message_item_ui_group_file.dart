import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_file_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_file_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupFile extends MessageItemUIComponent {
  const MessageItemUIGroupFile(
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
    MessageFile messageFile = message.decodeContent(cl: MessageFile.creator);
    return (isSaveChat ? messageFile.forward_user_id == 0 : isMeBubble)
        ? GroupFileMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageFile: messageFile,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupFileSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            chat: controller.chatController.chat,
            message: message,
            messageFile: messageFile,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
