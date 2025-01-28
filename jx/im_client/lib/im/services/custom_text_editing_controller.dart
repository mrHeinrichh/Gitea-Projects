import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/input_content_util.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
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
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (mentionRange.isEmpty) {
      if (Platform.isIOS) {
        Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(text);
        if (emojiMatches.isNotEmpty) {
          /// 包含表情，并且是ios
          return _buildIosTextSpan(
            context: context,
            style: style,
            withComposing: withComposing,
            emojiMatches: emojiMatches,
            text: text,
          );
        }
      }
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final TextStyle? textStyle = style?.copyWith(
      color: themeColor,
      fontSize: MFontSize.size17.value,
    );

    final textSpanChildren = <InlineSpan>[];

    // 生成富文本
    for (int i = 0; i < mentionRange.length; i++) {
      List<int> range = mentionRange[i];
      if (range.last > text.length) {
        textSpanChildren.add(
          TextSpan(
            text: text.substring(range.last),
            style: style,
          ),
        );
        break;
      }

      if (i == 0) {
        String str = text.substring(0, range[0]);
        Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(str);
        if (Platform.isIOS && emojiMatches.isNotEmpty) {
          textSpanChildren.add(
            _buildIosTextSpan(
              context: context,
              style: style,
              withComposing: withComposing,
              emojiMatches: emojiMatches,
              text: str,
            ),
          );
        } else {
          textSpanChildren.add(
            TextSpan(
              text: str,
              style: style,
            ),
          );
        }
      } else {
        String str = text.substring(mentionRange[i - 1][1], range[0]);
        Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(str);
        if (Platform.isIOS && emojiMatches.isNotEmpty) {
          textSpanChildren.add(
            _buildIosTextSpan(
              context: context,
              style: style,
              withComposing: withComposing,
              emojiMatches: emojiMatches,
              text: str,
            ),
          );
        } else {
          textSpanChildren.add(
            TextSpan(
              text: str,
              style: style,
            ),
          );
        }
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
        String str = text.substring(range[1]);
        Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(str);
        if (Platform.isIOS && emojiMatches.isNotEmpty) {
          textSpanChildren.add(
            _buildIosTextSpan(
              context: context,
              style: style,
              withComposing: withComposing,
              emojiMatches: emojiMatches,
              text: str,
            ),
          );
        } else {
          textSpanChildren.add(
            TextSpan(
              text: str,
              style: style,
            ),
          );
        }
      }
    }
    return TextSpan(style: style, children: textSpanChildren);
  }

  /// 处理包含表情的文本
  TextSpan _buildIosTextSpan({
    required BuildContext context,
    required TextStyle? style,
    required bool withComposing,
    required Iterable<RegExpMatch> emojiMatches,
    required String text,
  }) {
    return InputUtil.buildInputIosEmojiContent(
      context: context,
      style: style,
      withComposing: withComposing,
      emojiMatches: emojiMatches,
      text: text,
    );
  }
}
