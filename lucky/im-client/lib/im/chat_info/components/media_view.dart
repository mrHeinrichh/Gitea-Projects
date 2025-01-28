import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/media_detail/media_detail_view.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_large_photo.dart';

class MediaView extends StatefulWidget {
  final Chat? chat;
  final bool isGroup;

  const MediaView({
    super.key,
    required this.isGroup,
    this.chat,
  });

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool noMoreNext = false;

  bool singleAndNotFriend = false;
  bool chatIsDeleted = false;

  /// 是否还有更多数据
  bool isLoadingMore = true;
  final scrollThreshold = 200;

  final messageList = <Map<String, dynamic>>[].obs;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    if (widget.chat != null) {
      if (widget.chat!.isSingle) {
        chatInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (chatInfoController!.user.value!.relationship !=
            Relationship.friend) {
          singleAndNotFriend = true;
        }
      } else {
        groupInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (widget.chat!.flag_my >= ChatStatus.MyChatFlagKicked.value) {
          chatIsDeleted = true;
        } else {
          chatIsDeleted = false;
        }
      }
      loadMediaList();
    } else {
      singleAndNotFriend = true;
    }
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMediaMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMediaMessageAutoDelete);
    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    }
  }

  /// 实时消息通知
  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeImage &&
          data.typ != messageTypeVideo &&
          data.typ != messageTypeReel &&
          data.typ != messageTypeNewAlbum) return;

      if (data.typ == messageTypeNewAlbum) {
        NewMessageMedia messageMedia =
            data.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = messageMedia.albumList ?? [];

        List<Map<String, dynamic>> newList = [];
        for (AlbumDetailBean bean in list) {
          if (!messageList.contains(bean)) {
            newList.add({'asset': bean, 'message': data});
          }
        }

        newList = newList.reversed.toList();
        messageList.insertAll(0, newList);
      } else if (data.typ == messageTypeImage) {
        MessageImage msgImg = data.decodeContent(cl: MessageImage.creator);
        messageList.insert(0, {'asset': msgImg.url, 'message': data});
      } else if (data.typ == messageTypeVideo || data.typ == messageTypeReel) {
        MessageVideo msgImg = data.decodeContent(cl: MessageVideo.creator);
        messageList.insert(0, {
          'asset': msgImg.url,
          'cover': msgImg.cover,
          'message': data,
        });
      }
      return;
    }
  }

  /// 消息更新
  _onMediaMessageUpdate(sender, type, data) {
    if (data['id'] != widget.chat?.id || data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int message_id = 0;
      if (item is Message) {
        id = item.id;
      } else {
        message_id = item;
      }
      for (final asset in messageList) {
        Message msg = asset['message'];
        if (id == 0) {
          if (msg.message_id == message_id) {
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
        messageList.remove(item);
      }
    }
  }

  _onMediaMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeImage && data.typ != messageTypeVideo && data.typ != messageTypeLiveVideo && data.typ != messageTypeNewAlbum) return;
      for (final asset in messageList) {
        Message msg = asset['message'];
        if (msg.message_id == data.message_id) {
          messageList.remove(asset);
        }
      }
      return;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onMediaMessageUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _onMediaMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);
    super.dispose();
  }

  loadMediaList() async {
    if (messageList.isEmpty) isLoading.value = true;
    if (noMoreNext) return;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND (typ = ? OR typ = ? OR typ = ? OR typ = ?) AND deleted != 1 AND (expire_time == 0 OR expire_time > ?) AND message_id != 0',
      [
        widget.chat!.id,
        widget.chat!.hide_chat_msg_idx,
        messageList.isEmpty
            ? widget.chat!.msg_idx + 1
            : messageList.last['message'].chat_idx,
        messageTypeImage,
        messageTypeVideo,
        messageTypeReel,
        messageTypeNewAlbum,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ],
      'DESC',
      30,
    );

    if (tempList.isEmpty) {
      noMoreNext = true;
    }

    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    messageList.addAll(processAssetList(mList));

    isLoading.value = false;
  }

  onShowMedia(int index) {
    ChatContentController? controller;
    if (Get.isRegistered<ChatContentController>(
        tag: widget.chat?.id.toString())) {
      controller =
          Get.find<ChatContentController>(tag: widget.chat!.id.toString());
    }
    if (objectMgr.loginMgr.isDesktop) {
      DesktopGeneralDialog(
        context,
        color: const Color.fromRGBO(25, 25, 25, 0.9),
        dismissible: true,
        widgetChild: NewDesktopLargePhoto(
          assetList: messageList,
          index: index,
          contentController: controller,
          groupChatInfoController: groupInfoController,
        ),
      );
    } else {
      Navigator.of(context).push(
        TransparentRoute(
          builder: (BuildContext context) => MediaDetailView(
            assetList: messageList,
            index: index,
            contentController: controller,
            groupChatInfoController: groupInfoController,
          ),
          settings: const RouteSettings(name: RouteName.mediaDetailView),
        ),
      );
    }
  }

  onItemLongPress(Message message) async {
    if (widget.isGroup) {
      groupInfoController!.onMoreSelect.value = true;
      groupInfoController!.selectedMessageList.add(message);
    } else {
      chatInfoController!.onMoreSelect.value = true;
      chatInfoController!.selectedMessageList.add(message);
    }
  }

  onItemTap(Message message) {
    if (widget.isGroup) {
      if (groupInfoController!.selectedMessageList.contains(message)) {
        groupInfoController!.selectedMessageList.remove(message);
        if (groupInfoController!.selectedMessageList.isEmpty) {
          groupInfoController!.onMoreSelect.value = false;
        }
      } else {
        groupInfoController!.selectedMessageList.add(message);
      }
    } else {
      if (chatInfoController!.selectedMessageList.contains(message)) {
        chatInfoController!.selectedMessageList.remove(message);
        if (chatInfoController!.selectedMessageList.isEmpty) {
          chatInfoController!.onMoreSelect.value = false;
        }
      } else {
        chatInfoController!.selectedMessageList.add(message);
      }
    }
  }

  onJumpToOriginalMessage(Message message) {
    int idx = -1;

    if (idx == -1) {
      idx = message.chat_idx;
    }

    Get.back();
    if (widget.isGroup) {
      if (Get.isRegistered<GroupChatController>(
          tag: widget.chat!.id.toString())) {
        final groupController =
            Get.find<GroupChatController>(tag: widget.chat!.id.toString());
        groupController.clearSearching();
        groupController.locateToSpecificPosition([idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    } else {
      if (Get.isRegistered<SingleChatController>(
          tag: widget.chat!.id.toString())) {
        final singleChatController =
            Get.find<SingleChatController>(tag: widget.chat!.id.toString());
        singleChatController.clearSearching();
        singleChatController.locateToSpecificPosition([idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    }
  }

  List<Map<String, dynamic>> processAssetList(List<Message> messageList) {
    List<Map<String, dynamic>> assetList = [];
    for (Message message in messageList) {
      if (message.deleted == 1 || !message.isMediaType) {
        continue;
      }

      if (message.typ == messageTypeImage) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
        } else {
          MessageImage messageImage =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageImage.url;
          assetMap['message'] = message;
        }
        assetList.add(assetMap);
      } else if (message.typ == messageTypeVideo ||
          message.typ == messageTypeReel) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
        } else {
          MessageVideo messageVideo =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageVideo.url;
          assetMap['cover'] = messageVideo.cover;
          assetMap['message'] = message;
        }

        assetMap['hasVideo'] = true;
        assetList.add(assetMap);
      } else {
        if (notBlank(message.asset)) {
          List<AssetEntity> reversedAsset = message.asset.reversed.toList();
          for (int i = 0; i < reversedAsset.length; i++) {
            Map<String, dynamic> assetMap = {};
            AssetEntity asset = reversedAsset[i];
            NewMessageMedia msgMedia = message.decodeContent(
              cl: NewMessageMedia.creator,
            );

            if (notBlank(msgMedia.albumList) &&
                msgMedia.albumList!.length > i) {
              AlbumDetailBean bean = msgMedia.albumList![i];
              bean.asset = asset;
              assetMap['asset'] = bean;
              assetMap['message'] = message;

              if (asset.type == AssetType.video) {
                assetMap['hasVideo'] = true;
              }
            } else {
              AlbumDetailBean bean = AlbumDetailBean(
                url: '',
              );
              bean.asset = asset;
              bean.asheight = asset.height;
              bean.aswidth = asset.width;
              if (asset.mimeType != null) {
                bean.mimeType = asset.mimeType;
              } else {
                AssetType type = asset.type;
                if (type == AssetType.image) {
                  bean.mimeType = "image/png";
                } else if (type == AssetType.video) {
                  bean.mimeType = "video/mp4";
                  assetMap['hasVideo'] = true;
                }
              }
              bean.currentMessage = message;

              assetMap['asset'] = bean;
              assetMap['message'] = message;
            }

            if (assetMap.isNotEmpty) {
              assetList.add(assetMap);
            }
          }
        } else {
          NewMessageMedia messageMedia =
              message.decodeContent(cl: NewMessageMedia.creator);
          List<AlbumDetailBean> list = messageMedia.albumList ?? [];
          list = list.reversed.toList();
          for (AlbumDetailBean bean in list) {
            Map<String, dynamic> assetMap = {};
            bean.currentMessage = message;
            assetMap['asset'] = bean;
            assetMap['message'] = message;
            if (bean.mimeType != null && bean.mimeType == "video/mp4") {
              assetMap['hasVideo'] = true;
            }

            assetList.add(assetMap);
          }
        }
      }
    }

    return assetList;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () {
        if (!widget.isGroup) {
          if (chatInfoController!.user.value!.relationship !=
              Relationship.friend) {
            singleAndNotFriend = true;
          } else {
            singleAndNotFriend = false;
          }
        }

        if (isLoading.value) {
          return BallCircleLoading(
            radius: 20,
            ballStyle: BallStyle(
              size: 4,
              color: accentColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: accentColor,
            ),
          );
        }

        if (singleAndNotFriend && messageList.isEmpty) {
          return Center(
            child: Text(localized(noItemFoundAddThisUserFirst)),
          );
        } else if (messageList.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svgs/empty_state.svg',
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 16),
              Text(
                localized(noHistoryYet),
                style: jxTextStyle.textStyleBold16(),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style:
                    jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              ),
            ],
          );
        } else {
          int scrollStatus = 0;

          return NotificationListener(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.scrollDelta! > 0.0) {
                  scrollStatus = 1;
                } else if (notification.scrollDelta! < 0.0) {
                  scrollStatus = -1;
                } else {
                  Debounce dbounce =
                      Debounce(const Duration(milliseconds: 100));
                  dbounce.call(() {
                    scrollStatus = 0;
                  });
                }
              }
              if (notification is ScrollEndNotification) {
                if ((notification.metrics.pixels ==
                        notification.metrics.maxScrollExtent) ||
                    (notification.metrics.pixels + scrollThreshold >
                            notification.metrics.maxScrollExtent) &&
                        scrollStatus == 1) {
                  if (isLoadingMore && !chatIsDeleted) {
                    loadMediaList();
                  }
                }
              }
              return true;
            },
            child: CustomScrollView(
              // physics: const NeverScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverGrid.count(
                  crossAxisCount: objectMgr.loginMgr.isDesktop ? 4 : 3,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                  children: List.generate(
                    messageList.length,
                    (index) {
                      final msg = messageList[index]['message'];

                      var msgImg;
                      if (msg.typ == messageTypeImage) {
                        msgImg = msg.decodeContent(cl: MessageImage.creator);
                      } else if (msg.typ == messageTypeVideo ||
                          msg.typ == messageTypeReel) {
                        msgImg = msg.decodeContent(cl: MessageVideo.creator);
                      } else {
                        msgImg = messageList[index]['asset'];
                      }

                      if (messageList.isEmpty && isLoading.value) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        );
                      }

                      if (msg.id == 0 && msg.content.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Obx(
                        () => Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  if (widget.isGroup) {
                                    if (!groupInfoController!
                                        .onMoreSelect.value) {
                                      onShowMedia(index);
                                    } else {
                                      onItemTap(msg);
                                    }
                                  } else {
                                    if (!chatInfoController!
                                        .onMoreSelect.value) {
                                      onShowMedia(index);
                                    } else {
                                      onItemTap(msg);
                                    }
                                  }
                                },
                                onLongPress: () {
                                  if (widget.isGroup) {
                                    if (!groupInfoController!
                                        .onMoreSelect.value) {
                                      onItemLongPress(msg);
                                    }
                                  } else {
                                    if (!chatInfoController!
                                        .onMoreSelect.value) {
                                      onItemLongPress(msg);
                                    }
                                  }
                                },
                                child: LayoutBuilder(builder: (context, c) {
                                  return buildMedia(msgImg, c);
                                }),
                              ),
                            ),
                            IgnorePointer(child: _buildSelectedCover(msg)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildMedia(dynamic msgImg, BoxConstraints c) {
    if (msgImg is MessageImage ||
        (msgImg is AlbumDetailBean && msgImg.cover.isEmpty)) {
      return ForegroundOverlayEffect(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: JXColors.outlineColor, width: 0.5)),
          child: RemoteImage(
            src: msgImg.url,
            width: c.maxWidth,
            height: c.maxHeight,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          ),
        ),
      );
    } else if (msgImg is MessageVideo ||
        (msgImg is AlbumDetailBean && msgImg.cover.isNotEmpty)) {
      return ForegroundOverlayEffect(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
                child: RemoteImage(
              src: msgImg.cover,
              width: c.maxWidth,
              height: c.maxHeight,
              fit: BoxFit.cover,
              mini: Config().messageMin,
            )),
            Positioned.fill(child: _buildCover()),
          ],
        ),
      );
    } else {
      return Container(child: const Text("Null"));
    }
  }

  Widget _buildCover() {
    return Container(
      color: Colors.black.withAlpha(130),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/svgs/video_play_icon.svg',
        width: 40,
        height: 40,
      ),
    );
  }

  Widget _buildSelectedCover(Message message) {
    if (widget.isGroup) {
      if (groupInfoController!.selectedMessageList.contains(message)) {
        return Container(
          color: Colors.black.withOpacity(0.36),
          alignment: Alignment.center,
          child: const Icon(
            Icons.done,
            color: Colors.white,
            size: 48.0,
          ),
        );
      } else {
        return const SizedBox();
      }
    } else {
      if (chatInfoController!.selectedMessageList.contains(message)) {
        return Container(
          color: Colors.black.withOpacity(0.36),
          alignment: Alignment.center,
          child: const Icon(
            Icons.done,
            color: Colors.white,
            size: 48.0,
          ),
        );
      } else {
        return const SizedBox();
      }
    }
  }
}
