import 'package:jxim_client/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class NoConnectView extends StatefulWidget {
  const NoConnectView({Key? key}) : super(key: key);

  @override
  State<NoConnectView> createState() => _NoConnectViewState();
}

class _NoConnectViewState extends State<NoConnectView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(vertical: 10.w),
      color: hexColor(0xFBEEED),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/common/tips.png', width: 16.w),
          SizedBox(width: 4.w),
          Text(localized(toastNotConnected),
              style: TextStyle(fontSize: 12.sp, color: color666666))
        ],
      ),
    );
  }
}
