import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_image_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_image_sender_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupImage extends MessageItemUIComponent {
  MessageItemUIGroupImage(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageImage messageImage = message.decodeContent(cl: MessageImage.creator);
    return (isSaveChat ? messageImage.forward_user_id == 0 : isMeBubble)
        ? GroupImageMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageImage: messageImage,
            controller: controller,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupImageSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            messageImage: messageImage,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
