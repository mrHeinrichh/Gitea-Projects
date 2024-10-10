import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class InputUtil {
  /// 处理输入框表情文本
  static TextSpan buildInputIosEmojiContent({
    required BuildContext context,
    required TextStyle? style,
    bool? withComposing,
    required Iterable<RegExpMatch> emojiMatches,
    required String text,
  }) {
    int len = text.length;

    /// 最终文本
    List<RegexTextModel> spanMapsList = [];

    /// 开始和结尾的文本
    List<RegexTextModel> firstLastSpanMapsList = [];
    for (var match in emojiMatches) {
      RegexTextModel spanMap = RegexTextModel(
        type: RegexTextType.emoji.value,
        text: text.substring(match.start, match.end),
        start: match.start,
        end: match.end,
      );
      spanMapsList.add(spanMap);
    }

    /// 排序特别文本（链接，@，电话号码）
    spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

    /// 如果开头字不是特别文本，补上开头的文本
    if (spanMapsList.first.start > 0) {
      RegexTextModel spanMap = RegexTextModel(
        type: RegexTextType.text.value,
        text: text.substring(0, spanMapsList.first.start),
        start: 0,
        end: spanMapsList.first.start,
      );
      firstLastSpanMapsList.add(spanMap);
    }

    /// 如果结尾字不是特别文本，补上结尾的文本
    if (spanMapsList.last.end < len) {
      RegexTextModel spanMap = RegexTextModel(
        type: RegexTextType.text.value,
        text: text.substring(spanMapsList.last.end, text.length),
        start: spanMapsList.last.end,
        end: text.length,
      );
      firstLastSpanMapsList.add(spanMap);
    }
    spanMapsList.addAll(firstLastSpanMapsList);

    /// 排序开头结尾文本
    spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

    /// 普通文本
    List<RegexTextModel> textSpanMapsList = [];
    for (int i = 0; i < spanMapsList.length; i++) {
      try {
        int firstEnd = spanMapsList[i].end;
        if (i + 1 == spanMapsList.length) break;
        int secondStart = spanMapsList[i + 1].start;

        /// 如果中间字不是特别文本，补上中间的文本
        if (secondStart != firstEnd) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.text.value,
            text: text.substring(firstEnd, secondStart),
            start: firstEnd,
            end: secondStart,
          );
          textSpanMapsList.add(spanMap);
        }
      } catch (e) {
        //throw e;
        // pdebug(e.toString());
      }
    }
    spanMapsList.addAll(textSpanMapsList);

    /// 排序最终文本
    spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

    List<InlineSpan> spanList = List.empty(growable: true);
    for (int i = 0; i < spanMapsList.length; i++) {
      String subText = spanMapsList[i].text;
      if (spanMapsList[i].type == RegexTextType.emoji.value) {
        /// 表情文本
        /// make emoji with text bigger on iOS.
        double size = MFontSize.size20.value;
        spanList.add(
          TextSpan(
            text: subText,
            style: style!.copyWith(
              fontSize: size,
            ),
          ),
        );
      } else {
        /// 普通文本
        spanList.add(
          TextSpan(text: subText, style: style),
        );
      }
    }
    return TextSpan(style: style, children: spanList);
  }

  static TextSpan buildContentTextSpan({
    required String text,
    TextStyle? style,
  }) {
    Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(text);
    style ??= jxTextStyle.chatCellContentStyle(
      color: colorTextSecondarySolid,
      fontSize: MFontSize.size17.value,
    );
    if (Platform.isIOS && emojiMatches.isNotEmpty) {
      return buildInputIosEmojiContent(
        context: Get.context!,
        text: text,
        emojiMatches: emojiMatches,
        style: style,
      );
    }
    return TextSpan(text: text, style: style);
  }
}
