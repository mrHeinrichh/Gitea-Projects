import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/main.dart';

//w文本键盘颜色
const Brightness txtBrightness = Brightness.light;

//颜色
Color colorCCCCCC = hexColor(0xCCCCCC);
Color color000000 = hexColor(0x000000);
Color color1A1A1A = hexColor(0x1A1A1A);
Color color4C84F6 = hexColor(0x4C84F6);
Color color333333 = hexColor(0x333333);
Color color666666 = hexColor(0x666666);
Color color999999 = hexColor(0x999999);
Color colorB3B3B3 = hexColor(0xB3B3B3);
Color colorE5454D = hexColor(0xE5454D);
Color colorE6E6E6 = hexColor(0xE6E6E6);
Color colorED7D82 = hexColor(0xED7D82);
Color colorF2F2F2 = hexColor(0xF2F2F2);
Color colorF6F6F9 = hexColor(0xF6F6F9);
Color colorF7F7F7 = hexColor(0xF7F7F7);
Color colorFFFFFF = hexColor(0xFFFFFF);
Color colorFFD25B = hexColor(0xFFD25B);
Color colorFFE7BA = hexColor(0xFFE7BA);
Color colorD9D3FF = hexColor(0xD9D3FF);
Color colorCBC1FF = hexColor(0xCBC1FF);
Color colorA4A4D8 = hexColor(0xA4A4D8);
Color colorEFEFF0 = hexColor(0xEFEFF0);
Color colorF4F4FB = hexColor(0xF4F4FB);
Color colorFCFCFC = hexColor(0xFCFCFC);
Color colorFEFEFE = hexColor(0xFEFEE5);
Color colorFDFDFD = hexColor(0xFDFDFD);

final primaryColorBottom = hexColor(0xDCDDF5);
final primaryColor = hexColor(0xDCDDF5);
final secondaryColor = hexColor(0x8E7CFC);

final bubbleMeColor = hexColor(0xE1FFC7);
final inputHintTextColor = hexColor(0x121212);
final recordDeleteColor = hexColor(0xFFC0BD);

final primaryIconColor = hexColor(0x9FA3B8);

final offWhite = hexColor(0xFCFCFC);
final dividerColor = hexColor(0xE9E9EB);
final systemColor = hexColor(0x999999);
final captionColor = hexColor(0x50555C);
final iOSSystemColor = hexColor(0xF0F0F0);
final separatorColor = hexColor(0x3C3C43);
final primaryTextColor = hexColor(0x121212);
final chatBgPrimaryColor = hexColor(0xF5F0FF);
final chatBgSecondaryColor = hexColor(0xEBE8FF);
final readCheckedColor = hexColor(0x68FF50);
final emojiBorderColor = hexColor(0xAEAEAE);
final switchColor = hexColor(0x452BB3);
final progressColor = hexColor(0xC8CEEC);

/// latest color code
final backgroundColor = hexColor(0xF3F3F3);
final greyBackgroundColor = hexColor(0xEFEEF2);
final surfaceBrightColor = hexColor(0xF6F6F6);
final accentColor = hexColor(0xFF007AFF);
final linkColor = hexColor(0xFF1D49A7);
final sendColor = hexColor(0x5AC63A);
final errorColor = hexColor(0xE84D3D);
final successColor = hexColor(0x57C055);
final warningColor = hexColor(0xFF9500);
final greyColorB2 = hexColor(0xB2B2B2);
final qrCodeColor = hexColor(0x268EA4);

final redPacketLuckyColor = hexColor(0xE57519);
final redPacketExclusiveColor = hexColor(0xA68633);
final redPacketNormalColor = hexColor(0xB73229);
final sheetTitleBarColor = hexColor(0xFFF3F3F3);

class JXColors {
  JXColors._();

  static const Color desktopChatPurple = const Color(0xFFF7F4FC);
  static const Color pastelPurple = const Color(0xFFDCDDF5);
  static const Color lightPurple = const Color(0xFFC9C1F5);

  // static const Color accentPurple = const Color(0xFF7561E5);
  static const Color darkThemeLightPurple = const Color(0xFF8372DF);
  static const Color mutedLightPurple = const Color(0xFF9FA3B8);
  static const Color mutedDarkPurple = const Color(0xFF61678B);
  static const Color onBoardingLightPurple = const Color(0xFF9B61E5);
  static const Color inactiveAccentColor =
      const Color.fromRGBO(81, 40, 212, 0.2);
  static const Color onBoardingDarkPurple = const Color(0xFF1E00C9);

