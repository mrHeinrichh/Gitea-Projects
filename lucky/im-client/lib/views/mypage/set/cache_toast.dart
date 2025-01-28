import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class CacheToast extends StatefulWidget {
  final String content;
  const CacheToast({Key? key, required this.content}) : super(key: key);

  @override
  _CacheToastState createState() => _CacheToastState();
}

class _CacheToastState extends State<CacheToast> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: hexColor(0xFCFCFC)),
        width: 270.w,
        height: 149.h,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 26.h),
            Expanded(
                child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Text(widget.content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17.sp,
                          color: hexColor(0x030303),
                          decoration: TextDecoration.none)),
                ),
                SizedBox(height: 18.h),
                Text('300.56',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: hexColor(0x00D2E4),
                        decoration: TextDecoration.none)),
              ],
            )),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        width: 1.h, color: hexColor(0x4D4D4D, alpha: 0.18))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 270.w / 2,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                            right: BorderSide(
                                width: 1.h,
                                color: hexColor(0x4D4D4D, alpha: 0.18))),
                      ),
                      padding: EdgeInsets.only(top: 11.h, bottom: 11.h),
                      child: Center(
                        child: Text(localized(popupConfirm),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17.sp,
                                color: hexColor(0x00D2E4),
                                decoration: TextDecoration.none)),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      color: Colors.transparent,
                      width: 270.w / 2,
                      padding: EdgeInsets.only(top: 11.h, bottom: 11.h),
                      child: Center(
                        child: Text(localized(popupCancel),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17.sp,
                                color: hexColor(0x00D2E4),
                                decoration: TextDecoration.none)),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
