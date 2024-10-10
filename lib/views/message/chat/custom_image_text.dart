import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomImageText extends StatelessWidget {
  const CustomImageText({
    super.key,
    required this.height,
    required this.radius,
    required this.imageH,
    required this.imageW,
    required this.fontSize,
    required this.bgColor,
    required this.textColor,
    required this.title,
    required this.imageName,
  });
  final double height;
  final double radius;
  final double imageH;
  final double imageW;
  final double fontSize;
  final Color bgColor;
  final Color textColor;
  final String title;
  final String imageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.r),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 2.r),
            child: Image.asset(
              imageName,
              width: imageW,
              height: imageH,
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: 50.w,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
