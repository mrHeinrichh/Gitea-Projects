import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../object/user.dart';
import '../../../utils/color.dart';
import '../../../utils/theme/text_styles.dart';
import '../../component/custom_avatar.dart';
import '../qr_code.dart';

class DownloadQRNameCard extends StatelessWidget {
  const DownloadQRNameCard({
    Key? key,
    required this.user,
    required this.data,
  }) : super(key: key);

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
                  top: 50, left: 50, right: 50, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CustomAvatar(
                    uid: user.uid,
                    size: 70,
                  ),
                  Expanded(
                    child: Padding(
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
                                  color: JXColors.secondaryTextBlack),
                            ),
                        ],
                      ),
                    ),
                  )
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
                    color: qrCodeColor,
                  ),
                  Image.asset(
                    'assets/images/qr_code_logo.png',
                    width: 54,
                    height: 54,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
