import 'package:jxim_client/utils/input/face_util.dart';
import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaceText extends SpecialText {
  FaceText(TextStyle textStyle, {required this.start})
      : super(FaceText.flag, "]", textStyle);

  static const String flag = "[";

  final int start;

  @override
  InlineSpan finishText() {
    var key = toString();
    if (FaceUtil.instance.faceMap.containsKey(key)) {
      final double size = 18.w;
      return ImageSpan(
        AssetImage(FaceUtil.instance.faceMap[key]!),
        imageWidth: size,
        imageHeight: size,
        actualText: key,
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        start: start,
        fit: BoxFit.contain,
      );
    }
    return TextSpan(text: toString(), style: textStyle);
  }
}
