import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CustomTextEditingController extends TextEditingController {
  final Function(int uid)? onTap;
  final List<MentionModel> atList;

  static List<List<int>> mentionRange = <List<int>>[];

  CustomTextEditingController({
    required this.atList,
    this.onTap,
  });

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    if (mentionRange.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final TextStyle? textStyle = style?.copyWith(
      color: accentColor,
      fontSize: objectMgr.loginMgr.isDesktop
          ? MFontSize.size14.value
          : MFontSize.size16.value,
    );

    final textSpanChildren = <InlineSpan>[];

    for (int i = 0; i < mentionRange.length; i++) {
      List<int> range = mentionRange[i];
      if (range.last > text.length) {
        textSpanChildren.add(TextSpan(
          text: text.substring(range.last),
          style: style,
        ));
        break;
      }

      if (i == 0) {
        textSpanChildren.add(TextSpan(
          text: text.substring(0, range[0]),
          style: style,
        ));
      } else {
        textSpanChildren.add(TextSpan(
          text: text.substring(mentionRange[i - 1][1], range[0]),
          style: style,
        ));
      }

      textSpanChildren.add(
        TextSpan(
          text: text.substring(range[0], range[1]),
          style: textStyle,
          recognizer: (TapGestureRecognizer()
            ..onTap = () => onTap?.call(
                  atList[int.parse(text.substring(range[0] + 1, range[1])) - 1]
                      .userId,
                )),
        ),
      );

      if (i == mentionRange.length - 1) {
        textSpanChildren.add(TextSpan(
          text: text.substring(range[1]),
          style: style,
        ));
      }
    }
    return TextSpan(style: style, children: textSpanChildren);
  }
}
