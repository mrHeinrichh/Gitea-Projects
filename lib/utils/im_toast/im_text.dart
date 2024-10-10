import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_font_size.dart';

class ImText extends StatelessWidget {
  final String text;
  final bool inherit;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final double? wordSpacing;
  final double height;
  final TextDecoration decoration;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? textOverflow;
  final double? textScaleFactor;
  final int maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final bool isGradient; // For gradient
  final List<Color>? colorList; // For gradient
  final Alignment begin; // For gradient
  final Alignment end; // For gradient

  const ImText(
    this.text, {
    super.key,
    this.inherit = true,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.wordSpacing,
    this.height = 1.2,
    this.decoration = TextDecoration.none,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textOverflow = TextOverflow.ellipsis,
    this.textScaleFactor,
    this.maxLines = 1,
    this.semanticsLabel,
    this.textWidthBasis,
    this.isGradient = false,
    this.colorList,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) {
    Text textWidget = Text(
      text,
      style: TextStyle(
        inherit: inherit,
        color: color ?? ImColor.black,
        fontSize: fontSize?.sp ?? ImFontSize.normal.sp,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height.w,
        decoration: decoration,
      ),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: textOverflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
    );

    if (isGradient) {
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: begin,
            end: end,
            colors: colorList ??
                [
                  ImColor.orange,
                  ImColor.blue,
                ], // Temporary default gradient color
          ).createShader(Offset.zero & bounds.size);
        },
        blendMode: BlendMode.srcIn,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
