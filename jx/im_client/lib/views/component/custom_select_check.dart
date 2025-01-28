import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomSelectCheck extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool showDivider;
  final Function() onClick;

  const CustomSelectCheck({
    super.key,
    required this.text,
    this.isSelected = false,
    this.showDivider = false,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.opaque,
      child: OverlayEffect(
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: showDivider ? customBorder : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: jxTextStyle.textStyle17(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              if (isSelected)
                CustomImage(
                  'assets/svgs/check1.svg',
                  size: 24,
                  color: themeColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
