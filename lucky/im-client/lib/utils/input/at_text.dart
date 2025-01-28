import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class AtText extends SpecialText {
  AtText(
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap, {
    this.start,
    required this.atList,
  }) : super(flag, ' ', textStyle, onTap: onTap);
  static const String flag = '@';
  final int? start;
  final List<MentionModel> atList;

  @override
  InlineSpan finishText() {
    final TextStyle? textStyle = this.textStyle?.copyWith(
          color: accentColor,
          fontSize: objectMgr.loginMgr.isDesktop
              ? MFontSize.size14.value
              : MFontSize.size16.value,
        );

    final String atText = toString();

    return SpecialTextSpan(
      text: '$flag${atList[int.parse(atText.substring(1)) - 1].userName}',
      actualText: '$flag${atList[int.parse(atText.substring(1)) - 1].userName}',
      start: start!,
      style: textStyle,
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) {
            onTap!(atText);
          }
        }),
    );
  }
}
