import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class RedPacketMessageBubble extends StatelessWidget {
  final BubbleType bubbleType;
  final RedPacketType rpType;
  final int redPacketStatus;
  final String redPacketRemark;
  final bool isPressed;

  const RedPacketMessageBubble({
    super.key,
    required this.bubbleType,
    required this.rpType,
    required this.redPacketStatus,
    required this.redPacketRemark,
    required this.isPressed,
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

    return Container(
      constraints: objectMgr.loginMgr.isDesktop
          ? const BoxConstraints(minWidth: 180, maxWidth: 180)
          : null,
      child: IntrinsicWidth(
          child: CustomPaint(
        painter: ChatBubblePainter(
          bubbleType,
          position: BubblePosition.isFirstAndLastMessage,
          isPressed: isPressed,
          // bgColor: ImColor.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: objectMgr.loginMgr.isDesktop ? 56 : null,
              width: objectMgr.loginMgr.isDesktop
                  ? null
                  : (BubbleType.sendBubble == bubbleType &&
                          redPacketValue.length >= 18
                      ? 260.w
                      : 237.w),
              padding: EdgeInsets.symmetric(
                vertical: objectMgr.loginMgr.isDesktop ? 0 : 12.5.w,
                horizontal: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
              ),
              decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    isPressed ? colorTextPlaceholder : Colors.transparent,
                    const Color(0xFFE49E4C),
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    isClaimed
                        ? 'assets/svgs/wallet/red_packet_uncover.svg'
                        : 'assets/svgs/wallet/red_packet_cover.svg',
                    width: objectMgr.loginMgr.isDesktop ? 32 : 44,
                    height: objectMgr.loginMgr.isDesktop ? 32 : 44,
                  ),
                  SizedBox(width: objectMgr.loginMgr.isDesktop ? 8 : 12.w),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          redPacketRemark,
                          style: TextStyle(
                            fontSize: MFontSize.size17.value,
                            fontWeight: MFontWeight.bold6.value,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        if (!objectMgr.loginMgr.isDesktop)
                          SizedBox(height: 2.w),
                        Text(
                          claimStatus,
                          style: TextStyle(
                            fontSize: MFontSize.size12.value,
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
            Container(
              height: objectMgr.loginMgr.isDesktop ? 35 : null,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(
                  vertical: objectMgr.loginMgr.isDesktop ? 0 : 8.w,
                  horizontal: objectMgr.loginMgr.isDesktop ? 12 : 12.w),
              margin: objectMgr.loginMgr.isDesktop
                  ? const EdgeInsets.only(bottom: 10)
                  : null,
              child: Text(
                redPacketValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'pingfang',
                  fontSize: MFontSize.size17.value,
                ),
              ),
            )
          ],
        ),
      )),
    );
  }
}
