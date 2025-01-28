import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_favourite_me.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_favourite_sender.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIFavourite extends MessageItemUIComponent {
  const MessageItemUIFavourite(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageFavourite messageFavourite =
        message.decodeContent(cl: MessageFavourite.creator);
    return isMeBubble
        ? GroupFavouriteMe(
            controller: controller,
            message: message,
            messageFavourite: messageFavourite,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupFavouriteSender(
            controller: controller,
            message: message,
            messageFavourite: messageFavourite,
            index: index,
            chat: controller.chatController.chat,
            isPrevious: isPrevious,
          );
  }
}
