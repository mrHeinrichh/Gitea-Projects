import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../utils/color.dart';
import '../../utils/theme/text_styles.dart';

class OfflineState extends StatelessWidget {
  const OfflineState({Key? key, required this.onTap}) : super(key: key);
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 40,
        ),
        Image.asset(
          'assets/images/common/offline.png',
          height: 150,
        ),
        const SizedBox(height: 20),
        Text(
          'You are currently offline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: MFontWeight.bold5.value,
          ),
        ),
        const Text(
          'Check your internet connection and retry again',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
              text: 'Retry Again',
              style: TextStyle(
                color: accentColor,
                fontWeight: MFontWeight.bold5.value,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap),
        ),
      ],
    );
  }
}
