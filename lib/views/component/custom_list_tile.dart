import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomListTile extends StatelessWidget {
  final double? height;
  final String text;
  final Color? textColor;
  final String? subText;
  final FontWeight? textFontWeight;
  final String? rightText;
  final Widget? leading;
  final Widget? trailing;
  final double marginLeft;
  final bool showDivider;
  final VoidCallback? onClick;
  final VoidCallback? onArrowClick;

  const CustomListTile({
    super.key,
    this.height,
    required this.text,
    this.textColor,
    this.subText,
    this.textFontWeight,
    this.rightText,
    this.leading,
    this.trailing,
    this.marginLeft = 16,
    this.showDivider = false,
    this.onClick,
    this.onArrowClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onClick != null) {
          onClick!();
        } else if (onArrowClick != null) {
          onArrowClick!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: OverlayEffect(
        withEffect: onClick != null || onArrowClick != null,
        child: Container(
          margin: EdgeInsets.only(left: marginLeft),
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: leading!,
                ),
              Expanded(
                child: Container(
                  height: height,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    border: showDivider ? customBorder : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: jxTextStyle.textStyleBold17(
                                color: textColor ?? colorTextPrimary,
                                fontWeight:
                                    textFontWeight ?? MFontWeight.bold4.value,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subText != null)
                              Text(
                                subText!,
                                style: jxTextStyle.textStyle13(
                                  color: colorTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (rightText != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          rightText!,
                          style: jxTextStyle.textStyle17(
                              color: colorTextSecondary),
                        ),
                      ],
                      if (trailing != null) trailing!,
                      if (onArrowClick != null)
                        CustomImage(
                          'assets/svgs/right_arrow_thick.svg',
                          padding: const EdgeInsets.only(left: 8),
                          color: colorTextPrimary.withOpacity(0.38),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
