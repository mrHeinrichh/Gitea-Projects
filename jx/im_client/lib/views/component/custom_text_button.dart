import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final double? fontSize;
  final bool isBold;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool isDisabled;
  final VoidCallback? onClick;

  const CustomTextButton(
    this.text, {
    super.key,
    this.fontSize,
    this.isBold = false,
    this.color,
    this.padding,
    this.isDisabled = false,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? MFontSize.size17.value,
        fontWeight: isBold ? MFontWeight.bold5.value : MFontWeight.bold4.value,
        leadingDistribution: TextLeadingDistribution.even,
        color: isDisabled ? colorTextSupporting : color ?? themeColor,
        fontFamily: appFontFamily,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : onClick,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: isDisabled ? child : OpacityEffect(child: child),
        ),
      ),
    );
  }
}
