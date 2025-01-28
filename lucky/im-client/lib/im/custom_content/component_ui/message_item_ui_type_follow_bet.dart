import 'package:flutter/cupertino.dart';
import 'package:im/widget/bet_status_sender_widget.dart';
import 'package:im/widget/lottery_bet_status_me_widget.dart';
import '../../../main.dart';
import '../../../utils/format_time.dart';
import '../../../views/component/custom_avatar.dart';
import '../message_widget/message_widget_mixin.dart';
import 'message_item_ui_component.dart';

class MessageItemUITypeFollowBet extends MessageItemUIComponent {
  MessageItemUITypeFollowBet(
      {super.key,
        required super.message,
        required super.index,
        required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);
    String content = message.content;
    bool isFirstMsg = firstMessageShowFunc(controller.chatController, message);
    bool isLastMsg = lastMessageShowFunc(controller.chatController, message);
    return !isMeBubble
        ? LotteryBetStatusSenderWidget(
      key: ValueKey('chat_${message.send_time}_${message.id}'),
      content: content,
      messageId: message.id,
      uid: message.send_id,
      avatar: CustomAvatar(
        uid: message.send_id,
        size: 38,
      ),
      createTime: FormatTime.chartTime(message.send_time~/1000, false),
      onCancelFocus: controller.chatController.onCancelFocus,
      isFirstMessage: isFirstMsg,
      isLastMessage: isLastMsg,
    )
        : LotteryBetStatusMeWidget(
      key: ValueKey('chat_${message.send_time}_${message.id}'),
      content: content,
      messageId: message.id,
      uid: message.send_id,
      createTime: FormatTime.chartTime(message.send_time~/1000, false),
      onCancelFocus: controller.chatController.onCancelFocus,
      isFirstMessage: isFirstMsg,
      isLastMessage: isLastMsg,
    );
  }
}
