import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_friedn_link_me.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_friend_link_sender.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIFriendLink extends MessageItemUIComponent {
  const MessageItemUIFriendLink(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageFriendLink messageFriendLink =
        message.decodeContent(cl: MessageFriendLink.creator);

    /// 成员名片
    return isMeBubble
        ? ChatFriendLinkMe(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageFriendLink: messageFriendLink,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : ChatFriendLinkSender(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageFriendLink: messageFriendLink,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
