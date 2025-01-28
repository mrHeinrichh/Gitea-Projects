import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/contact/qr_code.dart';

class DownloadQRNameCard extends StatelessWidget {
  const DownloadQRNameCard({
    super.key,
    required this.user,
    required this.data,
  });

  final User user;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.grey.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 50,
                right: 50,
                bottom: 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CustomAvatar.user(
                    user,
                    size: 70,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.nickname,
                          style: jxTextStyle.textStyle20(),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(height: 8.5),
                        if (user.username.isNotEmpty)
                          Text(
                            "@ ${user.username}",
                            style: jxTextStyle.textStyle18(
                              color: colorTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QRCode(
                    qrData: data,
                    qrSize: objectMgr.loginMgr.isDesktop ? 200 : 280,
                    roundEdges: false,
                    color: colorQrCode,
                  ),
                  Image.asset(
                    'assets/images/qr_code_logo.png',
                    width: 54,
                    height: 54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
