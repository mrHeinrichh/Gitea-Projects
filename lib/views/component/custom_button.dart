import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.text = '',
    this.fontSize,
    this.callBack,
    this.color,
    this.textColor = colorWhite,
    this.isBold = true,
    this.withBorder = false,
    this.radius = 12,
    this.height = 52,
    this.contentWidget,
    this.isDisabled = false,
  });

  final String text;
  final double? fontSize;
  final VoidCallback? callBack;
  final Color? color;
  final Color textColor;
  final bool isBold;
  final bool withBorder;
  final double radius;
  final double height;
  final Widget? contentWidget;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return GestureDetector(
      onTap: isDisabled ? null : callBack,
      child: ForegroundOverlayEffect(
        radius: borderRadius,
        withEffect: !isDisabled,
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDisabled
                ? colorTextPrimary.withOpacity(0.06)
                : color ?? themeColor,
            borderRadius: borderRadius,
            border: withBorder
                ? Border.all(color: colorTextPrimary.withOpacity(0.2))
                : const Border(),
          ),
          child: contentWidget != null
              ? contentWidget!
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDisabled ? colorTextPlaceholder : textColor,
                    fontSize: objectMgr.loginMgr.isDesktop
                        ? MFontSize.size13.value
                        : fontSize ?? MFontSize.size17.value,
                    fontWeight: objectMgr.loginMgr.isDesktop || !isBold
                        ? MFontWeight.bold4.value
                        : MFontWeight.bold5.value,
                  ),
                ),
        ),
      ),
    );
  }
}
