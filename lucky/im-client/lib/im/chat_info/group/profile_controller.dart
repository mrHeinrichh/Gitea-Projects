import 'package:flutter_screenutil/flutter_screenutil.dart';

const double initialScrollOffset = 50;
const double profileNormalSize = 280;

class ProfileController {
  static double screenWidth = ScreenUtil().screenWidth;
  static double maxHeight = 360.w;
  static double extendedHeight = 280.w;
  static int firstHeightAnimation = 320;
  static int secondHeightAnimation = 180;
  static double avatarCircleBig = 92.w;
  static double avatarCircleSmall = 40.w;
  static bool isFullScreenOpen = false;

  static double? getPictureSize({
    required double height,
    required double l, //large
    double? m, //medium
    double? s, //small
  }) {
    return height < ProfileController.firstHeightAnimation
        ? height < ProfileController.secondHeightAnimation
        ? m
        : s
        : l;
  }

  static getMaxHeight() => extendedHeight = profileNormalSize.w;
}
