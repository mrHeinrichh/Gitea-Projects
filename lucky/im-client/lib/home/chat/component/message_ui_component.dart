import 'dart:convert';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/components/chat_cell_setting_view.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/component/message_ui_base.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views_desktop/component/chat_option_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

import '../../../im/model/mention_model.dart';
import '../../../managers/utils.dart';
import '../../../utils/regular.dart';

class MessageUIComponent extends MessageUIBase<ChatListController> {
  final double _maxChatCellHeight = 81;
  late final int index;

  MessageUIComponent(
      {super.key,
      required super.chat,
      required super.searchText,
      required super.message}){
        index = controller.messageList.indexOf(message);
      }

  @override
  Widget build(BuildContext context) {
    final Widget widgetChild = Column(
      children: [
        createItemView(context, index),
        if (index != controller.messageList.length - 1)
          Padding(
            padding: jxDimension.messageCellDividerPadding(),
            child: const CustomDivider(),
          )
      ],
    );
    return ColoredBox(
      color: Colors.white,
      child: objectMgr.loginMgr.isDesktop
          ? widgetChild
          : GestureDetector(
              onTap: () async {
                // controller.clearSearching(isUnfocus: true);
                controller.searchFocus.unfocus();
                Routes.toChat(chat: chat);
              },
              child: widgetChild,
            ),
    );
  }

  @override
  Widget createItemView(BuildContext context, int index) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    final childWidget = Obx(() {
      final isOnline = objectMgr.userMgr.friendOnline[chat.friend_id] ?? false;
      final enableAudio = chat.enableAudioChat.value;
      Widget child = Container(
        height: _maxChatCellHeight,
        padding: jxDimension.messageCellPadding(),
        child: Row(
          children: <Widget>[
            /// 頭像
            Container(
              margin: const EdgeInsets.only(
                left: 2, //the another 8 is on parent.
                right: 10,
              ),
              child: Stack(
                children: [
                  buildHeadView(context),
                  if (isOnline && !enableAudio)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: JXColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                        ),
                        height: 16,
                        width: 16,
                      ),
                    )
                  else if (chat.autoDeleteEnabled && !enableAudio)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        height: 24,
                        width: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/icon_autodelete.png',
                              fit: BoxFit.contain,
                            ),
                            Text(
                              parseAutoDeleteInterval(chat.autoDeleteInterval),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24 * 0.4,
                                fontWeight:MFontWeight.bold6.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (enableAudio)

                    ///這邊做個判斷要不要出現語音icon
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: SvgPicture.asset(
                        'assets/svgs/agora_mark_icon.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  titleBuilder(),
                  contentBuilder(),
                ],
              ),
            ),
          ],
        ),
      );

