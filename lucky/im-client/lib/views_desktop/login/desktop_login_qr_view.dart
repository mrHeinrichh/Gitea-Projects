import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import '../../utils/color.dart';
import '../../utils/config.dart';
import '../../utils/lang_util.dart';
import '../../utils/theme/text_styles.dart';

class DesktopLoginQrView extends StatelessWidget {
  DesktopLoginQrView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      fontWeight:MFontWeight.bold4.value,
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
                    () => QRCode(
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
                Container(
                  width: 280,
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Text(
                          localized(scanToLogin,params: [Config().appName]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accentColor,
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
                              localized(openHeyTalkOnYourMobile,params: [Config().appName]),
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
                                color: JXColors.outlineColor,
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
                                color: JXColors.outlineColor,
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                'assets/svgs/scan.svg',
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localized(scanQrCode),
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
                        onTap: (){
                          Get.toNamed(RouteName.desktopOthersLogin);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Login with others method',style: TextStyle(fontSize: 14,fontWeight: MFontWeight.bold5.value,color: JXColors.blue,),),
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
