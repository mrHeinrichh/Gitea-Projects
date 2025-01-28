import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_content/transfer_money/message_create_time.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';

import '../../../utils/theme/text_styles.dart';

class TransferMoneyBubble extends StatelessWidget {
  final BubbleType bubbleType;
  final String amount;
  final String currency;
  final String remark;
  final String createTime;

  const TransferMoneyBubble({
    super.key,
    this.bubbleType = BubbleType.sendBubble,
    required this.amount,
    required this.currency,
    required this.remark,
    required this.createTime,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: CustomPaint(
        painter: ChatBubblePainter(
          bubbleType,
          position: BubblePosition.isFirstAndLastMessage,
          bgColor: ImColor.white,
        ),
        child: Column(
          children: [
            Container(
              width: 235.w,
              padding: const EdgeInsets.symmetric(
                vertical: 12.5,
                horizontal: 16,
              ).w,
              decoration: BoxDecoration(
                color: ImColor.primaryYellow,
                borderRadius: ImBorderRadius.only(
                  topLeft: 16,
                  topRight: 16,
                ),
              ),
              child: Row(
                children: [
                  ImSvgIcon(
                    icon: 'icon_currency_exchange',
                    size: 40,
                    color: ImColor.white,
                  ),
                  ImGap.hGap12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ImText(
                        '$amount $currency',
                        fontSize: 17,
                        fontWeight: MFontWeight.bold6.value,
                        color: ImColor.white,
                      ),
                      ImGap.vGap(2),
                      ImText(
                        remark,
                        fontSize: ImFontSize.small,
                        color: ImColor.white60,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ).w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   ImText(
                    '转账',
                    fontSize: ImFontSize.large,
                  ),
                  MessageCreateTime(createTime: createTime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