  static const Color indigo = const Color(0xFF243BB2);

  static const Color black = const Color(0xFF121212);
  static const Color black3 = const Color(0x08000000);
  static const Color black6 = const Color(0x0C000000);
  static const Color black8 = const Color(0x14121212);
  static const Color black20 = const Color(0x33000000);
  static const Color black32 = const Color(0x52121212);
  static const Color black24 = const Color(0x3D121212);
  static const Color black40 = const Color(0x66121212);
  static const Color black48 = const Color(0x7A121212);
  static const Color offBlack = const Color(0xFF262628);

  static const Color lightGrey = const Color(0xFFE9E9EB);
  static const Color darkGrey = const Color(0xFF999999);
  static const Color darkGreyBlue = const Color(0x1F767680);
  static const Color darkGrey2 = const Color(0xFF636366);
  static const Color grey8d = const Color(0xFF8D8D8D);

  static const Color white = const Color(0xFFFFFFFF);
  static const Color offWhite = const Color(0xFFFCFCFC);
  static const Color solidTextFieldBg = Color(0xFF2F2F2F);
  static const Color lightShade = const Color(0xFFFEFEFE);
  static const Color compassBg = const Color(0xFFF7F7F6);

  static const Color purple = Color(0xFF6D84FF);

  static const Color red = const Color(0xFFEB4B35);
  static const Color orange = const Color(0xFFE49E4C);
  static const Color yellow = const Color(0xFFFFBC0E);
  static const Color green = const Color(0xFF5AC63A);
  static const Color green32Solid = const Color(0xFFcaedc0);
  static const Color blue = const Color(0xFF007AFF);
  static const Color blue32Solid = const Color(0xFFadd4ff);
  static const Color lightGreen = const Color(0xFFADFF00);
  static const List<Color> purpleGradient = [lightPurple, pastelPurple];
  static const Color pink = const Color(0xFFF7D3E1);
  static const Color disabledIcon = const Color.fromRGBO(0, 0, 0, 0.36);
  static const Color blueE0 = const Color(0xFFE0EFFF);

  static const primaryTextBlack = const Color(0xFF121212); // 100% black
  static const secondaryTextBlack = const Color(0x7A121212); // 48% black
  static const supportingTextBlack = const Color(0x52121212); // 32% black
  static const outlineColor = const Color(0x14121212); // 8% black

  static const primaryTextWhite = const Color(0xFFFFFFFF); // 100% white
  static const secondaryTextWhite = const Color(0x99FFFFFF); // 60% white
  static const whiteColor90 = const Color(0xE6FEFEFE); // 90% white
  static const whiteColor20 = const Color(0x33FFFFFF); //20% white
  static const whiteColor10 = const Color(0x1AFFFFFF); //10% white
  static const brightOrange = const Color(0xFFE57519);
  static const seaBlue = const Color(0xFFE0FDFB);
  static const backgroundWhite = const Color(0xFFEFEEF2);
  static const mediaCover = const Color(0xFF363636);

  // Semantic Colors
  static Color bgPrimaryColor = backgroundColor; // 100%
  static const Color bgSecondaryColor = const Color(0xFFFFFFFF); // 100%
  static const Color bgTertiaryColor = const Color(0x0F121212); // 6%
  static const Color bgPinColor =
      const Color(0xFFf8f8f8); // 這裡需要用實色,看起來是121212的3％
  static const Color bgSearchBarTextField = const Color(0xFFE8E8E8); //100%
  static const Color bgSelectedChatEdit = const Color(0xFFEBF4FF); //100%

  static const Color hintColor = const Color(0x3D121212); //24%

  static const Color iconPrimaryColor = const Color(0x52121212); // 32%
  static const Color iconSecondaryColor = const Color(0x52121212); // 32%
  static const Color iconTertiaryColor = const Color(0x66121212); // 40%
  static const Color cIconPrimaryColor = const Color(0xFFFFFFFF); // 100%

  static const Color borderPrimaryColor = const Color(0x33121212); // 20%

  static const Color unreadBarBgColor = const Color(0x99FFFFFF);
  static const Color chatBubbleMeAccentColor = const Color(0xFF5AC63A);
  static const Color chatBubbleMeHighlightBgColor = const Color(0xFFCBDFB4);
  static const Color chatBubbleSenderHighlightBgColor = const Color(0xFFD9D9D9);

  static const Color chatBubbleMeReplyLabelColor = const Color(0xFF5AC63A);
  static const Color chatBubbleSenderReplyLabelColor = const Color(0xFA121212);

