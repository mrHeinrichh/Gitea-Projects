import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_mini_app_share_sender_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_mini_app_share_me_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupMiniAppShare extends MessageItemUIComponent {
  const MessageItemUIGroupMiniAppShare(
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
    MessageMiniAppShare messageText = message.decodeContent(cl: MessageMiniAppShare.creator);
    return (isSaveChat ? messageText.forward_user_id == 0 : isMeBubble)
        ? GroupMiniAppShareMeItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      controller: controller,
      message: message,
      messageText: messageText,
      index: index,
      isPrevious: isPrevious,
    )
        : GroupMiniAppShareSenderItem(
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
