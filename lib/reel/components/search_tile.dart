import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class SearchTile extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final String leftIcon;
  final String rightIcon;

  const SearchTile({
    super.key,
    required this.title,
    required this.onClose,
    required this.leftIcon,
    required this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SvgPicture.asset(
            'assets/svgs/$leftIcon.svg',
            width: 24,
            height: 24,
            colorFilter:
                const ColorFilter.mode(colorTextPrimary, BlendMode.srcIn),
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: jxTextStyle.textStyle17(),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: SvgPicture.asset(
              'assets/svgs/$rightIcon.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(colorTextPrimary, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }
}
