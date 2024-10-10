import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/new_album_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/new_album_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupNewAlbum extends MessageItemUIComponent {
  const MessageItemUIGroupNewAlbum(
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
    NewMessageMedia messageMedia =
        message.decodeContent(cl: NewMessageMedia.creator);
    return (isSaveChat ? messageMedia.forward_user_id == 0 : isMeBubble)
        ? NewAlbumMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageMedia: messageMedia,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : NewAlbumSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageMedia: messageMedia,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
