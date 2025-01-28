import 'package:flutter/cupertino.dart';
import 'package:im/widget/message/im_message_20006.dart';
import '../message_widget/message_widget_mixin.dart';
import 'message_item_ui_component.dart';

class MessageItemUITypeBetClosed extends MessageItemUIComponent {
  MessageItemUITypeBetClosed(
      {super.key,
      required super.message,
      required super.index,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isFirstMsg = firstMessageShowFunc(controller.chatController, message);
    bool isLastMsg = lastMessageShowFunc(controller.chatController, message);
    return IMMessage20006(
      createTime: message.send_time,
      isFirstMsg: isFirstMsg,
      isLastMsg: isLastMsg,
      content: message.content,
      onCancelFocus: controller.chatController.onCancelFocus,
    );
  }
}
