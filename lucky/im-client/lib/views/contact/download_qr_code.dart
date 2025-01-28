import 'package:flutter/material.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import '../../utils/theme/text_styles.dart';
import '../login/components/company_logo.dart';

class DownloadQRCode extends StatelessWidget {
  final String downloadLink;

  const DownloadQRCode({super.key, required this.downloadLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CompanyLogo(width: 60),
          const SizedBox(height: 8),
          Text(
            Config().appName,
            style: jxTextStyle.textStyleBold20(),
          ),
          const SizedBox(height: 16),
          QRCode(
            qrData: downloadLink,
            qrSize: 280,
            roundEdges: false,
          ),
        ],
      ),
    );
  }
}
