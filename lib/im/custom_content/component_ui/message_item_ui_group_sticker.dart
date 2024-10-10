import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_sticker_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_sticker_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupSticker extends MessageItemUIComponent {
  const MessageItemUIGroupSticker({
    super.key,
    required super.message,
    required super.index,
    super.isPrevious,
    super.isPinOpen,
    required super.tag,
  });

  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageImage messageImage = message.decodeContent(cl: MessageImage.creator);
    return (isSaveChat ? messageImage.forward_user_id == 0 : isMeBubble)
        ? GroupStickerMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageImage: messageImage,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupStickerSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageImage: messageImage,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