  static const Color chatBubbleMeReplyTitleColor = const Color(0xFF5AC63A);
  static const Color chatBubbleSenderReplyTitleColor = const Color(0xFA121212);
  static const Color chatBubbleSenderForwardLabelColor = const Color(0xFF007AFF);
  static const Color chatBubbleMeForwardLabelColor = const Color(0xFF5AC63A);

  static const Color chatBubbleMeBgColor = const Color(0xFFE1FFC7);
  static const Color chatBubbleSenderBgColor = const Color(0xFFFFFFFF);

  static const Color chatBubbleMeTextColor = const Color(0xFF121212);
  static const Color chatBubbleSenderTextColor = const Color(0xFF121212);

  static const Color chatBubbleMeHyperLink = const Color(0xFF5AC63A);
  static const Color chatBubbleSenderHyperLink = const Color(0xFF017BFF);

  static const Color chatBubbleMeReactBg = const Color(0xFF5AC63A);
  static const Color chatBubbleSenderReactBg = const Color(0xFF007AFF);

  static const Color bubbleMeReactText = const Color(0xFFFFFFFF);
  static const Color bubbleMeNoReactText = const Color(0x7A121212);
  static const Color bubbleSenderReactText = const Color(0xFFFFFFFF);
  static const Color bubbleSenderNoReactText = const Color(0x7A121212);

  static const Color chatBubbleMeReadColor = const Color(0xFF5AC63A);

  static const Color chatBubbleFileIconHolderColor = const Color(0x0F121212);
  static const Color chatBubbleFileMeBgColor = const Color(0xFF5AC63A);
  static const Color chatBubbleFileSenderBgColor = const Color(0xFF007AFF);
  static const Color chatBubbleFileMeIconColor = const Color(0xFFFFFFFF);
  static const Color chatBubbleFileSenderIconColor = const Color(0xFFFFFFFF);
  static const Color chatBubbleFileMeIconHolderColor = const Color(0x0F121212);
  static const Color chatBubbleFileLoadingColor = const Color(0xFFFFFFFF);

  static const Color chatBubbleFileMeTitle = const Color(0xFF5AC63A);
  static const Color chatBubbleFileSenderTitle = const Color(0xFF007AFF);

  static const Color chatBubbleFileMeSubTitle = const Color(0xFF5AC63A);
  static const Color chatBubbleFileSenderSubTitle = const Color(0x7A121212);

  static const Color chatBubbleVideoMeStatusBgColor = const Color(0x7A121212);
  static const Color chatBubbleVideoMeStatusTextColor = const Color(0xFFFFFFFF);

  static const Color chatBubblePinBg = const Color(0x52121212);
  static const Color chatBubblePinText = const Color(0xFFFFFFFF);
  static const Color chatBubbleMePinIcon = const Color(0x80FFFFFF);
  static const Color chatBubbleSenderPinIcon = const Color(0x7A121212);

  static const Color chatBubbleTimeBg = const Color(0x52121212);
  static const Color chatBubbleTimeText = const Color(0xFF5AC63A);

  static const Color chatBubbleMeRecordColor = const Color(0xFF5AC63A);
  static const Color chatBubbleSenderRecordColor = const Color(0xFF017BFF);

  static const Color chatBubbleMeRecordIconColor = const Color(0xFFFFFFFF);
  static const Color chatBubbleSenderRecordIconColor = const Color(0xFFFFFFFF);

  static const Color chatBubbleMeRecordSubTitleColor = const Color(0x7A121212);
  static const Color chatBubbleSenderRecordSubTitleColor =
      const Color(0x7A121212);

  static const Color chatBubbleMeRecordDrawColor = const Color(0xFF5AC63A);
  static const Color chatBubbleMeRecordDrawBGColor = const Color(0x995AC63A);
  static const Color chatBubbleSenderRecordDrawColor = const Color(0xFF017BFF);
  static const Color chatBubbleSenderRecordDrawBGColor =
      const Color(0x99017BFF);

  static const Color chatBubbleCallIconColor = const Color(0xFFFFFFFF);
  static const Color chatBubbleCallTextMeColor = const Color(0x66121212);
  static const Color chatBubbleCallTextSenderColor = const Color(0x66121212);
  static const Color chatBubbleCallIndicatorColor = const Color(0xFF5AC63A);

  static const Color chatBubbleContactMeBg = const Color(0xF121212);
  static const Color chatBubbleContactSenderBg = const Color(0xF121212);
  static const Color chatContactTitle = const Color(0xFF318330);

