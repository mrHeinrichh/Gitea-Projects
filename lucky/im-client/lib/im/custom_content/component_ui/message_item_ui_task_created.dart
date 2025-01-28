import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/task_me_bubble.dart';
import 'package:jxim_client/im/custom_content/message_widget/task_sender_bubble.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/task_content.dart';

class MessageItemUITaskCreated extends MessageItemUIComponent {
  MessageItemUITaskCreated(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);

    return isMeBubble
        ? TaskMeBubble(
            chat: controller.chatController.chat,
            message: message,
            messageTask: message.decodeContent(cl: TaskContent.creator),
            index: index,
          )
        : TaskSenderBubble(
            chat: controller.chatController.chat,
            message: message,
            messageTask: message.decodeContent(cl: TaskContent.creator),
            index: index,
          );
  }
}
