import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class TransferMoneyBubble extends StatelessWidget {
  final BubbleType bubbleType;
  final String amount;
  final String currency;
  final String remark;
  final String createTime;
  final Message message;
  final Chat chat;
  final bool isSender;

  const TransferMoneyBubble({
    super.key,
    this.bubbleType = BubbleType.sendBubble,
    required this.amount,
    required this.currency,
    required this.remark,
    required this.createTime,
    required this.chat,
    required this.message,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: CustomPaint(
        painter: ChatBubblePainter(
          bubbleType,
          position: BubblePosition.isFirstAndLastMessage,
          // bgColor: ImColor.white,
        ),
        child: Stack(
          children: [
            Column(
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
                      topLeft: 14,
                      topRight: 14,
                    ),
                  ),
                  child: Row(
                    children: [
                      const ImSvgIcon(
                        icon: 'icon_currency_exchange',
                        size: 40,
                        color: ImColor.white,
                      ),
                      ImGap.hGap12,
                      Flexible(
                        child: Column(
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
                              color: const Color(0xFFF4D8B7),
                            ),
                          ],
                        ),
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
                        localized(chatTransferMoney),
                        fontSize: ImFontSize.large,
                      ),
                      // MessageCreateTime(createTime: createTime),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: objectMgr.loginMgr.isDesktop ? 5 : 8.w,
              bottom: objectMgr.loginMgr.isDesktop ? 5 : 5.w,
              child: ChatReadNumView(
                message: message,
                chat: chat,
                showPinned: false,
                sender: isSender,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
