import 'package:flutter/material.dart';

import '../../../utils/color.dart';
import '../qr_code.dart';

class NameCardQr extends StatelessWidget {
  const NameCardQr({
    Key? key,
    required this.data,
  }) : super(key: key);

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
          color: qrCodeColor,
        ),
        Image.asset(
          'assets/images/qr_code_logo.png',
          width: 54,
          height: 54,
        )
      ],
    );
  }
}