  static const Color chatPopBgColor = const Color(0xCCFFFFFF);
  static const Color chatEmojiPopBgColor = const Color(0xFFF3F3F3);
  static const Color toastButtonColor = const Color(0xFF82D2FF);

  static const Color desktopChatBgColor = const Color(0xFFE6E2DA);
  static const Color desktopChatBlue = const Color(0xFF4685BC);
  static const Color desktopDarkGrey = const Color(0xFFDDDDDD);

  static const Color mediaBarBg = const Color(0xE6121212);
  static const Color chatBubbleMeTranslateBgColor = const Color(0xF121212);
  static const Color chatBubbleSenderTranslateBgColor = const Color(0xF121212);
  static const Color secondaryTextBlackSolid = const Color(0xFF8A8A8A);
}

//主题
ThemeData themeData() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: primaryColor,
      iconTheme: const IconThemeData(color: Colors.black),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    // textTheme: _textTheme(false, FontWeight.normal,),
    dividerColor: dividerColor,
    iconTheme: IconThemeData(color: accentColor),
    backgroundColor: hexColor(0xFFFFFFFFF),
    primarySwatch: createMaterialColor(primaryColor),
    textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorED7D82.withOpacity(.5),
        selectionHandleColor: colorE5454D //安卓光标球颜色
        ),
    fontFamily: appFontfamily,
    unselectedWidgetColor: accentColor,
  );
}

ThemeData darkThemeData() {
  return ThemeData(
    // 主题颜色属于亮色系还是属于暗色系(eg:dark时,AppBarTitle文字及状态栏文字的颜色为白色,反之为黑色)
    // 这里设置为dark目的是,不管App是明or暗,都将appBar的字体颜色的默认值设为白色.
    // 再AnnotatedRegion<SystemUiOverlayStyle>的方式,调整响应的状态栏颜色
    brightness: Brightness.dark,
    backgroundColor: hexColor(0x040404),
    primarySwatch: createMaterialColor(Colors.black),
    scaffoldBackgroundColor:
        // Color(int.parse(objcetMgr.skinMgr.color('scaffoldBackground')))
        Colors.black,
    appBarTheme: const AppBarTheme(
      color: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    // textTheme: TextTheme(
    //   titleSmall: TextStyle(
    //     fontSize: 14,
    //     height: 1.1,
    //     color: Colors.white /*objcetMgr.skinMgr.color('titleFont')*/,
    //     fontWeight: FontWeight.normal,
    //   ),
    // ),
    textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorED7D82.withOpacity(.5),
        selectionHandleColor: colorE5454D //安卓光标球颜色
        ),
    fontFamily: appFontfamily,
  );
}

TextTheme _textTheme(bool isDark, FontWeight fontWeight) {
  final TextStyle baseStyle = TextStyle(
    fontFamily: appFontfamily,
    fontFamilyFallback: null,
    fontWeight: FontWeight.normal,
    height: fontHeight,
    leadingDistribution: TextLeadingDistribution.even,
    textBaseline: TextBaseline.alphabetic,
  );

  final TextStyle baseTextStyle = baseStyle.copyWith(
    color: Colors.black,
  );

  final Typography typography = Typography.material2014(
    platform: defaultTargetPlatform,
  );

  final TextTheme baseTextTheme = isDark ? typography.black : typography.white;

  return baseTextTheme.merge(
    TextTheme(
      displayLarge:
          baseTextStyle.copyWith(fontSize: 11.0, fontWeight: fontWeight),
      displayMedium:
          baseTextStyle.copyWith(fontSize: 11.0, fontWeight: fontWeight),
      displaySmall:
          baseTextStyle.copyWith(fontSize: 11.0, fontWeight: fontWeight),
      headlineLarge:
          baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      headlineMedium:
          baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      headlineSmall:
          baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      titleLarge:
          baseTextStyle.copyWith(fontSize: 28.0, fontWeight: fontWeight),
      titleMedium:
          baseTextStyle.copyWith(fontSize: 28.0, fontWeight: fontWeight),
      titleSmall:
          baseTextStyle.copyWith(fontSize: 28.0, fontWeight: fontWeight),
      bodyLarge: baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      bodyMedium:
          baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      bodySmall: baseTextStyle.copyWith(fontSize: 16.0, fontWeight: fontWeight),
      labelLarge:
          baseTextStyle.copyWith(fontSize: 10.0, fontWeight: fontWeight),
      labelMedium:
          baseTextStyle.copyWith(fontSize: 10.0, fontWeight: fontWeight),
      labelSmall:
          baseTextStyle.copyWith(fontSize: 10.0, fontWeight: fontWeight),
    ),
  );
}

