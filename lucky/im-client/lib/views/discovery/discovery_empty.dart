import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_font_size.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/call_log/component/call_bottom_modal.dart';
import '../../../utils/lang_util.dart';
import '../../utils/im_toast/im_color.dart';

class DiscoveryEmpty extends StatelessWidget {
  final bool isRecommend;

  const DiscoveryEmpty({Key? key, required this.isRecommend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 57.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Image.asset(
              'assets/images/common/empty-norecord.png',
              width: 148.w,
              height: 148.w,
            ),
          ),
          Text(
            localized(
                isRecommend ? noDiscoveryRecommend : noDiscoveryCollection),
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 16.sp,
              letterSpacing: 0.15,
            ),
          ),
          SizedBox(
            height: 4.h,
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ImText(
              localized(
                  isRecommend ? waitForMoreRecommend : goToGroupGameToCollect),
              color: ImColor.black60,
              fontWeight: FontWeight.w400,
              fontSize: ImFontSize.normal,
            ),
          ),
        ],
      ),
    );
  }
}
