import 'package:jxim_client/utils/color.dart';

import 'package:jxim_client/views/message/chat/custom_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/theme/text_styles.dart';

class CustomSingleButton extends StatelessWidget {
  const CustomSingleButton(
      {Key? key,
      required this.title,
      required this.titleFonSize,
      required this.titleColor,
      required this.sure,
      required this.sureFonSize,
      required this.sureColor,
      required this.onSure,
      this.subTextColor,
      this.subText,
      this.windowWidth})
      : super(key: key);
  final String title;
  final double titleFonSize;
  final Color titleColor;
  final String sure;
  final double sureFonSize;
  final Color sureColor;
  final VoidCallback onSure;
  final Color? subTextColor;
  final String? subText;
  final double? windowWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Container(
        width: windowWidth ?? 300.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(width: 0.2, color: hexColor(0xEDEDED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0.w, 20.w, 0.w, 20.w),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFonSize,
                  fontWeight: MFontWeight.bold5.value,
                  color: titleColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            subText != null
                ? Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0.w, 20.w, 36.w),
                    child: Text(
                      subText!,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.normal,
                          color: subTextColor ?? color666666,
                          decoration: TextDecoration.none,
                          height: 22 / 13),
                    ),
                  )
                : const SizedBox(),
            Padding(
              padding: EdgeInsets.fromLTRB(23.w, 0, 23.w, 30.w),
              child: CustomGradientButton(
                onPress: () {
                  onSure();
                },
                width: double.infinity,
                height: 45.w,
                gradientColor: [colorE5454D, colorE5454D],
                textColor: sureColor,
                fontSize: sureFonSize,
                radius: 23.w,
                title: sure,
                enable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
