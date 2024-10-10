import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class FullScreenWidthButton extends StatelessWidget {
  const FullScreenWidthButton({
    super.key,
    required this.title,
    this.onTap,
    this.buttonColor,
    this.textColor = colorWhite,
    this.borderColor,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.margin,
    this.padding,
    this.height,
    this.icon,
  });
  final String title;
  final GestureTapCallback? onTap;
  final Color? buttonColor;
  final Color textColor;
  final Color? borderColor;
  final double fontSize;
  final double? height;
  final FontWeight fontWeight;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: buttonColor ?? themeColor,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 2)
              : null,
          borderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        padding: padding ??
            EdgeInsets.symmetric(
              vertical: 15.h,
            ),
        margin: EdgeInsets.symmetric(horizontal: 0.h, vertical: 5.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize.sp,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
            if (icon != null) icon!,
          ],
        ),
      ),
    );
  }
}
