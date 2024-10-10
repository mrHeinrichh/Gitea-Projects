import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/check_login_task.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class DesktopLoginQrView extends StatefulWidget {
  const DesktopLoginQrView({super.key});

  @override
  State<DesktopLoginQrView> createState() => _DesktopLoginQrViewState();
}

class _DesktopLoginQrViewState extends State<DesktopLoginQrView> {
  late CheckLoginTask checkLoginTask;
  String desktopSecret = '';
  @override
  void initState() {
    super.initState();
    checkLoginTask = CheckLoginTask();
    objectMgr.scheduleMgr.addTask(checkLoginTask);
    unawaited(
      desktopGenerateQR().then((value) {
        objectMgr.loginMgr.desktopSecret.value = value;
      }),
    );
  }

  @override
  void dispose() {
    objectMgr.scheduleMgr.removeTask(checkLoginTask);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      fontWeight: MFontWeight.bold4.value,
      fontSize: 14,
      letterSpacing: 0.25,
    );
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                  ),
                  child: Obx(
                    () => objectMgr.loginMgr.desktopSecret.isEmpty
                        ? const CircularProgressIndicator()
                        : QRCode(
                            qrSize: 200,
                            qrData: jsonEncode(
                              {
                                "login": objectMgr.loginMgr.desktopSecret.value,
                              },
                            ),
                            roundEdges: true,
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 280,
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Text(
                          localized(scanToLogin, params: [Config().appName]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: MFontWeight.bold5.value,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: NumberIcon(title: "1"),
                            ),
                            Text(
                              localized(
                                openHeyTalkOnYourMobile,
                                params: [Config().appName],
                              ),
                              style: textStyle,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: NumberIcon(title: "2"),
                            ),
                            Text(
                              localized(clickOn),
                              style: textStyle,
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              decoration: const BoxDecoration(
                                color: colorBorder,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_vert_outlined,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              localized(and),
                              style: textStyle,
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: colorBorder,
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                'assets/svgs/scan.svg',
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localized(scanQRCodeTitle),
                              style: textStyle,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: NumberIcon(title: "3"),
                          ),
                          Text(
                            localized(scanThisQRCodeToConnect),
                            style: textStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          Get.offNamed(RouteName.desktopOthersLogin);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Login with others method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: MFontWeight.bold5.value,
                              color: themeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NumberIcon extends StatelessWidget {
  const NumberIcon({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: MFontWeight.bold5.value,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
