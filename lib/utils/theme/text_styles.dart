import 'dart:io';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

const String appFontFamily = 'PingFang SC';

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
  static MFontSize size22 = Platform.isAndroid ? MFontSize(21) : MFontSize(22);
  static MFontSize size24 = Platform.isAndroid ? MFontSize(23) : MFontSize(24);
  static MFontSize size28 = Platform.isAndroid ? MFontSize(27) : MFontSize(28);
  static MFontSize size34 = Platform.isAndroid ? MFontSize(33) : MFontSize(34);

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

final double bubbleNicknameSize = MFontSize.size14.value;

class MTextStyle extends TextStyle {
  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  final textHeight = 1.3;

  TextStyle appTitleStyle({Color color = colorTextPrimary}) {
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
      color: colorTextPrimary,
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
      color: colorTextPrimary,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle chatCellContentStyle({Color? color, double? fontSize}) {
    final textStyle = TextStyle(
      fontSize: fontSize ?? MFontSize.size15.value,
      fontWeight: MFontWeight.bold4.value,
      height: textHeight,
      color: color ?? colorTextSecondarySolid,
      decoration: TextDecoration.none,
      overflow: TextOverflow.ellipsis,
    ).useSystemChineseFont();
    return textStyle;
  }

  TextStyle normalBubbleText(Color color) {
    return isDesktop
        ? normalSmallText(color: color).copyWith(letterSpacing: 0.25)
        : headerText(color: color);
  }

  TextStyle replyBubbleTextStyle() {
    return normalText(color: colorTextSecondary);
  }

  TextStyle replyBubbleLinkTextStyle({bool isSender = false}) {
    return normalText(color: isSender ? themeColor : bubblePrimary).copyWith(
      decoration: TextDecoration.underline,
    );
  }

  TextStyle forwardBubbleTitleText({Color? color}) {
    return normalText(color: color ?? themeColor);
  }

  TextStyle chatReadNumText(Color color) {
    return supportSmallText(color: color);
  }

  TextStyle chatReadBarText() {
    final textStyle = TextStyle(
      fontSize: isDesktop ? MFontSize.size11.value : MFontSize.size14.value,
      color: colorTextPrimary,
      decoration: TextDecoration.none,
    );

    return textStyle;
  }

  TextStyle contactCardSubtitle([Color color = colorTextSecondary]) {
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
      color: themeColor,
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
      color: color ?? themeColor,
    );
    return jxTextStyle.defaultStyle().merge(textStyle);
  }

  TextStyle friendRequestTitleStyle() {
    final textStyle = TextStyle(
      fontSize: MFontSize.size16.value,
      color: themeColor,
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
      color: themeColor,
      fontWeight: MFontWeight.bold4.value,
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
      color: colorTextPrimary,
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
            color: colorGrey,
            fontSize: 14,
            height: textHeight,
          )
        : TextStyle(
            color: colorGrey,
            fontSize: 10,
            height: textHeight,
          );
  }

  TextStyle textStyleSingleChatLastTime({Color color = colorTextPrimary}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
    );
  }

  TextStyle textStyleTitle({Color color = colorTextPrimary}) {
    return TextStyle(
      fontSize: isDesktop ? MFontSize.size12.value : MFontSize.size14.value,
      fontWeight: MFontWeight.bold5.value,
      color: color,
    );
  }

  TextStyle textStyleSecretaryChatTitle({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: fontWeight ?? MFontWeight.bold6.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textDialogContent({Color color = colorTextPrimary}) {
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
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyleBold10({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size10.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyle12({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold12({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size12.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle13({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size13.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold13({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size13.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle14({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold14({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size14.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle15({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold15({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size15.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle16({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size16.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold16({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size16.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle17({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyleBold17({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
      height: textHeight,
    );
  }

  TextStyle textStyle18({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size18.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyleBold18({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size18.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyle20({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size20.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyleBold20({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size20.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyle24({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size24.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyleBold24({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size24.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyle28({Color? color}) {
    return TextStyle(
      fontSize: MFontSize.size28.value,
      fontWeight: MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
    );
  }

  TextStyle textStyleBold28({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size28.value,
      fontWeight: fontWeight ?? MFontWeight.bold5.value,
      color: color ?? colorTextPrimary,
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
      color: colorTextPrimary,
    );
  }

  TextStyle infoViewTabText() {
    return TextStyle(
      color: themeColor,
      fontSize: MFontSize.size14.value,
    );
  }

  TextStyle infoViewAddMemberText(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).iconTheme.color,
      fontSize: MFontSize.size16.value,
    );
  }

  /// 大标题
  TextStyle titleLargeText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size34.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: colorTextPrimary,
      height: 1.2,
    );
  }

  TextStyle titleText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size28.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.21,
    );
  }

  TextStyle titleSmallText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size20.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.25,
    );
  }

  /// 标题
  TextStyle headerText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontFamily: appFontFamily,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.29,
      decoration: TextDecoration.none,
    );
  }

  TextStyle headerSmallText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size15.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.33,
    );
  }

  /// 内容
  TextStyle normalText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size14.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.36,
    );
  }

  TextStyle normalSmallText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size13.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.38,
    );
  }

  /// 辅助文字
  TextStyle supportText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size12.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.33,
    );
  }

  TextStyle supportSmallText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontSize: MFontSize.size11.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1,
    );
  }

  /// 提升行文字
  TextStyle tinyText({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: MFontSize.size10.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? colorTextPrimary,
      height: 1.2,
    );
  }

  TextStyle chatInfoSecondaryMenuTitleStyle({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: MFontSize.size17.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? Colors.black,
      fontFamily: "pingfang",
      height: 1.2,
    );
  }

  TextStyle chatInfoSecondaryMenuTipStyle({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: MFontSize.size13.value,
      fontWeight: fontWeight ?? MFontWeight.bold4.value,
      color: color ?? Colors.black,
      fontFamily: "pingfang",
      height: 1.2,
    );
  }
}
