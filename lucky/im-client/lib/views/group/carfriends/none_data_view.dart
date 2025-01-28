import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class NoneDataView extends StatelessWidget {
  const NoneDataView({
    Key? key,
    this.padding = 30,
    this.noneText = "",
    this.showLoading = false,
  }) : super(key: key);
  final int padding;
  final String noneText;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    noneText == "" ? localized(myGroupEmpty) : noneText;
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.only(top: padding.w),
      alignment: Alignment.topCenter,
      child: showLoading
          ? Padding(
              padding: EdgeInsets.only(top: 20.w),
              child: SizedBox(
                width: 30.w,
                height: 30.w,
                child: BallCircleLoading(
                  radius: 10.w,
                  ballStyle: BallStyle(
                    size: 4.w,
                    color: accentColor,
                    ballType: BallType.solid,
                    borderWidth: 2,
                    borderColor: accentColor,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Image.asset(
                  'assets/images/message/no_result.png',
                  width: 200.w,
                  height: 155.w,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.w),
                  child: Text(
                    noneText,
                    style: TextStyle(
                      color: color666666,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
