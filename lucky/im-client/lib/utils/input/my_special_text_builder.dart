import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/im/model/mention_model.dart';

import 'at_text.dart';

class MySpecialTextBuilder extends SpecialTextSpanBuilder {
  List<MentionModel> atList = [];

  MySpecialTextBuilder({
    required this.atList,
  });

  @override
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    var textSpan = super.build(data, textStyle: textStyle, onTap: onTap);
    //for performance, make sure your all SpecialTextSpan are only in textSpan.children
    //extended_text_field will only check SpecialTextSpan in textSpan.children
    return textSpan;
  }

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    if (flag.isEmpty) return null;

    if (isStart(flag, AtText.flag)) {
      return AtText(
        textStyle!,
        onTap,
        start: index - (AtText.flag.length - 1),
        atList: atList,
      );
    }

    return null;
  }
}
