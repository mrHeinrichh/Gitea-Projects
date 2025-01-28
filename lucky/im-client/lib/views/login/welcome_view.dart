import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(RouteName.registerProfile);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(47.w),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/svgs/welcome_image.svg',
                  width: 266,
                  height: 266,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 26.h,
                    bottom: 8.h,
                  ),
                  child: Text(
                    localized(homeSeemNew),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight:MFontWeight.bold4.value,
                    ),
                  ),
                ),
                Text(
                  localized(homeLetsStart),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
