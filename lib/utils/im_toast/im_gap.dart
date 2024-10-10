import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImGap {
  static SizedBox hGap4 = SizedBox(width: 4.w);
  static SizedBox hGap8 = SizedBox(width: 8.w);
  static SizedBox hGap12 = SizedBox(width: 12.w);
  static SizedBox hGap16 = SizedBox(width: 16.w);
  static SizedBox hGap20 = SizedBox(width: 20.w);
  static SizedBox hGap24 = SizedBox(width: 24.w);
  static SizedBox hGap32 = SizedBox(width: 32.w);

  static SizedBox vGap4 = SizedBox(height: 4.w);
  static SizedBox vGap8 = SizedBox(height: 8.w);
  static SizedBox vGap12 = SizedBox(height: 12.w);
  static SizedBox vGap16 = SizedBox(height: 16.w);
  static SizedBox vGap20 = SizedBox(height: 20.w);
  static SizedBox vGap24 = SizedBox(height: 24.w);
  static SizedBox vGap32 = SizedBox(height: 32.w);

  static SizedBox hGap(double hGap) {
    return SizedBox(
      width: hGap.w,
    );
  }

  static SizedBox vGap(double vGap) {
    return SizedBox(
      height: vGap.w,
    );
  }
}
