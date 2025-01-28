import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_group_link_me.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_group_link_sender.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupLink extends MessageItemUIComponent {
  const MessageItemUIGroupLink(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageGroupLink messageGroupLink =
        message.decodeContent(cl: MessageGroupLink.creator);

    /// 成员名片
    return isMeBubble
        ? ChatGroupLinkMe(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageGroupLink: messageGroupLink,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : ChatGroupLinkSender(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageGroupLink: messageGroupLink,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
