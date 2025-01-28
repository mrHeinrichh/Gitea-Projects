import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CheckTickItem extends StatelessWidget {
  const CheckTickItem({
    super.key,
    this.isCheck = false,
    this.showUnCheckbox = true,
    this.borderColor,
    this.circleSize = 20.0,
    this.circlePaddingValue = 4.0,
  });

  final bool isCheck;
  final bool showUnCheckbox;
  final Color? borderColor;
  final double circleSize;
  final double circlePaddingValue;

  @override
  Widget build(BuildContext context) {
    double size = circleSize;

    if (isCheck) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(circlePaddingValue),
        decoration: BoxDecoration(
          color: themeColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.transparent,
          ),
        ),
        child: SvgPicture.asset(
          'assets/svgs/check.svg',
          colorFilter: const ColorFilter.mode(colorWhite, BlendMode.srcIn),
        ),
      );
    } else {
      if (showUnCheckbox) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? colorTextPrimary.withOpacity(0.28),
            ),
          ),
          child: borderColor != null && objectMgr.loginMgr.isDesktop
              ? Container(
                  width: size - 2,
                  height: size - 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorTextPrimary.withOpacity(0.09),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorTextPrimary.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 5,
                      )
                    ],
                  ),
                )
              : null,
        );
      } else {
        return const SizedBox();
      }
    }
  }
}
