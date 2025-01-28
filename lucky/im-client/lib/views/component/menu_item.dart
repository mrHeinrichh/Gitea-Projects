import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

PopupMenuEntry menuItem(
    {int? value, String? icon, String? text, bool isShowTick = false}) {
  return PopupMenuItem(
    value: value,
    height: 36,
    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
    child: Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/svgs/$icon.svg',
              width: 24,
              height: 24,
              color: accentColor,
              fit: BoxFit.fitWidth,
            ),
          ),
        Expanded(
          child: Text(
            text ?? "",
            style: jxTextStyle.textStyle15(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        if (isShowTick)
          SvgPicture.asset(
            'assets/svgs/check.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(accentColor, BlendMode.srcATop),
          )
      ],
    ),
  );
}
