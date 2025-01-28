import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/controllers/message_item_controller.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/chat/pages/chat_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/component/search_header_view.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/search/search_skeleton.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchChatUI extends StatefulWidget {
  final ChatListController controller;
  final bool isSearching;
  final String searchText;

  const SearchChatUI({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchText,
  });

  @override
  State<SearchChatUI> createState() => _SearchChatUIState();
}

class _SearchChatUIState extends State<SearchChatUI>
    with AutomaticKeepAliveClientMixin {
  RxList<Chat> recommendChatList = <Chat>[].obs;
  RxList<Chat> recentChatList = <Chat>[].obs;
  RxList<Chat> searchChatList = <Chat>[].obs;
  RxList<Message> messageList = <Message>[].obs;
  RxBool isShowLabel = true.obs;
  final ScrollController scrollController = ScrollController();

  int pageSize = 500;
  int pageNumber = 1;
  RxBool isLoadingMore = false.obs;
  final searchBounce = Debounce(const Duration(milliseconds: 500));

  @override
  initState() {
    super.initState();
    searchChatMessage();
  }

  @override
  void didUpdateWidget(covariant SearchChatUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      messageList.clear();
      searchChatList.clear();
      pageNumber = 1;
      isLoadingMore.value = true;
      searchChatMessage();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isSearching) return buildLoadingView(context);

    return Obx(() {
      if (isLoadingMore.value) {
        if (notBlank(widget.searchText) && messageList.isEmpty) {
          return buildLoadingView(context);
        }
      }

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
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          if (notification is ScrollUpdateNotification) {
            widget.controller.searchFocus.unfocus();
          }
        }
        return true;
      },
      child: ListView(
        shrinkWrap: true,
        children: [
          Container(
            alignment: Alignment.center,
            height: 102,
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // Number of rows
              ),
              itemCount: recommendChatList.length,
              itemBuilder: (ctx, index) {
                Chat chat = recommendChatList[index];
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    widget.controller.searchFocus.unfocus();
                    Routes.toChat(chat: chat);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ForegroundOverlayEffect(
                          overlayColor: colorOverlay40,
                          radius: BorderRadius.circular(100),
                          child: buildIcon(
                            chat,
                            jxDimension.chatListAvatarSize(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        buildChatName(
                          chat,
                          MFontSize.size11.value,
                          MFontWeight.bold4.value,
                          1,
                          widget.searchText,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Visibility(
            visible: recentChatList.isNotEmpty,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomDivider(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  width: double.infinity,
                  color: colorBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localized(recent),
                        style: jxTextStyle.normalSmallText(
                            color: colorTextSecondary),
                      ),
                      GestureDetector(
                        onTap: () => onClearRecentChat(context),
                        child: OpacityEffect(
                          child: Text(
                            localized(chatClear),
                            style: jxTextStyle.normalSmallText(
                                color: colorTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  reverse: true,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: recentChatList.length,
                  itemBuilder: (context, index) {
                    Chat chat = recentChatList[index];
                    return buildChatItem(chat, isShowSubtitle: true);
                  },
                  separatorBuilder: (_, __) => const CustomDivider(indent: 68),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    if (isLoadingMore.value) return;
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
    if (notBlank(widget.searchText)) {
      searchBounce.call(searchMessage);
    }
  }

  Future<void> searchChat() async {
    if (notBlank(widget.searchText)) {
      List<Chat> tempChatList = await widget.controller.processSearchChat();
      tempChatList = tempChatList.where((chat) {
        return chat.name
            .toLowerCase()
            .contains(widget.searchText.toLowerCase());
      }).toList();
      objectMgr.chatMgr.sortChatList(tempChatList);
      searchChatList.assignAll(tempChatList);
    } else {
      searchChatList.value = [];
      List<Chat> allChats = widget.controller.allChats;

      /// 推荐聊天室
      List<Chat> tempChatList = allChats.sublist(
        0,
        allChats.length > 10 ? 10 : allChats.length,
      );
      objectMgr.chatMgr.sortChatList(tempChatList);
      recommendChatList.assignAll(tempChatList);

      /// 最近聊天室
      List<Chat> chats = await objectMgr.chatMgr.getRecentChatList();
      recentChatList.assignAll(chats);
      isLoadingMore.value = false;
    }
  }

  Future<void> searchMessage() async {
    int foundCount = 0;
    final accumulatedMessages = <Message>[];

    while (foundCount < 100) {
      isLoadingMore.value = true;
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

    if (isLoadingMore.value) {
      await Future.delayed(const Duration(milliseconds: 500), () {
        isLoadingMore.value = false;
        messageList.removeWhere((element) => element.id == 0);
      });
    }

    for (Message msg in accumulatedMessages) {
      bool exists = messageList.any((message) => message.id == msg.id);
      if (!exists) {
        messageList.add(msg);
      }
    }
  }

  void onClearRecentChat(BuildContext context) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(areYouSureClearSearchHistory),
      confirmText: localized(chatClear),
      onConfirmListener: () {
        recentChatList.clear();
        objectMgr.localStorageMgr.write(
          LocalStorageMgr.RECENT_CHAT,
          jsonEncode(recentChatList),
        );
      },
    );
  }

  Future<void> onClickChat(Chat chat, {List<Message>? message}) async {
    final chatList = await objectMgr.chatMgr.getRecentChatList();
    int index = chatList.indexWhere((element) => element.id == chat.id);

    if (index < 0) {
      if (chatList.length >= 10) {
        chatList.removeAt(0); // Remove the first item if the array is full.
      }
      chatList.add(chat);
      List<int> ids = chatList.map((chat) => chat.chat_id).toList();

      objectMgr.localStorageMgr.write(
        LocalStorageMgr.RECENT_CHAT,
        jsonEncode(ids),
      );
    }
    recentChatList.value = chatList;
    widget.controller.searchFocus.unfocus();
    Routes.toChat(chat: chat, selectedMsgIds: message);
  }
}
