import 'package:flutter/material.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/contact/qr_code.dart';

class GroupQRNameCard extends StatelessWidget {
  const GroupQRNameCard({
    super.key,
    required this.group,
    required this.data,
  });

  final Group group;
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CustomAvatar.group(
                      group,
                    size: 70
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            group.name,
                            style: jxTextStyle.textStyle20(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
