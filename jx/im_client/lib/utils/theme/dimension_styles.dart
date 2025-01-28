import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';

final jxDimension = DimensionStyle();

class DimensionStyle {
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  final avatarFontSizeMap = {
    136.0: 68.0,
    100.0: 50.0,
    60.0: 28.0,
    40.0: 19.0,
    38.0: 18.0,
    30.0: 14.0,
    24.0: 11.0,
    22.0: 11.0,
  };

  double chatListAvatarSize() {
    return isDesktop ? 50.0 : 60.0;
  }

  double myFileMinWidth() {
    return ObjectMgr.screenMQ!.size.width * (isDesktop ? 0.15 : 0.35);
  }

  double senderFileMaxWidth({bool isMoreChoose = false}) {
    if (isDesktop) {
      return ObjectMgr.screenMQ!.size.width * 0.45;
    } else {
      return ObjectMgr.screenMQ!.size.width - (isMoreChoose ? 98 : 66);
    }
  }

  double meFileMaxWidth() {
    if (isDesktop) {
      return ObjectMgr.screenMQ!.size.width * 0.45;
    } else {
      return ObjectMgr.screenMQ!.size.width - 66;
    }
  }

  double senderImageWidth(double width) {
    return width;
  }

  double senderImageHeight(double height) {
    return height;
  }

  double getDesktopSize() {
    // double width = clampDouble((ObjectMgr.screenMQ!.size.width - 320) * 0.3, 250, 500);
    if (((ObjectMgr.screenMQ!.size.width - 320) * 0.3) > 250 &&
        ((ObjectMgr.screenMQ!.size.width - 320) * 0.3) < 500) {
      return (ObjectMgr.screenMQ!.size.width - 320) * 0.3;
    } else if (((ObjectMgr.screenMQ!.size.width - 320) * 0.3) > 500) {
      return 500;
    }
    return 250;
  }

  double chatCellPadding() {
    return isDesktop
        ? 80
        : jxDimension.chatListAvatarSize() +
            12 +
            jxDimension.messageCellPadding().left;
  }

  EdgeInsets chatCellHeadPadding() {
    return EdgeInsets.only(
      right: isDesktop ? 12 : 12.w,
    );
  }

  EdgeInsets chatCellTitlePadding() {
    return EdgeInsets.only(
      right: isDesktop ? 20 : 20.w,
    );
  }

  double chatCellPinImageSize() {
    return isDesktop ? 8 : 8.w;
  }

  double chatCellMuteImageSize() {
    return isDesktop ? 12 : 12.w;
  }

  double chatCellBadgeSize() {
    return isDesktop ? 8 : 8.w;
  }

  EdgeInsets chatCellBadgeMargin() {
    return EdgeInsets.only(
      right: isDesktop ? 4 : 4.w,
      top: isDesktop ? 4 : 4.w,
    );
  }

  BorderRadius chatCellBadgeRadius() {
    return BorderRadius.circular(
      isDesktop ? 5 : 5.w,
    );
  }

  EdgeInsets chatCellContentPadding() {
    return EdgeInsets.only(
      right: isDesktop ? 20 : 20,
    );
  }

  double contactCardAvatarSize() {
    return isDesktop ? 31 : 40;
  }

  double chatRoomAvatarSize() {
    return 36;
  }

  double emojiAvatarLeft() {
    return 40.w;
  }

  double emojiLeft() {
    return 6.w;
  }

  double emojiRight() {
    return 6.w;
  }

  EdgeInsets messageCellPadding() {
    return const EdgeInsets.symmetric(
      horizontal: 10,
    );
  }

  EdgeInsets messageCellContentPadding() {
    return EdgeInsets.symmetric(
      horizontal: isDesktop ? 10 : 0.w,
    );
  }

  EdgeInsets messageCellMargin() {
    return EdgeInsets.symmetric(
      horizontal: isDesktop ? 0 : 8,
      vertical: isDesktop ? 0 : 0.w,
    );
  }

  EdgeInsets messageCellDividerPadding() {
    return EdgeInsets.only(
      left: isDesktop ? 80 : 80.w,
    );
  }

  double messageCellAvatarSize() {
    return isDesktop ? 52 : 52.w;
  }

  EdgeInsets messageCellAvatarPadding() {
    return EdgeInsets.only(
      right: isDesktop ? 12 : 12.w,
    );
  }

  double chatSendStateImageSize() {
    return isDesktop ? 20 : 20.w;
  }

