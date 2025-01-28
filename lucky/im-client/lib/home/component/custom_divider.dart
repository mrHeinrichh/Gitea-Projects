import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/color.dart';

Border customBorder = const Border(
  bottom: BorderSide(
    color: JXColors.borderPrimaryColor,
    width: 0.33,
  ),
);

Border customPurpleBorder = Border(
  bottom: BorderSide(
    color: accentColor.withOpacity(0.2),
    width: 0.5.w,
  ),
);

Divider SeparateDivider({indent = 16.0}) {
  return Divider(
    color: JXColors.borderPrimaryColor,
    thickness: 0.33,
    height: 1,
    indent: indent,
  );
}

class CustomDivider extends StatelessWidget {
  final double? thickness;
  final Color? color;

  const CustomDivider({
    Key? key,
    this.thickness = 0.5,
    this.color = JXColors.outlineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: 0,
      height: 0,
      thickness: thickness,
      color: color,
    );
  }
}
