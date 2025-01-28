import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/color.dart';

class CheckTickItem extends StatelessWidget {
  const CheckTickItem({
    Key? key,
    this.isCheck,
    this.showUnCheckbox = true,
    this.borderColor,
  }) : super(key: key);

  final bool? isCheck;
  final bool? showUnCheckbox;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (isCheck == true) {
      return Container(
        width: 20,
        height: 20,
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: SvgPicture.asset(
          'assets/svgs/check.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      );
    } else {
      if (showUnCheckbox == true) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Shape of the container
            border: Border.all(
              color: borderColor ?? JXColors.primaryTextBlack.withOpacity(0.28), // Border color
              width: 1.5,
            ),
          ),
        );
      } else {
        return const SizedBox();
      }
    }
  }
}
