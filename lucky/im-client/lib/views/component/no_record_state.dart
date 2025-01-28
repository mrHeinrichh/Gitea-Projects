import 'package:flutter/material.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/theme/text_styles.dart';

class NoRecordState extends StatelessWidget {
  const NoRecordState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: JXColors.white,
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
