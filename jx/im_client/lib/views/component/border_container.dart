import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';

class BorderContainer extends StatelessWidget {
  final double verticalPadding;
  final double horizontalPadding;
  final Widget child;
  final double horizontalMargin;
  final double verticalMargin;
  final double? borderRadius;
  final Color? bgColor;
  final Function()? onClick;

  const BorderContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.verticalPadding = 12,
    this.horizontalPadding = 16,
    this.horizontalMargin = 0,
    this.verticalMargin = 0,
    this.bgColor = Colors.white,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    double radius = borderRadius ?? 12;

    Widget content = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: ImBorderRadius.all(radius),
        color: bgColor,
      ),
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: verticalMargin,
        horizontal: horizontalMargin,
      ).w,
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ).w,
      child: child,
    );

    return onClick != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClick,
            child: ImClickEffect(
              borderRadius: radius,
              child: content,
            ),
          )
        : content;
  }
}
