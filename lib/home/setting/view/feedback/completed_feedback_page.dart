import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class CompletedFeedbackPage extends StatelessWidget {
  const CompletedFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        bgColor: colorWhite,
      ),
      body: Column(
        children: [
          Expanded(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svgs/thankYouFeedbackImageIcon.svg',
                  width: 148.w,
                  height: 148.w,
                  fit: BoxFit.fill,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    localized(thankFeedback),
                    style: jxTextStyle.textStyle16(),
                  ),
                ),
                Text(
                  localized(thankFeedbackDescription),
                  textAlign: TextAlign.center,
                  style: jxTextStyle.textStyle14(
                      color: colorTextSupporting),
                )
              ],
            ),
          )),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                backgroundColor: themeColor,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                splashFactory: NoSplash.splashFactory,
                animationDuration: const Duration(milliseconds: 1),
              ),
              onPressed: () {
                Get.back();
              },
              child: Text(
                localized(buttonDone),
                style: jxTextStyle.textStyleBold16(
                  color: colorWhite,
                  fontWeight: MFontWeight.bold6.value,
                ).copyWith(height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
