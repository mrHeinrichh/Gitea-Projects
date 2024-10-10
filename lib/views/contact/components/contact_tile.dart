import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.title,
    this.svgIcon,
    this.count = 0,
    this.onTap,
  });

  final String? svgIcon;
  final String title;
  final int count;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OverlayEffect(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/${svgIcon ?? 'add_friends_plus'}.svg',
                width: 40,
                height: 40,
                colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
              const Spacer(),
              if (count > 0)
                Container(
                  height: 18,
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: themeColor,
                    shape: count < 100
                        ? const CircleBorder()
                        : const StadiumBorder(),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      leadingDistribution: TextLeadingDistribution.even,
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
