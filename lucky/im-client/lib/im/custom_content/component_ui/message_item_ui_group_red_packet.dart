import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_red_packet_me_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_red_packet_sender_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupRedPacket extends MessageItemUIComponent {
  MessageItemUIGroupRedPacket(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    return isMeBubble
        ? GroupRedPacketMeItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            message: message,
            messageRed: message.decodeContent(cl: MessageRed.creator),
            chat: controller.chatController.chat,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupRedPacketSenderItem(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            message: message,
            messageRed: message.decodeContent(cl: MessageRed.creator),
            chat: controller.chatController.chat,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
