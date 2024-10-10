import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class NoContentView extends StatelessWidget {
  final String icon;
  final String? title;
  final String? subtitle;
  final double? subtitleFontSize;
  final Alignment alignment;

  const NoContentView({
    super.key,
    this.icon = 'no_content',
    this.title,
    this.subtitle,
    this.subtitleFontSize,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImage(
            'assets/images/common/$icon.png',
            size: 84,
            isAsset: true,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? localized(noResults),
            style: jxTextStyle.textStyleBold17(),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? localized(reelNoPublishedYet),
            style: TextStyle(
              fontSize: subtitleFontSize ?? MFontSize.size12.value,
              color: colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