  double chatRecommendSenderAvatar() {
    return isDesktop ? 32 : 32.w;
  }

  EdgeInsets chatRecommendSenderOffstagePadding() {
    return isDesktop
        ? const EdgeInsets.only(bottom: 4)
        : EdgeInsets.only(bottom: 4.w);
  }

  PlaceholderAlignment pinMessageAlignment() {
    return isDesktop
        ? PlaceholderAlignment.middle
        : PlaceholderAlignment.middle;
  }

  double recordSenderAvatarSize() {
    return isDesktop ? 32 : 32.w;
  }

  EdgeInsets recordSenderAvatarPadding() {
    return isDesktop
        ? const EdgeInsets.only(right: 8)
        : EdgeInsets.only(right: 8.w);
  }

  EdgeInsets recordSenderContainerMargin(bool chooseMore) {
    return isDesktop
        ? EdgeInsets.only(
            left: chooseMore ? 40 : 18,
            right: 10.0,
            top: 2.0,
            bottom: 2.0,
          )
        : EdgeInsets.only(
            left: chooseMore ? 40.w : 18.w,
            right: 10.0,
          );
  }

  EdgeInsets systemMessagePadding() {
    return const EdgeInsets.only(top: 4, bottom: 5, left: 10, right: 10);
  }

  EdgeInsets systemMessageMargin(BuildContext context) {
    return const EdgeInsets.symmetric(vertical: 4, horizontal: 46);
  }

  double groupSystemItemNickname() {
    return isDesktop ? 12 : 12.w;
  }

//自己
  double groupTextMeMaxWidth() {
    return isDesktop
        ? ScreenUtil().screenWidth * 0.45
        : ObjectMgr.screenMQ!.size.width * (335 / 390);
  }

  double groupTextSenderReplySize() {
    return isDesktop ? 180.w : 100.w;
  }

  double showTranslationContentMinSize() {
    String b = objectMgr.langMgr.getLangKey().toUpperCase();
    bool isSystemEnglish = b.toUpperCase() == LanguageOption.english.value;
    if (isSystemEnglish) {
      return 150.w;
    }
    return 130.w;
  }

  /// 别人
  double groupTextSenderMaxWidth({
    bool isMoreChoose = false,
    bool hasAvatar = false,
  }) {
    /// figma bubble = 335, screen = 390
    ///sw : 335/390 = 0.859
    if (isDesktop) {
      return (ScreenUtil().screenWidth - 320) * 0.6;
    } else {
      return hasAvatar
          ? getReceiveHasAvatarWidth()
          : getReceiveHasAvatarWidth();
    }
  }

  BoxConstraints videoAttachmentMeConstraint() {
    return isDesktop
        ? BoxConstraints(
            minWidth: 150.w,
            maxWidth: ScreenUtil().screenWidth * 0.4,
          )
        : BoxConstraints(
            minWidth: 150.w,
            maxWidth: ScreenUtil().screenWidth * 0.8,
          );
  }

  EdgeInsets videoAttachmentMePadding() {
    return isDesktop
        ? const EdgeInsets.only(
            top: 8,
            right: 10,
            left: 10,
          )
        : EdgeInsets.only(
            top: 8.w,
            right: 10.w,
            left: 10.w,
          );
  }

  double videoAttachmentSenderAvatar() {
    return isDesktop ? 32 : 32.w;
  }

  EdgeInsets videoAttachmentSenderPadding(bool chooseMore) {
    return isDesktop
        ? EdgeInsets.only(
            left: chooseMore ? 40 : 18,
            top: 8,
            right: 10,
          )
        : EdgeInsets.only(
            left: chooseMore ? 40.w : 18.w,
            top: 8.w,
            right: 10.w,
          );
  }

  double videoAttachmentBorderRadius() {
    return isDesktop ? 8 : 8.w;
  }

  EdgeInsets videoAttachmentSenderAvatarPadding() {
    return isDesktop
        ? const EdgeInsets.only(
            right: 8,
            bottom: 10,
          )
        : EdgeInsets.only(
            right: 8.w,
            bottom: 10.w,
          );
  }

  double videoSenderAvatarSize() {
    return isDesktop ? 32 : 32.w;
  }

  double videoSenderHeight(Size size) {
    return isDesktop ? getDesktopSize() : size.height;
  }

  double videoSenderWidth(Size size) {
    return isDesktop ? getDesktopSize() : size.width;
  }

  BorderRadius textInputRadius() {
    return BorderRadius.circular(20);
  }

