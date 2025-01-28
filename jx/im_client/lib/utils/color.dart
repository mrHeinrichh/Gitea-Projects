import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

//w文本键盘颜色
const Brightness txtBrightness = Brightness.light;

//主题
ThemeData themeData() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: colorWhite,
      iconTheme: IconThemeData(color: Colors.black),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    // textTheme: _textTheme(false, FontWeight.normal,),
    dividerColor: colorBackground6,
    iconTheme: IconThemeData(color: themeColor),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: themeColor.withOpacity(.32),
      selectionHandleColor: themeColor, //安卓光标球颜色
    ),
    fontFamily: appFontfamily,
    unselectedWidgetColor: themeColor,
    colorScheme:
        ColorScheme.fromSwatch(primarySwatch: createMaterialColor(themeColor))
            .copyWith(background: hexColor(0xFFFFFFFFF)),
  );
}

ThemeData darkThemeData() {
  return ThemeData(
    // 主题颜色属于亮色系还是属于暗色系(eg:dark时,AppBarTitle文字及状态栏文字的颜色为白色,反之为黑色)
    // 这里设置为dark目的是,不管App是明or暗,都将appBar的字体颜色的默认值设为白色.
    // 再AnnotatedRegion<SystemUiOverlayStyle>的方式,调整响应的状态栏颜色
    brightness: Brightness.dark,
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
      selectionColor: themeColor.withOpacity(.32),
      selectionHandleColor: themeColor, //安卓光标球颜色
    ),
    fontFamily: appFontfamily,
    colorScheme:
        ColorScheme.fromSwatch(primarySwatch: createMaterialColor(Colors.black))
            .copyWith(background: hexColor(0x040404)),
  );
}

//字体
const String appFontfamily = 'pingfang';

//字行高
const double fontHeight = 1.25;

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
  return Color.fromRGBO(
    (hex & 0xFF0000) >> 16,
    (hex & 0x00FF00) >> 8,
    (hex & 0x0000FF) >> 0,
    alpha,
  );
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
              isPressed ? colorTextPlaceholder : Colors.transparent,
              bubbleSecondary,
            )
          : Color.alphaBlend(
              isPressed ? colorTextPlaceholder : Colors.transparent,
              colorWhite,
            ),
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

double bubbleBorderRadius = 16.r;

double bubbleInnerPadding = 12.w;

EdgeInsetsGeometry forwardTitlePadding =
    EdgeInsets.symmetric(vertical: 4.w, horizontal: 12.w);

class BubblePadding {
  static EdgeInsets nickname = const EdgeInsets.only(
    left: 10,
    top: 6,
  );
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
];

Color groupMemberColor(int uid) {
  final colorIndex = uid % 8;
  return constMemberColor[colorIndex];
}
