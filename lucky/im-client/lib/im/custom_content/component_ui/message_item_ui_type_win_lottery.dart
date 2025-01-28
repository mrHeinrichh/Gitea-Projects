import 'package:flutter/material.dart';
import 'package:im/widget/win_lottery_widget.dart';

import '../../../utils/format_time.dart';
import '../message_widget/message_widget_mixin.dart';
import 'message_item_ui_component.dart';

class MessageItemUITypeWinLottery extends MessageItemUIComponent {
  MessageItemUITypeWinLottery(
      {super.key,
      required super.message,
      required super.index,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    String content = message.content;
    bool isFirstMsg = firstMessageShowFunc(controller.chatController, message);
    bool isLastMsg = lastMessageShowFunc(controller.chatController, message);
    return WinLotteryWidget(
      key: ValueKey('chat_${message.send_time}_${message.id}'),
      content: content,
      messageId: message.id,
      createTime: FormatTime.chartTime(message.send_time, false),
      isFirstMsg: isFirstMsg,
      isLastMsg: isLastMsg,
      onCancelFocus: controller.chatController.onCancelFocus,
    );
  }
}
