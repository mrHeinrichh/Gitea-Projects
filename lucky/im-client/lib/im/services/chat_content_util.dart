import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

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
  }) {
    if (isMention) {
      return TextSpan(
        text: text,
        style: jxTextStyle.normalBubbleText(
          isSender
              ? JXColors.chatBubbleMeHyperLink
              : JXColors.chatBubbleSenderHyperLink,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => callback?.call(),
      );
    }

    if (isLink) {
      return WidgetSpan(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => callback?.call(),
            onLongPress: () => longPressCallback?.call(),
            child: OverlayEffect(
              overlayColor: isSender
                  ? JXColors.chatBubbleMeHyperLink.withOpacity(0.2)
                  : JXColors.chatBubbleSenderHyperLink.withOpacity(0.2),
              child: Text(
                text,
                style: jxTextStyle.normalBubbleText(
                  isSender
                      ? JXColors.chatBubbleMeHyperLink
                      : JXColors.chatBubbleSenderHyperLink,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (isPhone) {
      return WidgetSpan(
        child: GestureDetector(
          onLongPress: () => longPressCallback?.call(),
          child: OverlayEffect(
            overlayColor: isSender
                ? JXColors.chatBubbleMeHyperLink.withOpacity(0.2)
                : JXColors.chatBubbleSenderHyperLink.withOpacity(0.2),
            child: Text(
              text,
              style: jxTextStyle.normalBubbleText(
                isSender
                    ? JXColors.chatBubbleMeHyperLink
                    : JXColors.chatBubbleSenderHyperLink,
              ),
            ),
          ),
        ),
      );
    }
    double? size = isEmojiOnly ? fontSizeWithEmojiLength(text.length) : null;
    if (fontSize != null) {
      size = fontSize; //有外部传入的字体大小，优先使用外部传入的
    }
    return TextSpan(
      text: text,
      style: jxTextStyle.normalBubbleText(color).copyWith(
            fontSize: size,
            // fontFamily: 'emoji'
          ),
    );
  }

  /// 根据纯表情的数量来决定字体大小 注意每个表情占length为2
  static double fontSizeWithEmojiLength(int length) {
    if (length == 2) {
      return 120.0;
    } else if (length == 4) {
      return 84.0;
    } else if (length == 6) {
      return 66.0;
    } else if (length == 8) {
      return 48.0;
    } else if (length == 10) {
      return 30.0;
    } else if (length == 12) {
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
    bool isReply = false, //回覆的訊息
  }) {
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
            atUser.map<MentionModel>((e) => MentionModel.fromJson(e)).toList());
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
        mentionMatches.forEach((match) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.mention.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        });
      }

      /// 检查链接文本
      if (matches.isNotEmpty) {
        matches.forEach((match) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.link.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        });
      }

      /// 检查电话号码文本
      if (phoneMatches.isNotEmpty) {
        phoneMatches.forEach((match) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.number.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        });
      }

      /// 检查表情文本
      if (emojiMatches.isNotEmpty) {
        emojiMatches.forEach((match) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.emoji.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        });
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
              textColor ?? JXColors.chatBubbleMeTextColor,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
          subText = subText.substring(1);
        }

        if (spanMapsList[i].type == RegexTextType.mention.value) {
          /// @文本
          String uidStr = Regular.extractDigit(subText ?? '')?.group(0) ?? '';
          int uid = int.parse(uidStr);
          String name = objectMgr.userMgr
              .getUserTitle(objectMgr.userMgr.getUserById(uid));

          if (name.isEmpty) {
            final MentionModel? model = mentionList
                .firstWhereOrNull((mention) => mention.userId == uid);
            if (model == null) {
              name = uidStr.toString();
            } else {
              name = model.userName;
            }
          }
          spanList.add(
            buildText(
              '@$name',
              isSender
                  ? JXColors.chatBubbleMeAccentColor
                  : JXColors.chatBubbleSenderHyperLink,
              isMention: true,
              isSender: isSender,
              callback: () =>
                  !objectMgr.userMgr.isMe(uid) ? onMentionTap?.call(uid) : null,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.link.value) {
          /// 链接文本

          RegExp regExp = new RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
          subText = subText.replaceAll(regExp, '');

          spanList.add(
            buildText(
              subText,
              isSender
                  ? JXColors.chatBubbleMeAccentColor
                  : JXColors.chatBubbleSenderHyperLink,
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
              isSender
                  ? JXColors.chatBubbleMeAccentColor
                  : JXColors.chatBubbleSenderHyperLink,
              isPhone: true,
              isSender: isSender,
              longPressCallback: () => openPhonePopup?.call(subText),
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.emoji.value) {
          /// 表情文本
          spanList.add(
            buildText(
              subText,
              isSender
                  ? JXColors.chatBubbleMeAccentColor
                  : JXColors.chatBubbleSenderHyperLink,
              isSender: isSender,
              isEmojiOnly: false,
              fontSize: MFontSize.size16.value,
            ),
          );
        } else {
          /// 普通文本
          spanList.add(
            buildText(
              subText,
              textColor ?? JXColors.primaryTextBlack,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        }
      }
      return spanList;
    } else {
      /// 普通文本
      return [
        buildText(text, textColor ?? Colors.black,
            isSender: isSender,
            isEmojiOnly: isEmojiOnly,
            fontSize: isReply ? MFontSize.size17.value : null),
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
        style: TextStyle(
          color: color666666,
          fontSize: 10,
        ),
      ),
    );
  }
}
