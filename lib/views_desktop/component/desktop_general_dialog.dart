import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

Future<Object?> desktopGeneralDialog(
  BuildContext context, {
  required Widget widgetChild,
  Color color = const Color.fromRGBO(50, 50, 50, 0.85),
  bool dismissible = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: '',
    barrierColor: color,
    pageBuilder: (context, animation, secondaryAnimation) {
      return widgetChild;
    },
  );
}

///退出登入的界面
Widget logoutContext = Center(
  child: Material(
    color: Colors.transparent,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                    bottom: 15,
                  ),
                  child: Center(
                    child: Text(
                      "Log Out",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Are you sure you want to",
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 5,
                    bottom: 10,
                  ),
                  child: Center(
                    child: Text(
                      "Log Out ?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Divider(
                      height: 0,
                    ),
                    DesktopGeneralButton(
                      horizontalPadding: 0,
                      onPressed: () => objectMgr.logout(),
                      child: Container(
                        width: 400,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Log Out",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        DesktopGeneralButton(
          onPressed: () => Get.back(),
          child: Container(
            width: 400,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                localized(buttonCancel),
                style: TextStyle(color: themeColor),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
