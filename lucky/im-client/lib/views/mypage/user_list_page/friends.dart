import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/general.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class Friends extends StatefulWidget {
  const Friends({Key? key}) : super(key: key);

  @override
  _FriendsState createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          leadingWidth: 40.w,
          centerTitle: true,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Theme.of(context).appBarTheme.backgroundColor == Colors.black
                ? General.returnBackWhiteBtn()
                : General.returnBackBlackBtn(),
          ),
          title: Text(localized(myFriendsTitle),
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.color /*hexColor(0xFF333333)*/,
                  fontWeight: MFontWeight.bold6.value)),
        ),
        body: Container());
  }
}
