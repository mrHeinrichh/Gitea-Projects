import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_video_attachment_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_video_attachment_sender_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupVideoAttachment extends MessageItemUIComponent {
  MessageItemUIGroupVideoAttachment(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageVideo messageVideo = message.decodeContent(cl: MessageVideo.creator);
    return (isSaveChat ? messageVideo.forward_user_id == 0 : isMeBubble)
        ? GroupVideoAttachmentMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageVideo: messageVideo,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupVideoAttachmentSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            index: index,
            chat: controller.chatController.chat,
            message: message,
            messageVideo: messageVideo,
            isPrevious: isPrevious,
          );
  }
}
