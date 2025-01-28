import 'package:flutter/cupertino.dart';
import 'package:im/widget/message/im_message_20004.dart';
import '../message_widget/message_widget_mixin.dart';
import 'message_item_ui_component.dart';

class MessageItemUITypeBetOpening extends MessageItemUIComponent {
  MessageItemUITypeBetOpening(
      {super.key,
      required super.message,
      required super.index,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    String content = message.content;
    bool isFirstMsg = firstMessageShowFunc(controller.chatController, message);
    bool isLastMsg = lastMessageShowFunc(controller.chatController, message);
    return IMMessage20004(
      content: content,
      createTime: message.send_time,
      isFirstMsg: isFirstMsg,
      isLastMsg: isLastMsg,
      onCancelFocus: controller.chatController.onCancelFocus,
    );
  }
}
