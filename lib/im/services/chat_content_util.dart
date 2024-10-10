import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class BuildTextUtil {
  static InlineSpan buildText(
    String text,
    Color color, {
    bool isMention = false,
    bool isLink = false,
    bool isPhone = false,
    bool isSender = false,
    bool isEmojiOnly = false,
    Function? callback,
    Function? longPressCallback,
    double? fontSize,
    TextStyle? style,
  }) {
    if (isMention) {
      return TextSpan(
        text: text,
        style: jxTextStyle.normalBubbleText(
          const Color(0xFF1D49A7),
        ),
        recognizer: TapGestureRecognizer()..onTap = () => callback?.call(),
      );
    }

    if (isLink) {
      return TextSpan(
        text: handleText(text),
        style: jxTextStyle.normalBubbleText(const Color(0xFF1D49A7)),
        recognizer: TapGestureRecognizer()..onTap = () => callback?.call(),
      );
    }

    if (isPhone) {
      return TextSpan(
        text: text,
        style: jxTextStyle.normalBubbleText(const Color(0xFF1D49A7)),
        recognizer: TapGestureRecognizer()
          ..onTap = () => longPressCallback?.call(),
      );
    }
    double? size = isEmojiOnly ? fontSizeWithEmojiLength(text) : null;
    if (isEmojiOnly && isSender) {
      return TextSpan(
        text: text,
        style: jxTextStyle.normalBubbleText(color).copyWith(fontSize: size),
      );
    }

    if (fontSize != null) {
      size = fontSize; //有外部传入的字体大小，优先使用外部传入的
    }

    return TextSpan(
      text: text,
      style:
          style ?? jxTextStyle.normalBubbleText(color).copyWith(fontSize: size),
    );
  }

  /// 根据纯表情的数量来决定字体大小 注意每个表情占length为2
  static double fontSizeWithEmojiLength(String text) {
    final matches = EmojiParser.REGEX_EMOJI.allMatches(text);
    final length = matches.length;
    if (length == 1) {
      return 84.0;
    } else if (length == 2) {
      return 66.0;
    } else if (length == 3) {
      return 48.0;
    } else if (length == 4) {
      return 30.0;
    } else if (length == 5) {
      return 24.0;
    } else if (length == 6) {
      return 24.0;
    }
    return 24.0; // Default value for unspecified lengths
  }

  static List<InlineSpan> buildSpanList(
    Message message,
    String text, {
    bool isSender = false,
    bool isEmojiOnly = false,
    Function(String text)? launchLink,
    Function(int uid)? onMentionTap,
    Function(String text)? openLinkPopup,
    Function(String text)? openPhonePopup,
    Color? textColor,
    TextStyle? style,
    bool isReply = false, //回覆的訊息
    int? groupId,
  }) {
    // if (isMarkdown(text)) {
    //   return [
    //     WidgetSpan(
    //       child: MarkdownBody(
    //         data: text,
    //         onTapLink: (String text, String? href, String title) {
    //           if ((href ?? "").isNotEmpty) {
    //             launchLink?.call(href!);
    //           }
    //         },
    //       ),
    //     ),

    //   ];
    // }

    /// 匹配链接
    Iterable<RegExpMatch> matches = Regular.extractLink(text);
    Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);
    Iterable<RegExpMatch> phoneMatches = Regular.extractPhoneNumber(text);
    Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(text);
    if (isEmojiOnly) {
      //emojiMatches 只用来处理表情和其他混合的时候，如果是纯表情 不需要emojiMatches处理
      emojiMatches = [];
    }

    List<MentionModel> mentionList = <MentionModel>[];

    if (message.atUser.isNotEmpty) {
      mentionList.addAll(message.atUser);
    } else if (message.data.containsKey('at_users') &&
        notBlank(message.getValue('at_users')) &&
        message.getValue('at_users') is String) {
      final atUser = jsonDecode(message.getValue('at_users'));
      if (notBlank(atUser) && atUser is List) {
        mentionList.addAll(
          atUser.map<MentionModel>((e) => MentionModel.fromJson(e)).toList(),
        );
      }
    }

    if (matches.isNotEmpty ||
        mentionMatches.isNotEmpty ||
        phoneMatches.isNotEmpty ||
        emojiMatches.isNotEmpty) {
      /// 最终文本
      List<RegexTextModel> spanMapsList = [];

      /// 开始和结尾的文本
      List<RegexTextModel> firstLastSpanMapsList = [];

      /// 普通文本
      List<RegexTextModel> textSpanMapsList = [];

      ///--------------------------处理特别文本----------------------------///

      /// 检查@文本
      if (mentionMatches.isNotEmpty) {
        for (var match in mentionMatches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.mention.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 检查链接文本
      if (matches.isNotEmpty) {
        for (var match in matches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.link.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 检查电话号码文本
      if (phoneMatches.isNotEmpty) {
        for (var match in phoneMatches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.number.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 检查表情文本
      if (emojiMatches.isNotEmpty) {
        for (var match in emojiMatches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.emoji.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 排序特别文本（链接，@，电话号码）
      spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

      ///-------------------------- 处理开头和结尾文本----------------------------///
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
      if (spanMapsList.last.end < text.length) {
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

      ///-------------------------- 处理最终文本 ----------------------------///
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
          pdebug(e.toString());
        }
      }
      spanMapsList.addAll(textSpanMapsList);

      /// 排序最终文本
      spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

      ///-------------------------- 处理字体样本 ----------------------------///
      List<InlineSpan> spanList = List.empty(growable: true);
      for (int i = 0; i < spanMapsList.length; i++) {
        String subText = spanMapsList[i].text;
        // Check if the text starts with a newline character
        bool startsWithNewline = subText.startsWith('\n');

        if (startsWithNewline) {
          spanList.add(
            buildText(
              '\n',
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
          subText = subText.substring(1);
        }

        if (spanMapsList[i].type == RegexTextType.mention.value) {
          /// @文本
          String uidStr = Regular.extractDigit(subText)?.group(0) ?? '';
          int uid = int.parse(uidStr);

          final MentionModel? model =
              mentionList.firstWhereOrNull((mention) => mention.userId == uid);

          String name = '';

          if (uid == 0 && model != null && model.role == Role.all) {
            name = localized(mentionAll);
          } else {
            if (uid == 0) {
              name = localized(mentionAll);
            } else {
              name = objectMgr.userMgr.getUserTitle(
                  objectMgr.userMgr.getUserById(uid),
                  groupId: groupId);
            }
          }

          if (name.isEmpty) {
            if (model == null) {
              name = uidStr.toString();
            } else {
              name = model.userName;
            }
          }
          spanList.add(
            buildText(
              '@$name',
              const Color(0xFF1D49A7),
              isMention: true,
              isSender: isSender,
              callback: () => !objectMgr.userMgr.isMe(uid) && uid != 0
                  ? onMentionTap?.call(uid)
                  : null,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.link.value) {
          /// 链接文本

          RegExp regExp = RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
          subText = subText.replaceAll(regExp, '');

          spanList.add(
            buildText(
              subText,
              isSender ? bubblePrimary : themeColor,
              isLink: true,
              isSender: isSender,
              callback: () => launchLink?.call(subText),
              longPressCallback: () => openLinkPopup?.call(subText),
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.number.value) {
          /// 电话号码
          spanList.add(
            buildText(
              subText,
              isSender ? bubblePrimary : themeColor,
              isPhone: true,
              isSender: isSender,
              longPressCallback: () => openPhonePopup?.call(subText),
              isEmojiOnly: isEmojiOnly,
              style: style,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.emoji.value) {
          /// 表情文本
          /// make emoji with text bigger on iOS.
          double size = MFontSize.size17.value;
          if (Platform.isIOS) size = MFontSize.size20.value;
          spanList.add(
            buildText(
              subText,
              isSender ? bubblePrimary : themeColor,
              isSender: isSender,
              isEmojiOnly: false,
              fontSize: size,
            ),
          );
        } else {
          /// 普通文本
          spanList.add(
            buildText(
              subText,
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
              style: style,
            ),
          );
        }
      }
      return spanList;
    } else {
      /// 普通文本
      return [
        buildText(
          text,
          textColor ?? colorTextPrimary,
          isSender: isSender,
          isEmojiOnly: isEmojiOnly,
        ),
      ];
    }
  }

  static Widget buildEditState(String text, {bool isSender = false}) {
    return Positioned(
      left: isSender ? null : -34.w,
      bottom: 2.w,
      right: isSender ? -34.w : null,
      child: Text(
        text,
        style: const TextStyle(
          color: colorGrey,
          fontSize: 10,
        ),
      ),
    );
  }
}

bool isMarkdown(String text) {
  // 定义一些常见的Markdown模式
  final patterns = [
    RegExp(r'\*\*.*\*\*'), // 粗体
    RegExp(r'\*.*\*'), // 斜体
    RegExp(r'\[.*\]\(.*\)'), // 链接
    RegExp(r'`.*`'), // 行内代码
    RegExp(r'#{1,6} '), // 标题
    RegExp(r'!\[.*\]\(.*\)'), // 图片
    RegExp(r'> .*'), // 引用
    RegExp(r'(\d+\.) .*'), // 有序列表
    RegExp(r'- .*'), // 无序列表
    RegExp(r'\n---\n'), // 分隔线
    RegExp(r'\n\*\*\*\n'), // 分隔线
  ];

  // 检查文字是否匹配任意一个模式
  // 额外规则 匹配两次才处理为markdown
  int matchCount = 0;
  for (final pattern in patterns) {
    if (pattern.hasMatch(text)) {
      matchCount++;
    }
  }

  return matchCount >= 2;
}