//字体
final String appFontfamily = 'pingfang';

//字行高
final double fontHeight = 1.25;

final MFontFamilies = ["PingFang SC", 'PingFang TC', 'PingFang HK'];

/*创建MaterialColor*/
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;
  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

/*hex值获取颜色*/
Color hexColor(int hex, {double alpha = 1}) {
  if (alpha < 0) {
    alpha = 0;
  } else if (alpha > 1) {
    alpha = 1;
  }
  return Color.fromRGBO((hex & 0xFF0000) >> 16, (hex & 0x00FF00) >> 8,
      (hex & 0x0000FF) >> 0, alpha);
}

Color getTextColor(Color color) {
  return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

// chat room bubble style
Widget roundBubbleDecoration({
  required BubblePosition position,
  required BubbleType type,
  EdgeInsets? padding,
  required Widget child,
  bool isClipped = false,
  bool isPressed = false,
  bool isHighlight = false,
}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: type == BubbleType.sendBubble
          ? Color.alphaBlend(
              isPressed ? JXColors.outlineColor : Colors.transparent,
              JXColors.chatBubbleMeBgColor)
          : Color.alphaBlend(
              isPressed ? JXColors.outlineColor : Colors.transparent,
              JXColors.chatBubbleSenderBgColor),
      borderRadius: bubbleSideRadius(position, type),
    ),
    child: ClipRRect(
      clipBehavior: isClipped ? Clip.hardEdge : Clip.none,
      borderRadius: bubbleSideRadius(position, type),
      child: child,
    ),
  );
}

BorderRadius bubbleSideRadius(BubblePosition position, BubbleType type) {
  return BorderRadius.only(
    topLeft: Radius.circular(BubbleCorner.topLeftCorner(position, type)),
    topRight: Radius.circular(BubbleCorner.topRightCorner(position, type)),
    bottomLeft: Radius.circular(BubbleCorner.bottomLeftCorner(position, type)),
    bottomRight:
        Radius.circular(BubbleCorner.bottomRightCorner(position, type)),
  );
}

double bubbleBorderRadius = 16;

const double bubbleInnerPadding = 6;

class BubblePadding {
  static EdgeInsets nickname = const EdgeInsets.only(
    left: 10,
    top: 6,
  );

  static EdgeInsets forward = objectMgr.loginMgr.isDesktop
      ? const EdgeInsets.fromLTRB(12, 4, 12, 8)
      : const EdgeInsets.fromLTRB(12, 4, 12, 8).w;
}

List<Color> constMemberColor = [
  const Color(0xFFFA7162),
  const Color(0xFFF89558),
  const Color(0xFFFDB93E),
  const Color(0xFF82E47A),
  const Color(0xFF7180F8),
  const Color(0xFF5EAAEB),
  const Color(0xFF3FCAE0),
  const Color(0xFFC46EE6),
  if (false) ...[
    hexColor(0xFF7AB3),
    hexColor(0x44BAFF),
    hexColor(0x57C055),
    hexColor(0xFFCD00),
    hexColor(0xFF8C5C),
    hexColor(0x4DDDB2),
    hexColor(0xB772F2),
    hexColor(0x3DBEC7),
    hexColor(0x7492FF),
    hexColor(0xFF98A4),
    hexColor(0xFF98A4),
    hexColor(0xFF398E),
    hexColor(0x7400D7),
    hexColor(0x219EBC),
    hexColor(0x1AA97E),
    hexColor(0x3A8038),
    hexColor(0x0024A3),
    hexColor(0x784A50),
    hexColor(0x99682E),
  ]
];

Color groupMemberColor(int uid) {
  final colorIndex = uid % 8;
  return constMemberColor[colorIndex];
  if (uid == 0) {
    return Colors.black;
  }
  String uidString;
  // check if single digit uid
  if (uid.toString().length >= 2) {
    uidString = uid.toString().substring(uid.toString().length - 2);
  } else {
    uidString = uid.toString();
  }

  String index = '0';
  List uidList = uidString.split('');
  if (int.parse(uidList[0]) > 4) {
    index = '1';
  }

  if (uidList.length > 1) {
    index = index + uidList[1];
  }
  return constMemberColor[int.parse(index)];
}