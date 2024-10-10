import 'dart:convert';
import 'dart:io';

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
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/link_analyzer/link_analyzer.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart' show linkToWebView, vibrate;
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/utils/format_time.dart';

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

class _LinkViewState extends State<LinkView>
    with AutomaticKeepAliveClientMixin, MessageWidgetMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;
  final metadataList = <Metadata>[].obs;

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
      messageList.insert(0, data);
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
            'chat_id = ? AND chat_idx > ? AND typ = ?',
            [
              widget.chat!.id,
              messageList.isEmpty
                  ? widget.chat!.hide_chat_msg_idx
                  : messageList.last.chat_idx - 1,
              messageTypeLink
            ],
            'DESC',
            null);
    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    mList = mList
        .where((element) => !element.isDeleted && !element.isExpired)
        .toList();

    if (mList.isNotEmpty) {
      messageList.addAll(mList);
      for (Message msg in mList) {
        MessageText msgText = msg.decodeContent(cl: MessageText.creator);
        List<RegExpMatch> matches = Regular.extractLink(msgText.text);
        if (matches.length > 1) {
          for (int i = 1; i < matches.length; i++) {
            final match = matches[i];
            int msgIdx = messageList.indexOf(msg);
            Message tempMsg = Message()..init(msg.toJson());
            tempMsg.content = jsonEncode({
              'text': msgText.text.substring(match.start, match.end),
            });
            messageList.insert(msgIdx, tempMsg);
          }
        }

        for (final match in matches) {
          String url =
              msgText.text.substring(match.start, match.end).toLowerCase();
          if (!url.startsWith('http')) {
            url = 'http://$url';
          }
          try {
            LinkAnalyzer.getInfoClientSide(url).then((value) {
              Metadata? metadata = value;
              if (metadata != null) {
                metadataList.add(metadata);
              } else {
                metadataList.add(Metadata()
                  ..url = url
                  ..title = url);
              }
            });
          } catch (error) {
            pdebug(error);
            metadataList.add(
              Metadata()
                ..url = url
                ..title = url,
            );
            continue;
          }
        }
      }
    }

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
      onWillPop: Platform.isAndroid ? () async {
        resetPopupWindow();
        return true;
      }: null,
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
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
                child: SvgPicture.asset(
                  'assets/svgs/empty_state.svg',
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localized(noHistoryYet),
                style: jxTextStyle.textStyleBold16(),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style: jxTextStyle.textStyle14(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          if (widget.isGroup) {
            groupInfoController?.setUpItemKey(messageList, _keyList);
          } else {
            chatInfoController?.setUpItemKey(messageList, _keyList);
          }
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
                      // metadata: metadataList.length > index
                      //     ? metadataList[index]
                      //     : null,
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
                                child: ColoredBox(
                                  color: colorBorder,
                                ),
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

class LinkItem extends StatelessWidget {
  final Metadata? metadata;
  final Message message;
  final bool onMoreSelected;

  const LinkItem({
    super.key,
    required this.message,
    required this.onMoreSelected,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    RegExpMatch? match =
        Regular.extractLink(message.decodeContent(cl: MessageText.creator).text)
            .firstOrNull;

    String url = "";
    if (match != null) {
      url = message
          .decodeContent(cl: MessageText.creator)
          .text
          .substring(match.start, match.end)
          .toLowerCase();
    } else {
      url = message.decodeContent(cl: MessageText.creator).text;
    }

    if (!url.startsWith('http')) {
      url = 'http://$url';
    }

    return IgnorePointer(
      ignoring: onMoreSelected,
      child: GestureDetector(
        onTap: () => linkToWebView(metadata != null ? metadata!.url! : url),
        child: OverlayEffect(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
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
                    color: colorOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/link_icon.svg',
                    width: 24,
                    height: 20,
                    fit: BoxFit.fill,
                  ),
                ),

                /// 链接标题 + 链接地址
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    decoration: BoxDecoration(
                      border: customBorder,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                metadata?.title ?? url,
                                style: jxTextStyle.textStyleBold16(
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                metadata?.url ?? url,
                                style: jxTextStyle.textStyle12(
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          FormatTime.chartTime(
                            message.create_time,
                            true,
                            todayShowTime: true,
                            dateStyle: DateStyle.MMDDYYYY,
                          ),
                          style: jxTextStyle.textStyle14(
                            color: colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}
