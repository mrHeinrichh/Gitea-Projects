import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/controllers/message_item_controller.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/media_detail/media_detail_view.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/search/search_skeleton.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchMediaUI extends StatefulWidget {
  final ChatListController controller;
  final bool isSearching;
  final String searchText;

  const SearchMediaUI({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchText,
  });

  @override
  State<SearchMediaUI> createState() => _SearchMediaUIState();
}

class _SearchMediaUIState extends State<SearchMediaUI>
    with AutomaticKeepAliveClientMixin {
  RxList<Map<String, dynamic>> searchInitMediaMessageList =
      <Map<String, dynamic>>[].obs;
  RxList<Message> messageList = <Message>[].obs;
  int pageSize = 500;
  int pageNumber = 1;
  RxBool isLoadingMore = false.obs;
  final searchBounce = Debounce(const Duration(milliseconds: 500));

  @override
  initState() {
    super.initState();
    searchMessage();
    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMediaMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMediaMessageAutoDelete);
  }

  @override
  void didUpdateWidget(covariant SearchMediaUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      messageList.clear();
      pageNumber = 1;
      isLoadingMore.value = true;
      searchBounce.call(searchMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isSearching) return buildLoadingView(context);

    return Obx(() {
      if (isLoadingMore.value) {
        if (!notBlank(widget.searchText) &&
            searchInitMediaMessageList.isEmpty) {
          return buildLoadingView(context);
        }

        if (notBlank(widget.searchText) && messageList.isEmpty) {
          return buildLoadingView(context);
        }
      }

      if (notBlank(widget.searchText)) return buildResultView(context);

      return buildGridView(context);
    });
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (data.typ != messageTypeImage &&
          data.typ != messageTypeVideo &&
          data.typ != messageTypeReel &&
          data.typ != messageTypeNewAlbum) return;
      if (data.isEncrypted) return;

      if (data.typ == messageTypeNewAlbum) {
        NewMessageMedia messageMedia =
            data.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = messageMedia.albumList ?? [];

        List<Map<String, dynamic>> newList = [];
        for (AlbumDetailBean bean in list) {
          if (searchInitMediaMessageList
                  .indexWhere((e) => e['assets'] == bean) ==
              -1) {
            newList.add({'asset': bean, 'message': data});
          }
        }

        newList = newList.reversed.toList();
        searchInitMediaMessageList.insertAll(0, newList);
      } else if (data.typ == messageTypeImage) {
        MessageImage msgImg = data.decodeContent(cl: MessageImage.creator);
        searchInitMediaMessageList
            .insert(0, {'asset': msgImg.url, 'message': data});
      } else if (data.typ == messageTypeVideo || data.typ == messageTypeReel) {
        MessageVideo msgImg = data.decodeContent(cl: MessageVideo.creator);
        searchInitMediaMessageList.insert(0, {
          'asset': msgImg.url,
          'cover': msgImg.cover,
          'message': data,
        });
      }
      return;
    }
  }

  _onMediaMessageUpdate(sender, type, data) {
    if (data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int messageId = 0;
      if (item is Message) {
        id = item.id;
      } else {
        messageId = item;
      }
      for (final asset in searchInitMediaMessageList) {
        Message msg = asset['message'];
        if (id == 0) {
          if (msg.message_id == messageId) {
            delAsset.add(asset);
          }
        } else {
          if (msg.id == id) {
            delAsset.add(asset);
          }
        }
      }
    }

    if (delAsset.isNotEmpty) {
      for (final item in delAsset) {
        searchInitMediaMessageList.remove(item);
      }
    }
  }

  _onMediaMessageAutoDelete(sender, type, data) {
    if (data is Message) {
      if (data.typ != messageTypeImage &&
          data.typ != messageTypeVideo &&
          data.typ != messageTypeNewAlbum) return;
      for (final asset in searchInitMediaMessageList) {
        Message msg = asset['message'];
        if (msg.message_id == data.message_id) {
          searchInitMediaMessageList.remove(asset);
        }
      }
      return;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onMediaMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);
    super.dispose();
  }

  /// UI
  Widget buildLoadingView(BuildContext context) {
    final size = MediaQuery.of(context).size.width ~/ 3;
    final rowCount = MediaQuery.of(context).size.height ~/ size + 1;
    final totalCount = rowCount * 3;

    if (notBlank(widget.searchText)) {
      return buildSkeleton(
        context,
        CircleSkeleton(context),
        80,
      );
    } else {
      return Skeletonizer(
        effect: const ShimmerEffect(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          duration: Duration(milliseconds: 2000),
          highlightColor: colorWhite,
        ),
        textBoneBorderRadius: const TextBoneBorderRadius.fromHeightFactor(0.5),
        containersColor: colorBackground3,
        ignorePointers: false,
        enabled: true,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
          ),
          itemCount: totalCount,
          itemBuilder: (ctx, index) {
            return const Bone.square();
          },
        ),
      );
    }
  }

  Widget buildGridView(BuildContext context) {
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
      child: searchInitMediaMessageList.isNotEmpty
          ? GridView.builder(
              padding: EdgeInsets.only(
                bottom: Platform.isIOS ? 34.0 : 0.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: searchInitMediaMessageList.length,
              itemBuilder: (ctx, index) {
                final msg = searchInitMediaMessageList[index]['message'];
                if (msg == null) {
                  return const Skeletonizer(
                    effect: ShimmerEffect(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      duration: Duration(milliseconds: 2000),
                      highlightColor: colorWhite,
                    ),
                    textBoneBorderRadius:
                        TextBoneBorderRadius.fromHeightFactor(0.5),
                    containersColor: colorBackground3,
                    ignorePointers: false,
                    enabled: true,
                    child: Bone.square(),
                  );
                }

                dynamic msgImg;
                if (msg.typ == messageTypeImage) {
                  msgImg = msg.decodeContent(cl: MessageImage.creator);
                } else if (msg.typ == messageTypeVideo ||
                    msg.typ == messageTypeReel) {
                  msgImg = msg.decodeContent(cl: MessageVideo.creator);
                } else {
                  msgImg = searchInitMediaMessageList[index]['asset'];
                }

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onShowMedia(context, index),
                  child: _buildMediaItem(
                      msgImg, MediaQuery.of(context).size.width / 3),
                );
              },
            )
          : SearchEmptyState(
              searchText: widget.searchText,
              emptyMessage: localized(noRelevantContent),
            ),
    );
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
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: messageList.length,
          itemBuilder: (context, index) {
            final Message message = messageList[index];
            final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);

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
                child: CircleSkeleton(context),
              );
            }

            return Column(
              children: [
                MessageCellView<MessageItemController>(
                  message: message,
                  chatId: message.chat_id,
                  searchText: widget.searchText,
                  onClick: () {
                    if (chat != null) {
                      Routes.toChat(chat: chat, selectedMsgIds: [message]);
                    }
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: (index == messageList.length - 1 && Platform.isIOS)
                        ? 34.0
                        : 0.0,
                  ),
                  child: const CustomDivider(
                    indent: 82,
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaItem(dynamic msgImg, double imageWidth) {
    if (msgImg is MessageImage ||
        (msgImg is AlbumDetailBean && msgImg.cover.isEmpty)) {
      return ForegroundOverlayEffect(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: colorBackground6, width: 0.5)),
          child: RemoteImage(
            src: msgImg.url,
            width: imageWidth,
            height: imageWidth,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          ),
        ),
      );
    } else if (msgImg is MessageVideo ||
        (msgImg is AlbumDetailBean && msgImg.cover.isNotEmpty)) {
      int seconds = 0;
      if (msgImg is MessageVideo) {
        seconds = msgImg.second;
      } else {
        seconds = msgImg.seconds;
      }
      return ForegroundOverlayEffect(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
                child: RemoteImage(
              src: msgImg.cover,
              width: imageWidth,
              height: imageWidth,
              fit: BoxFit.cover,
              mini: Config().messageMin,
            )),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorTextSecondary,
                ),
                child: Text(
                  formatVideoDuration(seconds),
                  style: jxTextStyle.supportSmallText(
                    color: colorBrightPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const Text("Null");
    }
  }

  void onShowMedia(BuildContext context, int index) {
    Navigator.of(context).push(
      TransparentRoute(
        builder: (BuildContext context) => MediaDetailView(
          assetList: searchInitMediaMessageList,
          index: index,
          fromPage: FromPage.search,
        ),
        settings: const RouteSettings(name: RouteName.mediaDetailView),
      ),
    );
  }

  /// Logic
  Future<void> loadMoreSearchMessage() async {
    if (isLoadingMore.value) return;

    int totalCount = await objectMgr.localDB.getMessageCount([
      messageTypeImage,
      messageTypeVideo,
      messageTypeNewAlbum,
    ], widget.searchText);
    int totalPages = (totalCount / pageSize).ceil();
    if (pageNumber < totalPages) {
      if (notBlank(widget.searchText)) {
        messageList.add(Message());
      } else {
        searchInitMediaMessageList.add({});
        searchInitMediaMessageList.add({});
        searchInitMediaMessageList.add({});
      }
      searchMessage();
    }
  }

  Future<void> searchMessage() async {
    int foundCount = 0;
    final accumulatedMessages = <Message>[];

    while (foundCount < 100) {
      isLoadingMore.value = true;
      List<Message> messages = await widget.controller.searchDBMessages(
        typeList: [
          messageTypeImage,
          messageTypeVideo,
          messageTypeNewAlbum,
        ],
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

    if (notBlank(widget.searchText)) {
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
      searchInitMediaMessageList.value = [];
    } else {
      final List<Map<String, dynamic>> mediaList = <Map<String, dynamic>>[];

      for (Message item in accumulatedMessages) {
        if (item.typ == messageTypeNewAlbum) {
          NewMessageMedia messageMedia =
              item.decodeContent(cl: NewMessageMedia.creator);
          List<AlbumDetailBean> list = messageMedia.albumList ?? [];

          List<Map<String, dynamic>> newList = [];
          for (AlbumDetailBean bean in list) {
            if (mediaList.indexWhere((e) => e['assets'] == bean) == -1) {
              newList.add({'asset': bean, 'message': item});
            }
          }

          newList = newList.reversed.toList();
          mediaList.insertAll(0, newList);
        } else if (item.typ == messageTypeImage) {
          MessageImage msgImg = item.decodeContent(cl: MessageImage.creator);
          mediaList.insert(0, {'asset': msgImg.url, 'message': item});
        } else if (item.typ == messageTypeVideo ||
            item.typ == messageTypeReel) {
          MessageVideo msgImg = item.decodeContent(cl: MessageVideo.creator);
          mediaList.insert(0, {
            'asset': msgImg.url,
            'cover': msgImg.cover,
            'message': item,
          });
        }
      }

      mediaList
          .sort((a, b) => b['message'].create_time - a['message'].create_time);

      if (isLoadingMore.value) {
        await Future.delayed(const Duration(milliseconds: 500), () {
          isLoadingMore.value = false;
          searchInitMediaMessageList.removeWhere((element) => element.isEmpty);
        });
      }

      messageList.value = [];
      searchInitMediaMessageList.addAll(mediaList);
    }
  }

  @override
  bool get wantKeepAlive => true;
}
