import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool expandEnable;
  final Function? onLongTapCallback;

  const ExpandableText({
    required this.text,
    required this.style,
    this.expandEnable = true,
    this.onLongTapCallback,
    super.key,
  });

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  Widget? texts;

  @override
  Widget build(BuildContext context)
  {
    TextSpan ts = TextSpan(
      style: widget.style,
      children: [
        ...buildSpanList(
          widget.text,
          isLinkMsg: true,
          launchLink: (String text){
            objectMgr.momentMgr.onLinkOpen(text);
          },
          textColor: colorTextPrimary,
        ),
      ],
    );

    Widget texts =  Text.rich(
      ts,
      maxLines: _isExpanded || !widget.expandEnable ? null : 5,
    );

    return
      GestureDetector(
        onLongPress: (){
          if(widget.onLongTapCallback!= null) {
            widget.onLongTapCallback!();
          }
        },
        child:  LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints)
          {
            final textPainter = TextPainter(
              text: ts,
              maxLines: widget.expandEnable?5:null,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            if (textPainter.didExceedMaxLines) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  texts,
                  if (widget.expandEnable)
                    Container(
                      margin: const EdgeInsets.only(
                        top: 6.0,
                        bottom: 2.0,
                      ),
                      child: InkWell(
                        child: Text(
                          _isExpanded
                              ? localized(momentTextCollapse)
                              : localized(momentTextExpand),
                          style: jxTextStyle.textStyle17(
                            color: momentThemeColor,
                          ),
                        ),
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                      ),
                    ),
                ],
              );
            } else {
              return texts;
            }
          },
        ),
      );
  }

  List<InlineSpan> buildSpanList(String text, {
        bool isSender = false,
        bool isLinkMsg = false,
        Function(String text)? launchLink,
        Function(String text)? openLinkPopup,
        Color? textColor,
        TextStyle? style,
      })
  {
    text = text.replaceAll(RegExp(r'\u200B'), '');

    /// 匹配链接
    Iterable<RegExpMatch> matches = Regular.extractLink(
      text,
      isLinkMsg: isLinkMsg,
    );

    Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(text);

    if (matches.isNotEmpty || emojiMatches.isNotEmpty) {
      /// 最终文本
      List<RegexTextModel> spanMapsList = [];

      /// 开始和结尾的文本
      List<RegexTextModel> firstLastSpanMapsList = [];

      /// 普通文本
      List<RegexTextModel> textSpanMapsList = [];

      ///--------------------------处理特别文本----------------------------///

      /// 检查链接文本
      if (matches.isNotEmpty)
      {
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
          // pdebug(e.toString());
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
            BuildTextUtil.buildText(
              '\n',
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: false,
            ),
          );
          subText = subText.substring(1);
        }

        if(spanMapsList[i].type == RegexTextType.link.value) {
          /// 链接文本
          RegExp regExp = RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
          subText = subText.replaceAll(regExp, '');
          String title = subText.length > 30 ? '${subText.substring(0, 30)}...' : subText;
          spanList.add(
            BuildTextUtil.buildText(
              title,
              isSender ? bubblePrimary : themeColor,
              isLink: true,
              isSender: isSender,
              callback: () => launchLink?.call(subText),
              // longPressCallback: () => openLinkPopup?.call(subText),
              isEmojiOnly: false,
              style:TextStyle(
                fontSize: MFontSize.size17.value,
                fontFamily: appFontFamily,
                fontWeight:  MFontWeight.bold4.value,
                color: const Color(0xFF1D49A7),
                height: 1.29,
                decoration: TextDecoration.none,
              ),
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.emoji.value) {
          /// 表情文本
          /// make emoji with text bigger on iOS.
          double size = MFontSize.size17.value;
          if (Platform.isIOS) size = MFontSize.size20.value;
          spanList.add(
            BuildTextUtil.buildText(
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
            BuildTextUtil.buildText(
              subText,
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: false,
              style: style,
            ),
          );
        }
      }
      return spanList;
    } else {
      /// 普通文本
      return [
        BuildTextUtil.buildText(
          text,
          textColor ?? colorTextPrimary,
          isSender: isSender,
          isEmojiOnly: false,
          style: style,
        ),
      ];
    }
  }
}
