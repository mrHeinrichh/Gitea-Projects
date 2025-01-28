import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/custom_content/transfer_money/transfer_money_bubble.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';

class TransferMoneySender extends StatelessWidget {
  final String amount;
  final String currency;
  final String remark;
  final String createTime;

  const TransferMoneySender({
    required this.amount,
    required this.currency,
    required this.remark,
    required this.createTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.fromLTRB(12, 4, 39, 4).w,
      child: TransferMoneyBubble(
        bubbleType: BubbleType.receiverBubble,
        amount: amount,
        currency: currency,
        remark: remark,
        createTime: createTime,
      ),
    );
  }
}
