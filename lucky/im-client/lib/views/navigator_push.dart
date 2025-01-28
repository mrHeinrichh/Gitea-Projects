import 'package:jxim_client/views/page_mgr.dart';
import 'package:flutter/material.dart';

class NavigatorPush {
  //进入界面，支持回调函数
  static void to(BuildContext context, Widget page,
      [Function(dynamic value)? onBack]) {
    Navigator.push(
      context,
      MaterialPageRoute(
          maintainState: true,
          settings: pageMgr.savePage(page),
          builder: (context) {
            return page;
          }),
    ).then((value) {
      if (onBack != null) {
        onBack(value);
      }
    });
  }
}
