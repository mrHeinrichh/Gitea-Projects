import 'dart:io';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/main.dart';

import '../color.dart';

class MFontFamily {
  MFontFamily(this.value);

  final String value;

  // static MFontFamily dingPro = MFontFamily("DINPro");
  // static MFontFamily dingProMedium = MFontFamily("DINPro-Medium");
  // static MFontFamily dingProBold = MFontFamily("DINPro-Bold");
  TextStyle get style {
    return TextStyle(fontFamily: value);
  }
}

class MFontSize {
  MFontSize(this.value);

  final double value;

  static MFontSize size10 = Platform.isAndroid ? MFontSize(9) : MFontSize(10);
  static MFontSize size11 = Platform.isAndroid ? MFontSize(10) : MFontSize(11);
  static MFontSize size12 = Platform.isAndroid ? MFontSize(11) : MFontSize(12);
  static MFontSize size13 = Platform.isAndroid ? MFontSize(12) : MFontSize(13);
  static MFontSize size14 = Platform.isAndroid ? MFontSize(13) : MFontSize(14);
  static MFontSize size15 = Platform.isAndroid ? MFontSize(14) : MFontSize(15);
  static MFontSize size16 = Platform.isAndroid ? MFontSize(15) : MFontSize(16);
  static MFontSize size17 = Platform.isAndroid ? MFontSize(16) : MFontSize(17);
  static MFontSize size18 = Platform.isAndroid ? MFontSize(17) : MFontSize(18);
  static MFontSize size20 = Platform.isAndroid ? MFontSize(19) : MFontSize(20);
  static MFontSize size24 = Platform.isAndroid ? MFontSize(23) : MFontSize(24);
  static MFontSize size28 = Platform.isAndroid ? MFontSize(27) : MFontSize(28);

  TextStyle get style {
    return TextStyle(fontSize: value);
  }
}

class MFontWeight {
  MFontWeight(this.value);

  final FontWeight value;
  static MFontWeight bold3 = MFontWeight(FontWeight.w300);
  static MFontWeight bold4 = MFontWeight(FontWeight.w400);
  static MFontWeight bold5 =
      MFontWeight(Platform.isIOS ? FontWeight.w600 : FontWeight.w500);
  static MFontWeight bold6 = MFontWeight(FontWeight.w600);
  static MFontWeight bold7 = MFontWeight(FontWeight.w700);

  TextStyle get style {
    return TextStyle(fontWeight: value);
  }
}

final jxTextStyle = MTextStyle();

class MTextStyle extends TextStyle {
  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  final textHeight = 1.3;

