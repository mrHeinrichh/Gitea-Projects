import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/utils/im_toast/im_border_radius.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class RedPacketMessageBubble extends StatelessWidget {
  final BubbleType bubbleType;
  final RedPacketType rpType;
  final int redPacketStatus;
  final String redPacketRemark;

  const RedPacketMessageBubble({
    super.key,
    required this.bubbleType,
    required this.rpType,
    required this.redPacketStatus,
    required this.redPacketRemark,
  });

  String getRedPacketTxtByType(RedPacketType rpType) {
    return switch (rpType) {
      RedPacketType.normalRedPacket => localized(normalRedPacket),
      RedPacketType.luckyRedPacket => localized(luckyRedPacket),
      RedPacketType.exclusiveRedPacket => localized(exclusiveRedPacket),
      RedPacketType.none => 'Unknown Type RedPacket',
    };
  }

  String getRedPacketClaimTxtByStatus(int redPacketStatus) {
    return switch (redPacketStatus) {
      rpYetReceive => localized(redPacketUnClaim),
      rpReceived => localized(redPacketClaimed),
      rpNotInExclusive => localized(NotInTheExclusiveRedPacket),
      rpFullyClaimed => localized(TheRedPacketHasBeenClaimed),
      rpExpired => localized(redPacketExpired),
      _ => 'Unknown Status RedPacket',
    };
  }

  @override
  Widget build(BuildContext context) {
    final claimStatus = getRedPacketClaimTxtByStatus(redPacketStatus);
    final redPacketValue = getRedPacketTxtByType(rpType);
    final isClaimed =
        redPacketStatus != rpYetReceive && redPacketStatus != rpUnknownError;

    return IntrinsicWidth(
      child: CustomPaint(
        painter: ChatBubblePainter(
          bubbleType,
          position: BubblePosition.isFirstAndLastMessage,
          // bgColor: ImColor.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: BubbleType.sendBubble == bubbleType &&
                      redPacketValue.length >= 18
                  ? 260.w
                  : 237.w,
              padding: const EdgeInsets.symmetric(
                vertical: 12.5,
                horizontal: 12,
              ).w,
              decoration: BoxDecoration(
                color: const Color(0xFFE49E4C),
                borderRadius: ImBorderRadius.only(
                  topLeft: 15,
                  topRight: 15,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    isClaimed
                        ? 'assets/svgs/wallet/red_packet_uncover.svg'
                        : 'assets/svgs/wallet/red_packet_cover.svg',
                    width: 44,
                    height: 44,
                  ),
                  SizedBox(width: 12.w),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          redPacketRemark,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: MFontWeight.bold6.value,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        SizedBox(height: 2.w),
                        Text(
                          claimStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: isClaimed
                                ? const Color(0xFFF4D8B7)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12).w,
              child: Text(
                redPacketValue,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'pingfang',
                  fontSize: 17,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