  EdgeInsets chatBlackPadding() {
    return isDesktop
        ? const EdgeInsets.fromLTRB(56, 16, 56, 0)
        : EdgeInsets.fromLTRB(56.w, 16.w, 56.w, 0);
  }

  EdgeInsets infoViewMemberTabPadding() {
    return isDesktop ? const EdgeInsets.all(8) : const EdgeInsets.all(8);
  }

  EdgeInsets infoViewTabBarPadding() {
    return isDesktop
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 0);
  }

  EdgeInsets infoViewGridPadding() {
    return isDesktop
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 0);
  }

  BoxConstraints constraintContainer() {
    return const BoxConstraints(
      maxWidth: 640,
      minWidth: 300,
    );
  }

  BorderRadius infoViewTabBarBorder() {
    return isDesktop
        ? const BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          )
        : BorderRadius.circular(0);
  }

  BorderRadius borderRadius4() {
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    );
  }

  BorderRadius topBottomLeft() {
    return const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    );
  }

  BorderRadius topBottomRight() {
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    );
  }

  BorderRadius topLeft() {
    return const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    );
  }

  BorderRadius bottomLeft() {
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    );
  }

  BorderRadius topRight() {
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    );
  }

  BorderRadius bottomRight() {
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    );
  }

  EdgeInsets chatTextFieldInputPadding() {
    return isDesktop
        ? const EdgeInsets.only(top: 18, bottom: 18, left: 12, right: 35)
        : const EdgeInsets.only(
            top: 12.0,
            bottom: 12.0,
            left: 10.0,
            right: 34.0,
          );
  }

  EdgeInsets emojiIconPadding() {
    return isDesktop
        ? const EdgeInsets.only(left: 10, right: 15)
        : const EdgeInsets.fromLTRB(6, 14, 8, 14);
  }

  EdgeInsets clipIconPadding() {
    return isDesktop
        ? const EdgeInsets.only(right: 10, left: 15)
        : const EdgeInsets.all(10.0);
  }

  BoxDecoration chatPopMenuDecoration() {
    return BoxDecoration(
      color: colorSurface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: isDesktop
          ? [
              const BoxShadow(
                color: Colors.grey,
                blurRadius: 5,
                offset: Offset(0.0, 1),
              ),
            ]
          : [],
    );
  }

  BoxDecoration emojiSelectorDecoration() {
    return BoxDecoration(
      color: colorBackground,
      borderRadius: BorderRadius.circular(100.w),
      boxShadow: isDesktop
          ? [
              const BoxShadow(
                color: Colors.grey,
                blurRadius: 5,
                offset: Offset(0.0, 1),
              ),
            ]
          : [],
    );
  }

  // 有头像，头像到屏幕边距（无尖角，边距4）
  double chatRoomSideMargin = objectMgr.loginMgr.isDesktop ? 16 : 4.w;

  // 有头像，头像跟气泡边距（尖角4 + 边距2）
  double chatRoomSideMarginAvaR = objectMgr.loginMgr.isDesktop ? 8 : 6.w;

  // 无头像，头像到屏幕边距（尖角4 + 边距8）
  double chatRoomSideMarginNoAva = objectMgr.loginMgr.isDesktop ? 20 : 12.w;

  // 无头像，头像到屏幕边距（边距8）
  double chatRoomSideMarginSingle = objectMgr.loginMgr.isDesktop ? 20 : 8.w;

  // 另外一边最大距离 48
  double chatRoomSideMarginMaxGap = objectMgr.loginMgr.isDesktop ? 48 : 20.w;

  double chatBubbleLeftMargin = objectMgr.loginMgr.isDesktop ? 8 : 8.w;

  double chatBubbleTopMargin(BubblePosition position) {
    if (position == BubblePosition.isFirstMessage ||
        position == BubblePosition.isFirstAndLastMessage) {
      return 4.w;
    }

    return 0.w;
  }

  double chatBubbleBottomMargin(BubblePosition position) {
    if (position == BubblePosition.isLastMessage ||
        position == BubblePosition.isFirstAndLastMessage) {
      return 2;
    }

    return 2;
  }

  ButtonStyle textInputButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      minimumSize: const Size(24, 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: Alignment.center,
    );
  }

  Border borderPrimaryColor() {
    return Border(
      bottom: BorderSide(
        color: colorTextPrimary.withOpacity(0.06),
        width: 0.75,
      ),
    );
  }
}
