import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class UnreadBar extends StatelessWidget {
  const UnreadBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: objectMgr.loginMgr.isDesktop ? 4 : 4.w),
      margin: EdgeInsets.symmetric(
          vertical: objectMgr.loginMgr.isDesktop ? 8 : 8.w),
      alignment: Alignment.center,
      color: objectMgr.loginMgr.isDesktop
          ? const Color(0xFFFEFEFE)
          : JXColors.unreadBarBgColor,
      child: Text(
        localized(chatUnreadMessages),
        style: jxTextStyle.chatReadBarText(),
      ),
    );
  }
}
