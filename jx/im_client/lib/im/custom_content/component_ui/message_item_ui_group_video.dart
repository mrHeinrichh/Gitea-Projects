import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_video_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_video_sender_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupVideo extends MessageItemUIComponent {
  const MessageItemUIGroupVideo({
    super.key,
    required super.message,
    required super.index,
    super.isPinOpen,
    required super.tag,
  });

  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageVideo messageVideo = message.decodeContent(cl: MessageVideo.creator);
    return (isSaveChat ? messageVideo.forward_user_id == 0 : isMeBubble)
        ? GroupVideoMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            messageVideo: messageVideo,
            chat: controller.chatController.chat,
            message: message,
            index: index,
          )
        : GroupVideoSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            controller: controller,
            chat: controller.chatController.chat,
            message: message,
            messageVideo: messageVideo,
            index: index,
          );
  }
}
