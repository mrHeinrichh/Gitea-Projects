import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

Border customBorder = Border(
  bottom: BorderSide(
    color: colorTextPrimary.withOpacity(0.2),
    width: 0.33,
  ),
);

Divider separateDivider({indent = 16.0}) {
  return Divider(
    color: colorTextPrimary.withOpacity(0.2),
    thickness: 0.33,
    height: 1,
    indent: indent,
  );
}

class CustomDivider extends StatelessWidget {
  final double? thickness;
  final Color? color;
  final double indent;
  final double height;

  const CustomDivider({
    super.key,
    this.thickness = 0.33,
    this.color,
    this.indent = 0,
    this.height = 0.33,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: indent,
      height: height,
      thickness: thickness,
      color: color ?? colorTextPlaceholder,
    );
  }
}
