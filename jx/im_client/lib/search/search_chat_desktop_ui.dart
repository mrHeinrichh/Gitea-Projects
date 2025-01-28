import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_calendar_date_picker2/widgets/click_effect_button.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/controllers/message_item_controller.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/chat/pages/chat_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/component/search_header_view.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/search/search_skeleton.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchChatDesktopUI extends StatefulWidget {
  final ChatListController controller;
  final bool isSearching;
  final String searchText;

  const SearchChatDesktopUI({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchText,
  });

  @override
  State<SearchChatDesktopUI> createState() => _SearchChatDesktopUIState();
}

class _SearchChatDesktopUIState extends State<SearchChatDesktopUI> {
  RxList<Chat> searchChatList = <Chat>[].obs;
  RxList<Message> messageList = <Message>[].obs;
  RxBool isShowLabel = true.obs;
  final ScrollController scrollController = ScrollController();

  int pageSize = 100;
  int pageNumber = 1;
  bool isLoadingMore = false;

  @override
  initState() {
    super.initState();
    if (notBlank(widget.searchText)) {
      searchChatMessage();
    } else {
      searchChat();
    }
  }

  @override
  void didUpdateWidget(covariant SearchChatDesktopUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      messageList.clear();
      searchChatList.clear();
      pageNumber = 1;
      searchChatMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSearching) return buildLoadingView(context);

