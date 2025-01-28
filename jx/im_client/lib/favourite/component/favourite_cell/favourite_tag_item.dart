import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class FavouriteTagItem extends StatelessWidget {
  final String text;

  const FavouriteTagItem({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/svgs/favourite_tag_icon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            themeColor,
            BlendMode.srcIn,
          ),
          fit: BoxFit.fitWidth,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: jxTextStyle.supportText(color: themeColor),
        ),
      ],
    );
  }
}
