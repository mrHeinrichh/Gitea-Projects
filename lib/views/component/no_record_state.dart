import 'package:flutter/material.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class NoRecordState extends StatelessWidget {
  const NoRecordState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorWhite,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset(
            'assets/images/common/empty-norecord.png',
            width: 148,
            height: 148,
          ),
          const SizedBox(height: 16.0),
          Text(
            localized(noRecord),
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: MFontWeight.bold5.value,
            ),
          ),
        ],
      ),
    );
  }
}