    return Obx(() {
      if (notBlank(widget.searchText)) return buildResultView(context);

      return buildInitView(context);
    });
  }

  /// UI
  Widget buildLoadingView(BuildContext context) {
    return buildSkeleton(
      context,
      CircleSkeleton(context),
      80,
    );
  }

  Widget buildInitView(BuildContext context) {
    if (searchChatList.isNotEmpty || messageList.isNotEmpty) {
      return buildList();
    } else {
      return SearchEmptyState(
        searchText: widget.searchText,
        emptyMessage: localized(noRelevantContent),
      );
    }
  }

  Widget buildResultView(BuildContext context) {
    if (searchChatList.isNotEmpty || messageList.isNotEmpty) {
      return buildList();
    } else {
      return SearchEmptyState(
        searchText: widget.searchText,
        emptyMessage: localized(noRelevantContent),
      );
    }
  }

  Widget buildList() {
    final chatHeight = (48 * searchChatList.length);
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          if (notification is ScrollUpdateNotification) {
            widget.controller.searchFocus.unfocus();
            double currentScroll = notification.metrics.pixels;
            if (currentScroll >= chatHeight) {
              isShowLabel.value = false;
            } else {
              isShowLabel.value = true;
            }
          }

          if (notification.metrics.pixels + 300 >
              notification.metrics.maxScrollExtent) {
            loadMoreSearchMessage();
          }
        }
        return true;
      },
      child: Obx(
        () => Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isShowLabel.value && searchChatList.isNotEmpty
                  ? 30
                  : 0, // Expand or collapse height
              child: SearchHeaderView(
                title: localized(chatAndContact),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: SlowScrollPhysics(),
                ),
                slivers: [
                  Obx(
                    () => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final Chat chat = searchChatList[index];
                          if (chat.typ == chatTypePostNotify) {
                            return const SizedBox();
                          }

                          return Column(
                            children: [
                              buildChatItem(chat),
                              if (index != searchChatList.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(left: 68),
                                  child: CustomDivider(),
                                ),
                            ],
                          );
                        },
                        childCount: searchChatList.length,
                        addRepaintBoundaries: false,
                      ),
                    ),
                  ),
                  if (messageList.isNotEmpty)
                    SliverAppBar(
                      elevation: 0,
                      pinned: true,
                      toolbarHeight: 30,
                      flexibleSpace: SearchHeaderView(
                        title: localized(homeTitle),
                      ),
                    ),
                  Obx(
                    () => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final Message message = messageList[index];
                          final Chat? chat =
                              objectMgr.chatMgr.getChatById(message.chat_id);

                          if (message.id == 0) {
                            return Skeletonizer(
                              effect: const ShimmerEffect(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                duration: Duration(milliseconds: 2000),
                                highlightColor: colorWhite,
                              ),
                              textBoneBorderRadius:
                                  const TextBoneBorderRadius.fromHeightFactor(
                                      0.5),
                              containersColor: colorBackground3,
                              ignorePointers: false,
                              enabled: true,
                              child: CircleSkeleton(context),
                            );
                          } else {
                            return Column(
                              children: <Widget>[
                                MessageCellView<MessageItemController>(
                                    message: message,
                                    chatId: message.chat_id,
                                    searchText: widget.searchText,
                                    onClick: () {
                                      if (chat != null) {
                                        Routes.toChat(
                                            chat: chat,
                                            selectedMsgIds: [message]);
                                      }
                                    }),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: (index == messageList.length - 1 &&
                                            Platform.isIOS)
                                        ? 34.0
                                        : 0.0,
                                  ),
                                  child: const CustomDivider(
                                    indent: 82,
                                  ),
                                )
                              ],
                            );
                          }
                        },
                        childCount: messageList.length,
                        addRepaintBoundaries: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChatItem(Chat chat, {isShowSubtitle = false}) {
    bool isOnline = false;
    String subtitle = '';

    if (isShowSubtitle) {
      if (chat.isSingle) {
        if (!chat.isSpecialChat) {
          isOnline = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
              localized(chatOnline);
          subtitle =
              objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ?? '';
        }
      } else if (chat.isGroup) {
        Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
        if (group != null) {
          subtitle =
              '${group.members.length.toString()} ${localized(chatInfoMembers)}';
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onClickChat(chat),
      child: OverlayEffect(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 12),
                child: buildIcon(chat, 40),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    buildChatName(chat, MFontSize.size17.value,
                        MFontWeight.bold5.value, 1, widget.searchText),
                    Visibility(
                      visible: notBlank(subtitle),
                      child: Text(
                        subtitle,
                        style: jxTextStyle.normalSmallText(
                          color: isOnline ? themeColor : colorTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logic
  Future<void> loadMoreSearchMessage() async {
    if (isLoadingMore) return;

    isLoadingMore = true;
    int totalCount =
        await objectMgr.localDB.getMessageCount([], widget.searchText);
    int totalPages = (totalCount / pageSize).ceil();
    if (pageNumber < totalPages) {
      if (notBlank(widget.searchText)) {
        messageList.add(Message());
      }
      searchMessage();
    }
  }

  Future<void> searchChatMessage() async {
    await searchChat();
    await searchMessage();
  }

  Future<void> searchChat() async {
    List<Chat> tempChatList = await widget.controller.processSearchChat();

    if (notBlank(widget.searchText)) {
      tempChatList = tempChatList.where((chat) {
        return chat.name
            .toLowerCase()
            .contains(widget.searchText.toLowerCase());
      }).toList();
    }
    objectMgr.chatMgr.sortChatList(tempChatList);
    searchChatList.assignAll(tempChatList);
  }

  Future<void> searchMessage() async {
    if (notBlank(widget.searchText)) {
      int foundCount = 0;
      final accumulatedMessages = <Message>[];

      while (foundCount < 100) {
        List<Message> messages = await widget.controller.searchDBMessages(
          typeList: [],
          searchText: widget.searchText,
          pageSize: pageSize,
          pageNumber: pageNumber,
        );

        if (messages.isEmpty) break;

        pageNumber += 1;

        if (notBlank(widget.searchText)) {
          messages = objectMgr.chatMgr
              .searchMessageFromRows(widget.searchText, messages);
        }

        foundCount += messages.length;
        accumulatedMessages.addAll(messages);
      }

      accumulatedMessages.sort((a, b) => b.create_time - a.create_time);

      if (isLoadingMore) {
        await Future.delayed(const Duration(milliseconds: 500), () {
          isLoadingMore = false;
          messageList.removeWhere((element) => element.id == 0);
        });
      }
      messageList.addAll(accumulatedMessages);
      messageList.toSet().toList();
    } else {
      messageList.clear();
    }
  }

  Future<void> onClickChat(Chat chat, {List<Message>? message}) async {
    widget.controller.searchFocus.unfocus();
    Routes.toChat(chat: chat, selectedMsgIds: message);
  }
}
