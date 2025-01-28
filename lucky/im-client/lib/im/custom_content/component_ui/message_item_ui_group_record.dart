import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_record_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_record_sender_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupRecord extends MessageItemUIComponent {
  MessageItemUIGroupRecord(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageVoice messageVoice = message.decodeContent(cl: MessageVoice.creator);
    return (isSaveChat ? messageVoice.forward_user_id == 0 : isMeBubble)
        ? GroupRecordMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageVoice: messageVoice,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupRecordSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            message: message,
            chat: controller.chatController.chat,
            messageVoice: messageVoice,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
