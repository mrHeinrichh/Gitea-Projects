import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_link_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_link_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUILinkText extends MessageItemUIComponent {
  const MessageItemUILinkText({
    super.key,
    required super.message,
    required super.index,
    super.isPinOpen,
    required super.tag,
  });

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    final messageLink = message.decodeContent(cl: MessageLink.creator);
    return isMeBubble
        ? GroupLinkMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            messageLink: messageLink,
            index: index,
          )
        : GroupLinkSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            message: message,
            messageLink: messageLink,
            index: index,
          );
  }
}
