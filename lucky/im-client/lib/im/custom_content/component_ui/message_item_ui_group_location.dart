import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_me.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_sender.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupLocation extends MessageItemUIComponent {
  MessageItemUIGroupLocation(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    bool isSaveChat = controller.chatController.chat.isSaveMsg;
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    MessageMyLocation messageLocation =
        message.decodeContent(cl: MessageMyLocation.creator);
    return (isSaveChat ? messageLocation.forward_user_id == 0 : isMeBubble)
        ? GroupLocationMe(
            messageLocation: messageLocation,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          )
        : GroupLocationSender(
            messageLocation: messageLocation,
            chat: controller.chatController.chat,
            message: message,
            index: index,
            isPrevious: isPrevious,
          );
  }
}
