import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/search/search_skeleton.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchVoiceUI extends StatefulWidget {
  final ChatListController controller;
  final bool isSearching;
  final String searchText;

  const SearchVoiceUI({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchText,
  });

  @override
  State<SearchVoiceUI> createState() => _SearchVoiceUIState();
}

class _SearchVoiceUIState extends State<SearchVoiceUI>
    with AutomaticKeepAliveClientMixin {
  RxList<Message> messageList = <Message>[].obs;
  int pageSize = 500;
  int pageNumber = 1;
  RxBool isLoadingMore = false.obs;
  final searchBounce = Debounce(const Duration(milliseconds: 500));

  @override
  initState() {
    super.initState();
    searchMessage();
  }

  @override
  void didUpdateWidget(covariant SearchVoiceUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      messageList.clear();
      pageNumber = 1;
      isLoadingMore.value = true;
      searchBounce.call(searchMessage);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (messageList.isEmpty && isLoadingMore.value) {
        return buildLoadingView(context);
      }
      if (notBlank(widget.searchText)) return buildResultView(context);

      return buildInitView(context);
    });
  }

  /// UI
  Widget buildLoadingView(BuildContext context) {
    return buildSkeleton(
      context,
      VoiceSkeleton(context),
      64.0,
    );
  }

  Widget buildInitView(BuildContext context) {
    if (messageList.isNotEmpty) {
      return buildList();
    } else {
      return SearchEmptyState(
        searchText: widget.searchText,
        emptyMessage: localized(noRelevantContent),
      );
    }
  }

  Widget buildResultView(BuildContext context) {
    if (messageList.isNotEmpty) {
      return buildList();
    } else {
      return SearchEmptyState(
        searchText: widget.searchText,
        emptyMessage: localized(noRelevantContent),
      );
    }
  }

  Widget buildList() {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          if (notification is ScrollUpdateNotification) {
            widget.controller.searchFocus.unfocus();
          }

          if (notification.metrics.pixels + 300 >
              notification.metrics.maxScrollExtent) {
            loadMoreSearchMessage();
          }
        }
        return true;
      },
      child: Obx(
        () => ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: messageList.length,
          itemBuilder: (context, index) {
            final Message message = messageList[index];
            final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
            MessageVoice audio =
                messageList[index].decodeContent(cl: MessageVoice.creator);

            if (message.id == 0) {
              return Skeletonizer(
                effect: const ShimmerEffect(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  duration: Duration(milliseconds: 2000),
                  highlightColor: colorWhite,
                ),
                textBoneBorderRadius:
                    const TextBoneBorderRadius.fromHeightFactor(0.5),
                containersColor: colorBackground3,
                ignorePointers: false,
                enabled: true,
                child: VoiceSkeleton(context),
              );
            } else {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: (index == messageList.length - 1 && Platform.isIOS)
                      ? 34.0
                      : 0.0,
                ),
                child: AudioItem(
                  message: message,
                  messageVoice: audio,
                  isGroup: chat?.isGroup ?? false,
                  chat: chat,
                  isSearch: true,
                  searchText: widget.searchText,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Logic
  Future<void> loadMoreSearchMessage() async {
    if (isLoadingMore.value) return;
    int totalCount = await objectMgr.localDB
        .getMessageCount([messageTypeVoice], widget.searchText);
    int totalPages = (totalCount / pageSize).ceil();
    if (pageNumber < totalPages) {
      messageList.add(Message());
      searchMessage();
    }
  }

  Future<void> searchMessage() async {
    int foundCount = 0;
    final accumulatedMessages = <Message>[];

    while (foundCount < 100) {
      isLoadingMore.value = true;
      List<Message> messages = await widget.controller.searchDBMessages(
        typeList: [messageTypeVoice],
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
}
