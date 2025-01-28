import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TransferMoneyBubble extends StatelessWidget {
  final BubbleType bubbleType;
  final String amount;
  final String currency;
  final String remark;
  final String createTime;
  final Message message;
  final Chat chat;
  final bool isSender;
  final bool isPressed;

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
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: CustomPaint(
        painter: ChatBubblePainter(
          bubbleType,
          position: BubblePosition.isFirstAndLastMessage,
          isPressed: isPressed,
          // bgColor: ImColor.white,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: objectMgr.loginMgr.isDesktop ? 180 : 235.w,
                      maxWidth: objectMgr.loginMgr.isDesktop ? 180 : 235.w,
                    ),
                    // width: objectMgr.loginMgr.isDesktop ? 133 : 235.w,
                    padding: EdgeInsets.symmetric(
                      vertical: objectMgr.loginMgr.isDesktop ? 12.5 : 12.5.w,
                      horizontal: objectMgr.loginMgr.isDesktop ? 16 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        isPressed ? colorTextPlaceholder : Colors.transparent,
                        im.ImColor.primaryYellow,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'packages/im_common/assets/svg/icon_currency_exchange.svg',
                          width: objectMgr.loginMgr.isDesktop ? 32 : 40.w,
                          height: objectMgr.loginMgr.isDesktop ? 32 : 40.w,
                          color: im.ImColor.white,
                        ),
                        im.ImGap.hGap12,
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$amount $currency',
                                style: jxTextStyle.headerText(
                                  fontWeight: MFontWeight.bold5.value,
                                  color: colorBrightPrimary,
                                ),
                              ),
                              im.ImGap.vGap(2),
                              Text(
                                remark,
                                maxLines:
                                    objectMgr.loginMgr.isDesktop ? 1 : null,
                                overflow: objectMgr.loginMgr.isDesktop
                                    ? TextOverflow.ellipsis
                                    : null,
                                style: jxTextStyle.supportText(
                                  color: const Color(0xFFF4D8B7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: objectMgr.loginMgr.isDesktop ? 10 : 8.w,
                    horizontal: objectMgr.loginMgr.isDesktop ? 15 : 12.w,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        localized(chatTransferMoney),
                        style: jxTextStyle.headerText(),
                      ),
                      // MessageCreateTime(createTime: createTime),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: objectMgr.loginMgr.isDesktop
                  ? isSender
                      ? 10
                      : 7
                  : 8.w,
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