      if (isDesktop) {
        child = GestureDetector(
          onSecondaryTapDown: (details) {
            DesktopGeneralDialog(
              context,
              color: Colors.transparent,
              widgetChild: ChatOptionMenu(
                offset: details.globalPosition,
                chat: chat,
              ),
            );
          },
          child: MouseRegion(
            onEnter: (enterEvent) {
              controller.mousePosition = enterEvent.position;
            },
            onHover: (hoverEvent) {
              controller.mousePosition = hoverEvent.position;
            },
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: (index == controller.selectedCellIndex.value)
                    ? JXColors.desktopChatBlue
                    : Colors.white,
                disabledBackgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                surfaceTintColor: JXColors.outlineColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0.0,
              ),
              onPressed: () {
                controller.selectedCellIndex.value = index;
                if (!controller.isCTRLPressed()) {
                  Routes.toChatDesktop(context: context, chat: chat, selectedMsgIds: [message]);
                } else {
                  DesktopGeneralDialog(
                    context,
                    color: Colors.transparent,
                    widgetChild: ChatOptionMenu(
                      offset: controller.mousePosition,
                      chat: chat,
                    ),
                  );
                }
              },
              child: child,
            ),
          ),
        );
      } else {
        child = Container(
          constraints:
              isDesktop ? null : BoxConstraints(maxHeight: _maxChatCellHeight),
          child: OverlayEffect(
            child: child,
          ),
        );
      }

      return child;
    });

    return isDesktop
        ? childWidget
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              controller.searchFocus.unfocus();
              Routes.toChat(chat: chat, selectedMsgIds: [message]);
            },
            child: childWidget,
          );
  }

  @override
  Widget buildHeadView(BuildContext context) {
    return CustomAvatar(
      uid: (chat.isGroup) ? chat.id : chat.friend_id,
      size: jxDimension.chatListAvatarSize(),
      headMin: Config().headMin,
      isGroup: chat.isGroup,
      fontSize: 24.0,
    );
  }

  @override
  Widget contentBuilder() {
    final String text = getMessageText(this.message);
    final Widget messageThumbnail = getMessageThumbnail(this.message);
    final Color textColor = (objectMgr.loginMgr.isDesktop && controller.selectedCellIndex == index)
        ? Colors.white
        : JXColors.secondaryTextBlack;
    final spanList = getSpanList(text, searchText,textColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        messageThumbnail,
        Expanded(
          child: RichText(
            text: TextSpan(
              style: jxTextStyle.chatCellContentStyle(color: textColor),
              children: spanList,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget messageCellTime(Message message) {
    return Text(
      message.create_time > 0
          ? FormatTime.chartTime(
              message.create_time,
              true,
              todayShowTime: true,
              dateStyle: DateStyle.MMDDYYYY,
            )
          : '',
      style: jxTextStyle
          .textStyle14(color: JXColors.secondaryTextBlack)
          .useSystemChineseFont(),
    );
  }

  @override
  Widget titleBuilder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ChatCellSettingView(chat: chat,index: index),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // ChatCellTimeText(chat: chat!),
              messageCellTime(this.message),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget getMessageThumbnail(Message message) {
    if (message.typ == messageTypeImage || message.typ == messageTypeFile) {
      return const Padding(
        padding: EdgeInsets.only(right: 5),
        child: SizedBox(
          height: 15,
          width: 15,
          child: SizedBox(),
        ),
      );

    } else {
      return const SizedBox();
    }
  }

  List<InlineSpan> getSpanList(String text, String? regexText, Color textColor) {
    List<InlineSpan> spanList = List.empty(growable: true);

    if (regexText != '') {
      try {
        RegExp regex = RegExp(regexText!);

        /// special case when search "."
        if (regexText == "."){
          regex = RegExp(r'\.');
        }

        Iterable<Match> matches = regex.allMatches(text);
        Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);

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

        /// 最终文本
        List<RegexTextModel> spanMapsList = [];

        /// 开始和结尾的文本
        List<RegexTextModel> firstLastSpanMapsList = [];

        /// 普通文本
        List<RegexTextModel> textSpanMapsList = [];

        ///--------------------------处理特别文本----------------------------///

        /// 检查搜索文本
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

        if (matches.isNotEmpty) {
          matches.forEach((match) {
            RegexTextModel spanMap = RegexTextModel(
              type: RegexTextType.search.value,
              text: regexText,
              start: match.start,
              end: match.end,
            );
            spanMapsList.add(spanMap);
          });

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
            if (i != spanMapsList.length - 1) {
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
            }
          }
          spanMapsList.addAll(textSpanMapsList);

          /// 排序最终文本
          spanMapsList.sort((a, b) => (a.start).compareTo(b.start));
        }

        ///-------------------------- 处理字体样本 ----------------------------///
        for (int i = 0; i < spanMapsList.length; i++) {
          String subText = spanMapsList[i].text;
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
              TextSpan(
                text:  '@$name',
                style: jxTextStyle.chatCellContentStyle(),
              ),
            );
          }
          else if (spanMapsList[i].type == RegexTextType.search.value) {
            spanList.add(
              TextSpan(
                text: subText,
                style: jxTextStyle.chatCellContentStyle(color: accentColor),
              ),
            );
          } else {
            /// 普通文本
            spanList.add(
              TextSpan(
                text: subText,
                style: jxTextStyle.chatCellContentStyle(color:textColor),
              ),
            );
          }
        }
      } catch (e) {
        spanList.add(
          TextSpan(
            text: text,
            style: jxTextStyle.chatCellContentStyle(color:textColor),
          ),
        );
      }
    } else {
      spanList.add(
        TextSpan(
          text: text,
          style: jxTextStyle.chatCellContentStyle(color:textColor),
        ),
      );
    }
    return spanList;
  }

  @override
  String getMessageText(Message message) {
    String text = "";
    switch (message.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        text = message.decodeContent(cl: MessageText.creator).text;
        break;
      case messageTypeImage:
        MessageImage imageMessage = message.decodeContent(cl: MessageImage.creator);
        text =  imageMessage.caption;
        break;
      case messageTypeFile:
        MessageFile fileMessage = message.decodeContent(cl: MessageFile.creator);
        text =  fileMessage.caption;
        break;
      case messageTypeVideo:
        MessageVideo videoMessage = message.decodeContent(cl: MessageVideo.creator);
        text = videoMessage.caption;
        break;
      case messageTypeNewAlbum:
        NewMessageMedia albumMessage = message.decodeContent(cl: NewMessageMedia.creator);
        text = albumMessage.caption;
        break;
      default:
        break;
    }
    return text;
  }
}
