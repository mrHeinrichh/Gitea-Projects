import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/general.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/theme/text_styles.dart';


class RuleDescription extends StatefulWidget {
  const RuleDescription({Key? key}) : super(key: key);

  @override
  _RuleDescriptionState createState() => _RuleDescriptionState();
}

class _RuleDescriptionState extends State<RuleDescription> {
  TextStyle fontstyle =
      TextStyle(fontSize: 12.sp, color: color666666, height: 1.5);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leadingWidth: 40.w,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: General.returnBackBlackBtn(),
        ),
        title: Text(
          localized(ruleActive),
          style: TextStyle(
              color: color1A1A1A,
              height: 1,
              fontSize: 15.sp,
              fontWeight: MFontWeight.bold5.value),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 20.w, right: 20.w, top: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localized(rule1), style: fontstyle),
            SizedBox(
              height: 8.w,
            ),
            Text(localized(rule2), style: fontstyle),
            SizedBox(
              height: 8.w,
            ),
            Text(localized(rule3), style: fontstyle),
            SizedBox(
              height: 8.w,
            ),
            Text(localized(rule4), style: fontstyle)
          ],
        ),
      ),
    );
  }
}
