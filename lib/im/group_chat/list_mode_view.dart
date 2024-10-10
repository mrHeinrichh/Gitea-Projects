import 'dart:convert';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/message_ui_base.dart';
import 'package:jxim_client/home/chat/components/chat_cell_setting_view.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/chat_option_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class ListModeView extends StatelessWidget {
  late final BaseChatController controller;

  ListModeView({super.key, required this.tag, required this.isGroupChat}) {
    if (isGroupChat) {
      controller = Get.find<GroupChatController>(tag: tag);
    } else {
      controller = Get.find<SingleChatController>(tag: tag);
    }
  }

  final String tag;
  final bool isGroupChat;

  double get userSearchHeight =>
      143.5 / (41 * controller.groupMemberList.toList().length.toDouble());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: -100.0,
      displacement: 0.0,
      onRefresh: () async => controller.onRefresh(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
            width: double.infinity,
            color: colorBackground,
            child: Text(
              localized(homeTabMessage),
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
            ),
          ),
          Flexible(
            child: Obx(
              () => Container(
                // color: Colors.white,
                child: controller.isTextTypeSearch.value
                    ? Container(
                        height: 1.sh,
                        color: Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount:
                              controller.searchedIndexList.toList().length,
                          itemBuilder: (BuildContext context, int index) {
                            Message message =
                                controller.searchedIndexList[index];
                            return ListModeMessageFactory.createComponent(
                              message: message,
                              searchText: controller.searchParam.value,
                              onTap: () {
                                controller.positioningMessage(
                                  message,
                                  index,
                                );
                              },
                              chatId: message.chat_id,
                            );
                          },
                        ),
                      )
                    : controller.groupMemberList.toList().length <= 3
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            reverse: true,
                            itemExtent: 41,
                            itemCount:
                                controller.groupMemberList.toList().length,
                            itemBuilder: (BuildContext context, int index) {
                              User user = controller.groupMemberList[index];
                              return _buildGroupMemberView(user);
                            },
                          )
                        : RotatedBox(
                            quarterTurns: 2,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  height: 41,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  height: 41 *
                                      controller.groupMemberList
                                          .toList()
                                          .length
                                          .toDouble(),
                                  child: DraggableScrollableSheet(
                                    initialChildSize: userSearchHeight >= 0.44
                                        ? userSearchHeight
                                        : 0.44,
                                    minChildSize: userSearchHeight >= 0.44
                                        ? userSearchHeight
                                        : 0.44,
                                    maxChildSize: 1,
                                    expand: false,
                                    builder:
                                        (_, ScrollController scrollController) {
                                      return ListView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: const ClampingScrollPhysics(),
                                        controller: scrollController,
                                        shrinkWrap: true,
                                        itemExtent: 41,
                                        itemCount: controller.groupMemberList
                                            .toList()
                                            .length,
                                        itemBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          User user =
                                              controller.groupMemberList[index];
                                          return RotatedBox(
                                            quarterTurns: 2,
                                            child: _buildGroupMemberView(
                                              user,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMemberView(User user) {
    return GestureDetector(
      onTap: () {
        controller.onSelectUser(user);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            CustomAvatar.user(
              user,
              size: 30,
              headMin: Config().headMin,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                children: [
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: colorBorder,
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NicknameText(
                        isTappable: false,
                        uid: user.id,
                        fontSize: MFontSize.size14.value,
                        fontWeight: MFontWeight.bold5.value,
                        overflow: TextOverflow.ellipsis,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Flexible(
                        child: Text(
                          "@${user.nickname}",
                          style: TextStyle(
                            fontSize: MFontSize.size14.value,
                            fontWeight: MFontWeight.bold4.value,
                            color: Colors.black.withOpacity(0.44),
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListMessageUIComponent extends MessageUIBase<ChatListController> {
  final double _maxChatCellHeight = 81;
  late final int index;
  final bool? isFromChatRoomListModeSearch;
  final GestureTapCallback? onTap;

  ListMessageUIComponent({
    super.key,
    required super.chat,
    required super.searchText,
    this.isFromChatRoomListModeSearch,
    required this.onTap,
    required super.message,
  }) {
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
          ),
      ],
    );
    return ColoredBox(
      color: Colors.white,
      child: GestureDetector(
        onTap: onTap,
        child: widgetChild,
      ),
    );
  }

  @override
  Widget createItemView(BuildContext context, int index) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    final childWidget = Obx(() {
      final isOnline = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
          localized(chatOnline);
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
                          color: colorGreen,
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
                            SvgPicture.asset(
                              'assets/svgs/icon_auto_delete.svg',
                              fit: BoxFit.contain,
                              height: 22,
                              width: 22,
                            ),
                            Text(
                              parseAutoDeleteInterval(chat.autoDeleteInterval),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24 * 0.4,
                                fontWeight: MFontWeight.bold6.value,
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
            desktopGeneralDialog(
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
                    ? colorDesktopChatBlue
                    : Colors.white,
                disabledBackgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                surfaceTintColor: colorBorder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0.0,
              ),
              onPressed: () {
                controller.selectedCellIndex.value = index;
                if (!controller.isCTRLPressed()) {
                  Routes.toChat(
                    chat: chat,
                    selectedMsgIds: [message],
                  );
                } else {
                  desktopGeneralDialog(
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

    return childWidget;
  }

  @override
  Widget buildHeadView(BuildContext context) {
    if (chat.isSpecialChat) {
      if (chat.isSystem) {
        return SystemMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        );
      } else if (chat.isSaveMsg) {
        return SavedMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        );
      } else {
        return SecretaryMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        );
      }
    } else {
      return CustomAvatar.chat(
        chat,
        size: jxDimension.chatListAvatarSize(),
        headMin: Config().headMin,
        fontSize: 24.0,
        onTap: onTap,
      );
    }
  }

  @override
  Widget contentBuilder() {
    final String text = getMessageText(message);
    final Widget messageThumbnail = getMessageThumbnail(message);
    final Color textColor = (objectMgr.loginMgr.isDesktop &&
            controller.selectedCellIndex.value == index)
        ? Colors.white
        : colorGrey; // colorTextSecondary
    final spanList = getSpanList(text, searchText, textColor);

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
          .textStyle14(color: colorTextSecondary)
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
            child: ChatCellSettingView(chat: chat, index: index),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // ChatCellTimeText(chat: chat!),
              messageCellTime(message),
            ],
          ),
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

  List<InlineSpan> getSpanList(
    String text,
    String? regexText,
    Color textColor,
  ) {
    List<InlineSpan> spanList = List.empty(growable: true);
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
    if (regexText != '') {
      try {
        RegExp regex = RegExp(regexText!, caseSensitive: false);

        /// special case when search "."
        if (regexText == ".") {
          regex = RegExp(r'\.');
        }

        Iterable<Match> matches = regex.allMatches(text);
        Iterable<RegExpMatch> mentionMatches =
            Regular.extractSpecialMention(text);

        /// 最终文本
        List<RegexTextModel> spanMapsList = [];

        /// 开始和结尾的文本
        List<RegexTextModel> firstLastSpanMapsList = [];

        /// 普通文本
        List<RegexTextModel> textSpanMapsList = [];

        ///--------------------------处理特别文本----------------------------///

        /// 检查搜索文本
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

        if (matches.isNotEmpty) {
          for (var match in matches) {
            RegexTextModel spanMap = RegexTextModel(
              type: RegexTextType.search.value,
              text: text.substring(match.start, match.end),
              start: match.start,
              end: match.end,
            );
            spanMapsList.add(spanMap);
          }

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
            String uidStr = Regular.extractDigit(subText)?.group(0) ?? '';
            int uid = int.parse(uidStr);
            String name;
            if (uid == 0) {
              name = localized(mentionAll);
            } else {
              name = objectMgr.userMgr
                  .getUserTitle(objectMgr.userMgr.getUserById(uid));
            }

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
                text: '@$name',
                style: jxTextStyle.chatCellContentStyle(),
              ),
            );
          } else if (spanMapsList[i].type == RegexTextType.search.value) {
            spanList.add(
              TextSpan(
                text: subText,
                style: jxTextStyle.chatCellContentStyle(color: themeColor),
              ),
            );
          } else {
            /// 普通文本
            spanList.add(
              TextSpan(
                text: subText,
                style: jxTextStyle.chatCellContentStyle(color: textColor),
              ),
            );
          }
        }
      } catch (e) {
        spanList.add(
          TextSpan(
            text: text,
            style: jxTextStyle.chatCellContentStyle(color: textColor),
          ),
        );
      }
    } else {
      /// regexText 为空时的处理逻辑
      List<RegexTextModel> spanMapsList = [];

      /// 普通文本
      List<RegexTextModel> textSpanMapsList = [];

      /// 开始和结尾的文本
      List<RegexTextModel> firstLastSpanMapsList = [];
      Iterable<RegExpMatch> mentionMatches =
          Regular.extractSpecialMention(text);

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

        spanMapsList.sort((a, b) => a.start.compareTo(b.start));

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

        for (int i = 0; i < spanMapsList.length; i++) {
          String subText = spanMapsList[i].text;
          if (spanMapsList[i].type == RegexTextType.mention.value) {
            /// @文本
            String uidStr = Regular.extractDigit(subText)?.group(0) ?? '';
            int uid = int.parse(uidStr);
            String name;
            if (uid == 0) {
              name = localized(mentionAll);
            } else {
              name = objectMgr.userMgr
                  .getUserTitle(objectMgr.userMgr.getUserById(uid));
            }

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
                text: '@$name',
                style: jxTextStyle.chatCellContentStyle(),
              ),
            );
          } else {
            /// 普通文本
            spanList.add(
              TextSpan(
                text: subText,
                style: jxTextStyle.chatCellContentStyle(color: textColor),
              ),
            );
          }
        }
      } else {
        spanList.add(
          TextSpan(
            text: text,
            style: jxTextStyle.chatCellContentStyle(color: textColor),
          ),
        );
      }
    }
    return spanList;
  }

  @override
  String getMessageText(Message message, {String? searchText = ''}) {
    String text = "";
    switch (message.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        text = message.decodeContent(cl: MessageText.creator).text;
        break;
      case messageTypeImage:
        MessageImage imageMessage =
            message.decodeContent(cl: MessageImage.creator);
        text = imageMessage.caption;
        break;
      case messageTypeFile:
        MessageFile fileMessage =
            message.decodeContent(cl: MessageFile.creator);
        text = fileMessage.caption;
        break;
      case messageTypeVideo:
        MessageVideo videoMessage =
            message.decodeContent(cl: MessageVideo.creator);
        text = videoMessage.caption;
        break;
      case messageTypeNewAlbum:
        NewMessageMedia albumMessage =
            message.decodeContent(cl: NewMessageMedia.creator);
        text = albumMessage.caption;
        break;
      default:
        break;
    }
    return text;
  }
}

class ListModeMessageFactory {
  static Widget createComponent({
    required Message message,
    String? searchText,
    required int chatId,
    GestureTapCallback? onTap,
  }) {
    Widget child;

    Chat? chat = objectMgr.chatMgr.getChatById(chatId);
    if (chat == null) {
      return const SizedBox();
    }

    if (message.typ == messageTypeImage || message.typ == messageTypeFace) {
      child = _MessageUIImage(
        message: message,
        searchText: searchText,
        chat: chat,
        onTap: onTap,
      );
    } else if (message.typ == messageTypeFile) {
      child = _MessageUIFile(
        message: message,
        searchText: searchText,
        chat: chat,
        onTap: onTap,
      );
    } else if (message.typ == messageTypeText ||
        message.typ == messageTypeReply) {
      child = ListMessageUIComponent(
        chat: chat,
        searchText: searchText,
        message: message,
        onTap: onTap,
      );
    } else {
      child = _MessageUITypeName(
        chat: chat,
        searchText: searchText,
        message: message,
        onTap: onTap,
      );
    }

    return child;
  }
}

class _MessageUIImage extends ListMessageUIComponent {
  _MessageUIImage({
    super.onTap,
    required super.chat,
    required super.searchText,
    required super.message,
  });

  @override
  Widget getMessageThumbnail(Message message) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        height: 15,
        width: 15,
        child: RemoteImage(
          src: message.decodeContent(cl: MessageImage.creator()).url,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  @override
  String getMessageText(Message message, {String? searchText = ""}) {
    return message.decodeContent(cl: MessageImage.creator).caption;
  }
}

class _MessageUIFile extends ListMessageUIComponent {
  _MessageUIFile({
    required super.chat,
    super.onTap,
    required super.searchText,
    required super.message,
  });

  @override
  Widget getMessageThumbnail(Message message) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      // child: SizedBox(
      //   height: 15,
      //   width: 15,
      //   child: Image.asset(
      //     fileIconNameWithSuffix(
      //       message
      //           .decodeContent(cl: MessageImage.creator())
      //           .suffix
      //           .split('.')
      //           .join(),
      //     ),
      //   ),
      // ),
      child: Text(
        localized(chatTagFile),
        style: jxTextStyle.chatCellContentStyle(),
      ),
    );
  }

  @override
  String getMessageText(Message message, {String? searchText = ''}) {
    return message.decodeContent(cl: MessageFile.creator).caption;
  }
}

class _MessageUITypeName extends ListMessageUIComponent {
  _MessageUITypeName({
    required super.chat,
    required super.searchText,
    required super.message,
    required super.onTap,
  });

  @override
  String getMessageText(Message message, {String? searchText = ''}) {
    return prepareContentString(message, getCurUID(message));
  }

  String prepareContentString(Message message, int curUID) {
    bool isMe = objectMgr.userMgr.isMe(curUID);
    switch (message.typ) {
      case messageTypeAddReactEmoji:
      case messageTypeRemoveReactEmoji:
        return localized(hasReactToAMessage, params: ['']);
      case messageTypePin:
      case messageTypeCreateGroup:
        return isMe
            ? localized(haveCreatedANewGroup)
            : localized(hasCreatedANewGroup);
      case messageTypeExitGroup:
        return isMe ? localized(haveLeftTheGroup) : localized(hasLeftTheGroup);
      case messageTypeGroupAddAdmin:
        return isMe
            ? localized(haveBeenPromotedToGroupAdmin)
            : localized(hasBeenPromotedToGroupAdmin);
      case messageTypeGroupRemoveAdmin:
        return isMe
            ? localized(haveBeenDemotedToNormalMember)
            : localized(hasBeenDemotedToNormalMember);
      case messageTypeGroupChangeInfo:
        return isMe
            ? localized(msgGroupInfoHaveChanged)
            : localized(msgGroupInfoChanged);
      case messageTypeBeingFriend:
        return ' ${localized(weAreNowFriendStartChatting)}';
      case messageTypeSendRed:
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        return getSentRedPacketContent(msgRed, getCurUID(message));
      case messageTypeGetRed:
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        return getGetRedPacketContent(msgRed);
      case messageTypeGroupMute:
        return isMe
            ? localized(haveEnabledTheGroupToMute)
            : localized(hasEnabledTheGroupToMute);
      case messageBusyCall:
      case messageCancelCall:
      case messageMissedCall:
      case messageEndCall:
      case messageRejectCall:
        return ChatHelp.callMsgContent(message);
      case messageTypeAudioChatOpen:
        return localized(groupCallStart);
      case messageStartCall:
        return localized(incomingCall);
      case messageTypeNewAlbum:
        return localized(chatTagAlbum);
      case messageTypeImage:
        return localized(image);
      case messageTypeVideo:
      case messageTypeReel:
        return localized(chatVideo);
      case messageTypeTaskCreated:
        return localized(taskComing);
      case messageTypeChatScreenshotEnable:
        MessageSystem messageSystem =
            message.decodeContent(cl: MessageSystem.creator);
        if (messageSystem.isEnabled == 1) {
          return localized(screenshotTurnedOn);
        } else {
          return localized(screenshotTurnedOff);
        }
      case messageTypeChatScreenshot:
        return localized(tookScreenshotNotification);
      case messageTypeMarkdown:
        MessageMarkdown messageMarkdown =
            message.decodeContent(cl: MessageMarkdown.creator);
        String title = messageMarkdown.title;
        String text = messageMarkdown.text;
        if (searchText != '') {
          RegExp regex = RegExp(searchText!, caseSensitive: false);

          /// special case when search "."
          if (searchText == ".") {
            regex = RegExp(r'\.');
          }
          Iterable<Match> titleMatches = regex.allMatches(title);
          if (titleMatches.isNotEmpty) {
            return title;
          } else {
            Iterable<Match> textMatches = regex.allMatches(text);
            if (textMatches.isNotEmpty) {
              return text;
            }
          }
        }
        return '';
      default:
        final msg = ChatHelp.lastMsg(chat, message);
        if (msg.contains(':|')) {
          return msg;
        } else {
          String str = msg.breakWord;
          return str;
        }
      // if (widget.chat.isGroup) {
      //   return '${ChatHelp.lastMsg(widget.chat, message).breakWord}';
      // } else {
      //   return ChatHelp.lastMsg(widget.chat, message).breakWord;
      // }
    }
  }

  String getSentRedPacketContent(MessageRed msgRed, int curUID) {
    String message = objectMgr.userMgr.isMe(curUID)
        ? localized(haveSentA)
        : localized(hasSentA);

    switch (msgRed.rpType.value) {
      case 'LUCKY_RP':
        return "$message ${localized(luckyRedPacket)}";
      case 'STANDARD_RP':
        return "$message ${localized(normalRedPacket)}";
      case 'SPECIFIED_RP':
        return "$message ${localized(exclusiveRedPacket)}";
      default:
        return "$message ${localized(none)}";
    }
  }

  int getCurUID(Message? lastMessage) {
    if (lastMessage != null) {
      switch (lastMessage.typ) {
        case messageTypeAddReactEmoji:
        case messageTypeRemoveReactEmoji:
          MessageReactEmoji msg =
              lastMessage.decodeContent(cl: MessageReactEmoji.creator);
          return msg.userId;
        case messageTypeSendRed:
          MessageRed msg = lastMessage.decodeContent(cl: MessageRed.creator);
          msg.senderUid = lastMessage.send_id;
          return msg.senderUid;
        case messageTypeGetRed:
          MessageRed msg = lastMessage.decodeContent(cl: MessageRed.creator);
          return msg.userId;
        case messageTypePin:
        case messageTypeUnPin:
          MessagePin msg = lastMessage.decodeContent(cl: MessagePin.creator);
          return msg.sendId;
        case messageTypeAutoDeleteInterval:
          MessageInterval msg =
              lastMessage.decodeContent(cl: MessageInterval.creator);
          return msg.owner;
        case messageTypeSysmsg:
        case messageTypeCreateGroup:
        case messageTypeBeingFriend:
        case messageTypeAudioChatOpen:
        case messageTypeAudioChatInvite:
        case messageTypeAudioChatClose:
          return lastMessage.send_id;
        case messageTypeGroupOwner:
        case messageTypeGroupAddAdmin:
        case messageTypeGroupRemoveAdmin:
        case messageTypeKickoutGroup:
        case messageTypeGroupChangeInfo:
        case messageTypeGroupMute:
          if (chat.isGroup) {
            MessageSystem msg =
                lastMessage.decodeContent(cl: MessageSystem.creator);
            return msg.uid;
          } else {
            return lastMessage.send_id;
          }
        case messageTypeExitGroup:
          MessageSystem msg =
              lastMessage.decodeContent(cl: MessageSystem.creator);
          return msg.uid;
        case messageTypeGroupJoined:
          MessageSystem messageJoined =
              lastMessage.decodeContent(cl: MessageSystem.creator);
          return messageJoined.inviter;
        default:
          return lastMessage.send_id;
      }
    }
    return 0;
  }

  String getGetRedPacketContent(MessageRed msgRed) {
    String message = objectMgr.userMgr.isMe(msgRed.userId)
        ? localized(haveReceivedA)
        : localized(hasReceivedA);

    switch (msgRed.rpType.value) {
      case 'LUCKY_RP':
        return "$message ${localized(luckyRedPacket)}";
      case 'STANDARD_RP':
        return "$message ${localized(normalRedPacket)}";
      case 'SPECIFIED_RP':
        return "$message ${localized(exclusiveRedPacket)}";
      default:
        return "$message ${localized(none)}";
    }
  }
}
