import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/transfer_money/transfer_money_me.dart';
import 'package:jxim_client/im/custom_content/transfer_money/transfer_money_sender.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/format_time.dart';

class MessageItemUITransferMoney extends MessageItemUIComponent {
  const MessageItemUITransferMoney(
      {super.key,
      required super.message,
      super.index = 0,
      super.isPrevious,
      super.isPinOpen,
      super.tag = ''});

  @override
  Widget buildChild(BuildContext context) {
    bool isMeBubble = objectMgr.userMgr.isMe(message.send_id);

    /// 成员名片
    final content = jsonDecode(message.content);
    final data = MessageTransferMoney()..applyJson(content);
    final createTime = FormatTime.chartTime(message.create_time, false);
    return isMeBubble
        ? TransferMoneyMe(
            message: message,
            chat: controller.chatController.chat,
            index: index,
            amount: data.amount,
            currency: data.currency,
            remark: data.remark,
            createTime: createTime,
          )
        : TransferMoneySender(
            message: message,
            chat: controller.chatController.chat,
            index: index,
            amount: data.amount,
            currency: data.currency,
            remark: data.remark,
            createTime: createTime,
          );
  }
}
