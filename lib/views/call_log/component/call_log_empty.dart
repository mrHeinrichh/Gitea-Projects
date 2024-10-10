import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CallLogEmpty extends StatelessWidget {
  const CallLogEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomImage(
            'assets/images/call_log_empty.png',
            isAsset: true,
            size: 84,
          ),
          const SizedBox(height: 24),
          Text(
            localized(callNoRecords),
            style: jxTextStyle.textStyleBold17(),
          ),
          const SizedBox(height: 8),
          Text(
            localized(callNoRecordsDescription),
            style: jxTextStyle.textStyle17(color: colorTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
