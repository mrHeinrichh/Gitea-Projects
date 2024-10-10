import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/views/contact/qr_code.dart';

class NameCardQr extends StatelessWidget {
  const NameCardQr({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        QRCode(
          qrData: data,
          qrSize: 190,
          roundEdges: false,
          color: colorQrCode,
        ),
        Image.asset(
          'assets/images/qr_code_logo.png',
          width: 54,
          height: 54,
        ),
      ],
    );
  }
}
