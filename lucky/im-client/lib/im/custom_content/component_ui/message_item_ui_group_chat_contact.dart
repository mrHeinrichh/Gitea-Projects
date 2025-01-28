import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_contact_me.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_contact_sender.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupChatContact extends MessageItemUIComponent {
  MessageItemUIGroupChatContact(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageJoinGroup messageJoinGroup =
        message.decodeContent(cl: MessageJoinGroup.creator);

    /// 成员名片
    return (isSaveChat ? messageJoinGroup.forward_user_id == 0 : isMeBubble)
        ? ChatContactMe(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageJoinGroup: messageJoinGroup,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : ChatContactSender(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            messageJoinGroup: messageJoinGroup,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
