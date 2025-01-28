import 'package:flutter/material.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomButton extends StatelessWidget {
  CustomButton({
    Key? key,
    this.text = '',
    required this.callBack,
    this.color,
    this.textColor = Colors.white,
    this.isBold = true,
    this.withBorder = false,
    this.contentWidget,
  }) : super(key: key);

  final String text;
  final Function() callBack;
  Color? color;
  Color textColor;
  bool? isBold;
  final bool withBorder;
  final Widget? contentWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callBack,
      child: ForegroundOverlayEffect(
        radius: const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.circular(12),
        ),
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color ?? accentColor,
            borderRadius: BorderRadius.circular(12),
            border: withBorder
                ? Border.all(color: JXColors.borderPrimaryColor)
                : const Border(),
          ),
          child: contentWidget != null
              ? contentWidget!
              : Text(
                  text,
                  style: objectMgr.loginMgr.isDesktop ? TextStyle(
                    fontSize: MFontSize.size13.value,
                    fontWeight: MFontWeight.bold4.value,
                    color: textColor,
                  ) : jxTextStyle.textStyleBold16(
                    color: textColor,
                    fontWeight: (isBold == true)
                        ? MFontWeight.bold5.value
                        : MFontWeight.bold4.value,
                  ),
                ),
        ),
      ),
    );
  }
}
