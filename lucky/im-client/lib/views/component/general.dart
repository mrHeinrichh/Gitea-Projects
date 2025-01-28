import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class General {
  //黑色返回按钮
  static Widget returnBackBlackBtn({double? left}) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: left ?? 16.w),
      color: Colors.transparent,
      child: Image.asset(
        'assets/images/login_new/return_black.png',
        width: 20.w,
        height: 20.w,
      ),
    );
  }

  //白色返回按钮
  static Widget returnBackWhiteBtn({double? left}) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: left ?? 16.w),
      color: Colors.transparent,
      child: Image.asset(
        'assets/images/login_new/return_white.png',
        width: 20.w,
        height: 20.w,
      ),
    );
  }

  //灰色前进按钮
  static Widget returnForwardGreyBtn() {
    return Container(
      width: 20.w,
      height: 20.w,
      child: Image.asset('assets/images/mypage_new/next_setting.png'),
    );
  }
}
