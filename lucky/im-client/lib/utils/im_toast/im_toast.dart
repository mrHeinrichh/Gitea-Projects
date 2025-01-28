import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/im_toast/im_border_radius.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';

import '../theme/text_styles.dart';
import 'im_font_size.dart';

Future<void> ImToast(
    BuildContext context, {
      int horizontalPadding = 110,
      int status = 0,
      required String title,
      required String subtitle,
      int duration = 3,
    }) async {
  late Timer timer;

  String img;

  if (status == 0) {
    img = 'icon_toast_fail';
  } else {
    img = 'icon_toast_success';
  }

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      timer = Timer(Duration(seconds: duration), () {
        Get.back();
      });

      return Dialog(
        backgroundColor: ImColor.grey52,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: ImBorderRadius.borderRadius12,
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding.w),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'packages/im_common/assets/img/$img.png',
                width: 44.w,
                height: 44.w,
                fit: BoxFit.fill,
              ),
              ImGap.vGap12,
              ImText(
                title,
                fontWeight: MFontWeight.bold6.value,
                color: ImColor.white,
                textAlign: TextAlign.center,
              ),
              ImGap.vGap4,
              ImText(
                subtitle,
                fontSize: ImFontSize.small,
                color: ImColor.white,
                maxLines: 10,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  ).then((val) {
    if (timer.isActive) {
      timer.cancel();
    }
  });
}

class CustomToastWidget extends StatelessWidget {
  const CustomToastWidget({
    super.key,
    this.status = 0,
    required this.title,
    required this.subtitle,
  });

  final int status;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    String img;
    if (status == 0) {
      img = 'icon_toast_fail';
    } else {
      img = 'icon_toast_success';
    }
    return Container(
      width: 160.w,
      height: 160.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ImColor.grey52,
        shape: BoxShape.rectangle,
        borderRadius: ImBorderRadius.borderRadius12,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'packages/im_common/assets/img/$img.png',
              width: 44.w,
              height: 44.w,
              fit: BoxFit.fill,
            ),
            ImGap.vGap12,
            ImText(
              title,
              fontWeight: MFontWeight.bold6.value,
              color: ImColor.white,
              textAlign: TextAlign.center,
            ),
            ImGap.vGap4,
            ImText(
              subtitle,
              fontSize: ImFontSize.small,
              color: ImColor.white,
              maxLines: 10,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
