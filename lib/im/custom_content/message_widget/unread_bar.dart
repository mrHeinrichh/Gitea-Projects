import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class UnreadBar extends StatelessWidget {
  const UnreadBar({
    super.key,
  });

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
          : colorWhite.withOpacity(0.6),
      child: Text(
        localized(chatUnreadMessages),
        style: jxTextStyle.chatReadBarText(),
      ),
    );
  }
}
