import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_info.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart'
    show getChatNameMap, linkToWebView, vibrate;
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class LinkView extends StatefulWidget {
  final Chat? chat;
  final bool isGroup;

  const LinkView({
    super.key,
    required this.chat,
    required this.isGroup,
  });

  @override
  State<LinkView> createState() => _LinkViewState();
}

class _LinkViewState extends MessageWidgetMixin<LinkView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  final List<TargetWidgetKeyModel> _keyList = [];

  bool singleAndNotFriend = false;

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
      if (widget.chat!.isSingle || widget.chat!.isSpecialChat) {
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
      loadLinkList();
    } else {
      singleAndNotFriend = true;
    }

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onLinkMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);
    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    }
  }

  _onLinkMessageUpdate(sender, type, data) {
    if (data['id'] != widget.chat?.id || data['message'] == null) {
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
      for (final asset in messageList) {
        Message? msg = asset;
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
        int index = messageList.indexOf(item);
        _keyList.removeAt(index);
        messageList.remove(item);
      }
    }
  }

  _onMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeLink) return;
      messageList
          .removeWhere((element) => element.message_id == data.message_id);
      return;
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeLink) return;
      if (data.isEncrypted) return;
      messageList.insert(0, data);
      _keyList.insert(
        0,
        TargetWidgetKeyModel(0, GlobalKey()),
      );
      for (int i = 0; i < messageList.length; i++) {
        final msg = messageList[i];
        if (data.id == msg.id && msg.message_id == 0) {
          messageList.remove(msg);
          _keyList.removeAt(i);
          break;
        }
      }
      return;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onLinkMessageUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);
    super.dispose();
  }

  loadLinkList() async {
    if (messageList.isEmpty) isLoading.value = true;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ? AND ref_typ == 0',
      [
        widget.chat!.id,
        messageList.isEmpty
            ? widget.chat!.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeLink,
      ],
      'DESC',
      null,
      null,
    );
    List<Message> mList = tempList
        .map<Message>((e) => Message()..init(e))
        .where((element) => !element.isDeleted && !element.isExpired)
        .toList();

    if (mList.isNotEmpty) messageList.addAll(mList);

    _keyList.assignAll(
      List.generate(
        messageList.length,
        (index) => TargetWidgetKeyModel(0, GlobalKey()),
      ),
    );

    isLoading.value = false;
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
    Get.back();
    if (widget.isGroup) {
      if (Get.isRegistered<GroupChatController>(
          tag: widget.chat!.id.toString())) {
        final groupController =
            Get.find<GroupChatController>(tag: widget.chat!.id.toString());
        groupController.clearSearching();
        groupController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    } else {
      if (Get.isRegistered<SingleChatController>(
          tag: widget.chat!.id.toString())) {
        final singleChatController =
            Get.find<SingleChatController>(tag: widget.chat!.id.toString());
        singleChatController.clearSearching();
        singleChatController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    }
  }

  bool linkIsSelected(int index) {
    return widget.isGroup
        ? groupInfoController!.selectedMessageList.contains(messageList[index])
        : chatInfoController!.selectedMessageList.contains(messageList[index]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: Platform.isAndroid
          ? () async {
              resetPopupWindow();
              return true;
            }
          : null,
      child: Obx(() {
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
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
            ),
          );
        }

        if (singleAndNotFriend && messageList.isEmpty) {
          return Center(
            child: Text(localized(noItemFoundAddThisUserFirst)),
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
              Padding(
                padding: EdgeInsets.only(
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0, bottom: 16),
                child: SvgPicture.asset(
                  'assets/svgs/empty_state.svg',
                  width: 60,
                  height: 60,
                ),
              ),
              Text(
                localized(noHistoryYet),
                style: jxTextStyle.headerText(
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style: jxTextStyle.normalText(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext builder, int index) {
                    Message msg = messageList[index];

                    Widget child = LinkItem(
                      message: msg,
                      messageLink: msg.decodeContent(cl: MessageLink.creator),
                      onMoreSelected: widget.isGroup
                          ? groupInfoController!.onMoreSelect.value
                          : chatInfoController!.onMoreSelect.value,
                    );
                    TargetWidgetKeyModel model = _keyList[index];

                    return Obx(
                      () => GestureDetector(
                        key: model.targetWidgetKey,
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          tapPosition = details.globalPosition;
                        },
                        onTap: () {
                          if (widget.isGroup) {
                            if (groupInfoController!.onMoreSelect.value &&
                                groupInfoController!
                                    .selectedMessageList.isEmpty) {
                              onItemTap(msg);
                            } else if (groupInfoController!.selectedMessageList
                                .contains(msg)) {
                              onItemTap(msg);
                            }
                          } else {
                            if (!chatInfoController!.onMoreSelect.value &&
                                chatInfoController!
                                    .selectedMessageList.isEmpty) {
                              onItemTap(msg);
                            } else if (chatInfoController!.selectedMessageList
                                .contains(msg)) {
                              onItemTap(msg);
                            }
                          }
                        },
                        onLongPress: () {
                          vibrate();
                          if (objectMgr.loginMgr.isDesktop) {
                            if (widget.isGroup) {
                              if (!groupInfoController!.onMoreSelect.value) {
                                onItemLongPress(msg);
                              }
                            } else {
                              if (!chatInfoController!.onMoreSelect.value) {
                                onItemLongPress(msg);
                              }
                            }
                          } else {
                            if (widget.chat != null) {
                              final msg = messageList[index];
                              enableFloatingWindowInfo(
                                context,
                                widget.chat!.id,
                                msg,
                                child,
                                model.targetWidgetKey,
                                tapPosition,
                                ChatPopMenuSheetInfo(
                                  message: msg,
                                  chat: widget.chat!,
                                  sendID: msg.send_id,
                                  menuClick: (String title) {
                                    resetPopupWindow();
                                  },
                                ),
                                chatPopAnimationType:
                                    ChatPopAnimationType.right,
                                menuHeight: ChatPopMenuSheetInfo.getMenuHeight(
                                  msg,
                                  widget.chat!,
                                ),
                              );
                            }
                          }
                        },
                        child: Stack(
                          children: <Widget>[
                            child,
                            if (linkIsSelected(index))
                              const Positioned(
                                left: 0.0,
                                right: 0.0,
                                bottom: 0.0,
                                top: 0.0,
                                child: ColoredBox(color: colorBackground6),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: messageList.length,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}

class LinkItem extends StatefulWidget {
  final Message message;
  final MessageLink messageLink;
  final bool onMoreSelected;

  /// for searchView only
  final bool? isSearch;

  const LinkItem({
    super.key,
    required this.message,
    required this.messageLink,
    required this.onMoreSelected,
    this.isSearch = false,
  });

  Map<String, String> get chatNameMap {
    if (isSearch == true) {
      return getChatNameMap(message);
    } else {
      return {};
    }
  }

  @override
  State<LinkItem> createState() => _LinkItemState();
}

class _LinkItemState extends State<LinkItem> {
  final RxString source = ''.obs;
  CancelToken thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();

    _preloadImageSync();
  }

  _preloadImageSync() {
    if (widget.messageLink.linkPreviewData == null) return;
    if (widget.messageLink.linkImageSrc.isEmpty) return;

    source.value =
        imageMgr.getBlurHashSavePath(widget.messageLink.linkImageSrc);

    // print(
    //     "Check link view 1: ${widget.messageLink.linkImageSrc} | ${source.value}");

    if (source.value.isNotEmpty && !File(source.value).existsSync()) {
      imageMgr.genBlurHashImage(
        widget.messageLink.linkImageSrcGaussian,
        widget.messageLink.linkImageSrc,
      );
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      widget.messageLink.linkImageSrc,
      mini: Config().messageMin,
    );

    // print("Check link view 2: ${thumbPath}");

    if (thumbPath != null) {
      source.value = widget.messageLink.linkImageSrc;
      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    DownloadResult result = await downloadMgrV2.download(
      widget.messageLink.linkImageSrc,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
    );
    final thumbPath = result.localPath;
    // final thumbPath = await downloadMgr.downloadFile(
    //   widget.messageLink.linkImageSrc,
    //   mini: Config().messageMin,
    //   priority: 3,
    //   cancelToken: thumbCancelToken,
    // );

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = widget.messageLink.linkImageSrc;
      return;
    }
  }

  String? get msgUrl => widget.messageLink.linkPreviewData == null
      ? Regular.extractLink(widget.messageLink.text)
          .firstOrNull
          ?.groups([0]).firstOrNull
      : widget.messageLink.linkPreviewData!.url;

  @override
  Widget build(BuildContext context) {
    // print(
    //     "Check link: ${widget.messageLink.linkImageSrc} | ${widget.messageLink.linkImageSrcGaussian} | ${source.value}");
    final linkPreviewData = widget.messageLink.linkPreviewData;
    final hasMedia = linkPreviewData?.hasMedia ?? false;

    return IgnorePointer(
      ignoring: widget.onMoreSelected,
      child: GestureDetector(
        onTap: msgUrl != null
            ? () => linkToWebView(
                  msgUrl!,
                  useInternalWebView: false,
                )
            : null,
        child: OverlayEffect(
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            decoration: BoxDecoration(
              border: customBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 链接图标
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasMedia ? colorGrey : colorOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: hasMedia
                      ? _buildAsset(context, linkPreviewData!)
                      : Text(
                          linkPreviewData?.title?.substring(0, 1) ??
                              (msgUrl != null &&
                                      notBlank(Uri.parse(msgUrl!).host)
                                  ? Uri.parse(msgUrl!).host.substring(0, 1)
                                  : 'W'),
                          style: jxTextStyle.textStyleBold24(color: colorWhite),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                ),

                /// 链接标题 + 链接地址
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        linkPreviewData?.title ??
                            (msgUrl != null ? Uri.parse(msgUrl!).host : 'W'),
                        style: jxTextStyle.headerText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (linkPreviewData?.desc != null)
                        Text(
                          linkPreviewData!.desc!,
                          style: jxTextStyle.supportText(
                            color: colorTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (msgUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            linkPreviewData?.url ?? msgUrl!,
                            style: jxTextStyle.normalSmallText(
                              color: themeColor,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            FormatTime.getFullDayTime(
                                widget.message.create_time),
                            style: jxTextStyle.normalSmallText(
                              color: colorTextSecondary,
                            ),
                          ),
                          Expanded(
                            child: Visibility(
                              visible: widget.chatNameMap.isNotEmpty,
                              child: Row(
                                children: [
                                  Text(
                                    ' · ',
                                    style: jxTextStyle.normalSmallText(
                                      color: colorTextSecondary,
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.30),
                                    child: Text(
                                      widget.chatNameMap['first'] ?? '',
                                      style: jxTextStyle.normalSmallText(
                                        color: colorTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                    color: colorTextSecondary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.chatNameMap['second'] ?? '',
                                      style: jxTextStyle.normalSmallText(
                                        color: colorTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAsset(BuildContext context, Metadata linkPreviewData) {
    return Obx(
      () {
        final filePath = downloadMgrV2.getLocalPath(linkPreviewData.image!);
        final remoteFileExist = downloadMgrV2.getLocalPath(
              widget.messageLink.linkImageSrc,
              mini: Config().messageMin,
            ) !=
            null;

        final fileExist = objectMgr.userMgr.isMe(widget.message.send_id) &&
            filePath != null &&
            File(filePath).existsSync() &&
            !remoteFileExist;

        // check local file exist
        return RemoteImageV2(
          src: fileExist ? filePath : source.value,
          width: 40.0,
          height: 40.0,
          fit: BoxFit.cover,
          mini: source.value ==
                      imageMgr.getBlurHashSavePath(
                          widget.messageLink.linkImageSrc) ||
                  fileExist
              ? null
              : Config().messageMin,
        );
      },
    );
  }
}