  TextStyle appTitleStyle({Color color = JXColors.primaryTextBlack}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
    );

    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatConnectingStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: MFontWeight.bold5.value,
      color: JXColors.primaryTextBlack,
      decoration: TextDecoration.none,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle announcementTitleStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: Colors.white,
      fontWeight: MFontWeight.bold5.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle announcementSuffixStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: Colors.white,
      fontWeight: MFontWeight.bold5.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle slidableTextStyle({Color? color}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: Colors.white,
    );
    final desktopTextStyle = TextStyle(
      fontSize: MFontSize.size13.value,
      color: color ?? Colors.black,
      fontWeight: MFontWeight.bold4.value,
      letterSpacing: 0.15,
    );
    return jxTextStyle
        .defaultStyle()
        .merge(isDesktop ? desktopTextStyle : textStyle);
  }

  TextStyle secretaryChatTitleStyle({Color? color}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      height: 1.1,
      fontWeight: MFontWeight.bold6.value,
      color: color,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle systemSmallStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: JXColors.primaryTextBlack,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatCellSpecialContentStyle({Color? color}) {
    final textStyle = TextStyle(
      fontSize: isDesktop ? MFontSize.size13.value : MFontSize.size14.value,
      fontWeight: MFontWeight.bold3.value,
      height: 1.0,
      fontFamilyFallback: MFontFamilies,
      color: color ?? JXColors.primaryTextBlack,
      decoration: TextDecoration.none,
      letterSpacing: isDesktop ? 0.25 : 0.15,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatCellContentStyle({Color? color}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: MFontWeight.bold4.value,
      height: textHeight,
      color: color ?? JXColors.secondaryTextBlackSolid,
      decoration: TextDecoration.none,
      overflow: TextOverflow.ellipsis,
    ).useSystemChineseFont();
    return textStyle;
  }

  TextStyle normalBubbleText(Color color,
      {TextDecoration decoration = TextDecoration.none}) {
    final textStyle = TextStyle(
        fontSize: isDesktop ? MFontSize.size13.value : MFontSize.size17.value,
        fontWeight: MFontWeight.bold4.value,
        color: color,
        decoration: decoration,
        height: textHeight,
        letterSpacing: isDesktop ? 0.25 : null);
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle replyBubbleTextStyle({bool isSender = false}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      color: isSender
          ? JXColors.chatBubbleSenderTextColor
          : JXColors.chatBubbleMeTextColor,
      height: textHeight,
    );
  }

  TextStyle replyBubbleLinkTextStyle({bool isSender = false}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      color: isSender
        ? JXColors.chatBubbleSenderHyperLink
        : JXColors.chatBubbleMeHyperLink,
      decoration: TextDecoration.underline,
      height: textHeight,
    );
  }

  TextStyle forwardBubbleTitleText({Color? color}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: color ?? accentColor,
      decoration: TextDecoration.none,
      height: 1.2,
    );

    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatReadNumText(Color color) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: color,
      fontWeight: MFontWeight.bold4.value,
      decoration: TextDecoration.none,
      height: 16.8 / 12,
    );

    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatReadBarText() {
    final textStyle = TextStyle(
      fontSize: isDesktop ? MFontSize.size11.value : MFontSize.size14.value,
      color: JXColors.primaryTextBlack,
      decoration: TextDecoration.none,
    );

    return textStyle;
  }

  TextStyle contactCardSubtitle([Color color = JXColors.secondaryTextBlack]) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: color,
      fontWeight: MFontWeight.bold4.value,
      height: textHeight,
      letterSpacing: 0.2,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle alertDialogContent() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: Colors.black,
      decoration: TextDecoration.none,
    );
    return jxTextStyle.defaultStyle().merge(
          textStyle,
        );
  }

  TextStyle alertDialogContentBold() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: accentColor,
      fontWeight: MFontWeight.bold6.value,
      decoration: TextDecoration.none,
    );

    return jxTextStyle.defaultStyle().merge(
          textStyle,
        );
  }

  TextStyle bottomSheetTitle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: Colors.black,
      fontWeight: MFontWeight.bold5.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle bottomSheetButton({Color? color}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: color ?? accentColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle searchBarHintStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: primaryIconColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle friendRequestTitleStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: accentColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle friendRequestCountStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size10.value,
      color: Colors.white,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle settingItemTitleStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: MFontWeight.bold5.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle profileSettingTextStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: Colors.indigo,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle profileInfoTextStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: Colors.indigo,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle errorFieldStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: Colors.red,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle validFieldStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: Colors.green,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle modalBottomSheetButtonStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: accentColor,
      fontWeight: MFontWeight.bold4.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle systemColorNormalStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size14.value,
      color: systemColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle textFieldTitleStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size15.value,
      color: systemColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle textFieldTextStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle largerTextFieldTextStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size18.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle defaultStyle() {
    return TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: MFontWeight.bold4.value,
      color: color000000,
    );
  }

  TextStyle dropAreaTitle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size18.value,
      color: Colors.grey,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle dropAreaSubTitle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size13.value,
      color: Colors.grey,
      letterSpacing: 0.5,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle imagePopupTitle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: Colors.black,
      letterSpacing: 0.5,
      fontWeight: MFontWeight.bold5.value,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle imagePopupTextField({Color color = Colors.grey}) {
    final textStyle = TextStyle(
      fontSize: MFontSize.size12.value,
      color: color,
      letterSpacing: 0.5,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatBlackTextStyle() {
    return isDesktop
        ? TextStyle(
            color: color666666,
            fontSize: 14,
            height: textHeight,
          )
        : TextStyle(
            color: color666666,
            fontSize: 10,
            height: textHeight,
          );
  }

  TextStyle textStyleSingleChatLastTime(
      {Color color = JXColors.primaryTextBlack}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
    );
  }

  TextStyle textStyleGroupMemberCount(
      {Color color = JXColors.primaryTextBlack}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
      height: 1,
    );
  }

  TextStyle textStyleTitle({Color color = JXColors.primaryTextBlack}) {
    return TextStyle(
      fontSize: isDesktop ? MFontSize.size12.value : MFontSize.size14.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
    );
  }

  TextStyle textStyleSecretaryChatTitle(
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: fontWeight ?? MFontWeight.bold6.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textDialogContent({Color color = JXColors.primaryTextBlack}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold4.value,
      color: color,
      height: textHeight,
    );
  }

  /// 最新字体规范
  TextStyle textStyle10({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size10.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyleBold10({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size10.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyle12({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyleBold12({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle13({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size13.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle14({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyleBold14({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle15({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle16({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size16.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyleBold16({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size16.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle17({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyleBold17({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
      height: textHeight,
    );
  }

  TextStyle textStyle18({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size18.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyleBold18({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size18.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyle20({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size20.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyleBold20({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size20.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyle24({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size24.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyleBold24({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size24.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyle28({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size28.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  TextStyle textStyleBold28({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size28.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? JXColors.primaryTextBlack,
    );
  }

  double chatCellNameSize() {
    return isDesktop ? MFontSize.size14.value : MFontSize.size16.value;
  }

  double chatCellContentSize() {
    return MFontSize.size13.value;
  }

  double messageCellNameSize() {
    return MFontSize.size14.value;
  }

  double messageCellContentSize() {
    return MFontSize.size13.value;
  }

  double chatRecommendTextSize() {
    return MFontSize.size16.value;
  }

  double chatSourceTextSize() {
    return isDesktop ? MFontSize.size13.value : MFontSize.size12.value;
  }

  double groupJoinedItemText() {
    return MFontSize.size12.value;
  }

  double chatRecommendSenderTextSize() {
    return MFontSize.size16.value;
  }

  double chatRecommendSenderContactSize() {
    return MFontSize.size14.value;
  }

  double chatRecommendSenderButtonSize() {
    return MFontSize.size16.value;
  }

  TextStyle infoViewToolButtonText() {
    return TextStyle(
      fontSize: isDesktop ? MFontSize.size13.value : MFontSize.size11.value,
      fontWeight: MFontWeight.bold5.value,
      color: JXColors.primaryTextBlack,
    );
  }

  TextStyle infoViewTabText() {
    return TextStyle(
      color: accentColor,
      fontSize: MFontSize.size14.value,
    );
  }

  TextStyle infoViewAddMemberText(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).iconTheme.color,
      fontSize: MFontSize.size16.value,
    );
  }
}

String fontFamily_plusjakartasans = "plusjakartasans";
String fontFamily_caveat = "Caveat";
String fontFamily_pingfang = "pingfang";
String fontFamily_din = "DIN";

