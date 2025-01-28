import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImBorderRadius {
  static BorderRadius borderRadius4 = BorderRadius.circular(4.w);
  static BorderRadius borderRadius8 = BorderRadius.circular(8.w);
  static BorderRadius borderRadius12 = BorderRadius.circular(12.w);
  static BorderRadius borderRadius16 = BorderRadius.circular(16.w);
  static BorderRadius borderRadius20 = BorderRadius.circular(20.w);

  static BorderRadius all(double radius) => BorderRadius.circular(radius.w);

  static BorderRadius only(
      {double topRight = 0.0,
        double topLeft = 0.0,
        double bottomRight = 0.0,
        double bottomLeft = 0.0}) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft.w),
      topRight: Radius.circular(topRight.w),
      bottomLeft: Radius.circular(bottomLeft.w),
      bottomRight: Radius.circular(bottomRight.w),
    );
  }
}
