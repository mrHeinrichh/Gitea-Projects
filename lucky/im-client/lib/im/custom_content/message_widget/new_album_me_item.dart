import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/new_album_util.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/new_album_grid.dart';

class NewAlbumMeItem extends StatefulWidget {
  const NewAlbumMeItem({
    Key? key,
    required this.messageMedia,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final NewMessageMedia messageMedia;
  final Message message;
  final Chat chat;
  final int index;
  final isPrevious;

  @override
  State<NewAlbumMeItem> createState() => _NewAlbumMeItemState();
}

class _NewAlbumMeItemState extends State<NewAlbumMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  late NewMessageMedia messageMedia;

  static const double maxWidthRatio = 0.8;
  final emojiUserList = <EmojiModel>[].obs;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    messageMedia = widget.messageMedia;
    if (widget.message.asset != null) {
      prepopulateAssetToMedia();
    }

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      Message item = data['message'];
      if (item.id == widget.message.id) {
        widget.message.content = item.content;
        widget.message.edit_time = item.edit_time;
        widget.message.sendState = item.sendState;
      }
    }
  }

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        emojiUserList.value = data.emojis;
        emojiUserList.refresh();
      }
    }
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
    super.dispose();
  }

  void prepopulateAssetToMedia() {
    final assetList = widget.message.asset;

    for (int i = 0; i < assetList.length; i++) {
      AlbumDetailBean bean = messageMedia.albumList![i];
      bean.asset = assetList[i];
    }
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: <Widget>[
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (_) {
                    controller.chatController.onCancelFocus();
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
                      enableFloatingWindow(
                        context,
                        widget.chat.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                        ),
                        bubbleType: BubbleType.sendBubble,
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                            widget.message, widget.chat),
                        topWidget: EmojiSelector(
                          chat: widget.chat,
                          message: widget.message,
                          emojiMapList: emojiUserList,
                        ),
                      );
                      isPressed.value = false;
                    }
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      DesktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          isSender: true,
                          emojiSelector: EmojiSelector(
                            chat: widget.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
                        ),
                      );
                    }
                    isPressed.value = false;
                  },
                  child: child,
                ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: RepaintBoundary(
                    child: MoreChooseView(
                      chatController: controller.chatController,
                      message: widget.message,
                      chat: widget.chat,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      if (controller.chatController.isPinnedOpened) {
        position = BubblePosition.isLastMessage;
      }

      Widget body = ChatBubbleBody(
        position: position,
        type: BubbleType.sendBubble,
        isClipped: true,
        isPressed: isPressed.value,
        constraints: BoxConstraints(
          maxWidth: isDesktop
              ? 400
              : NewAlbumUtil.getMaxWidth(
                  messageMedia.albumList?.length ?? 0, maxWidthRatio),
        ),
        body: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.messageMedia.forward_user_id != 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 10.0,
                      top: bubbleInnerPadding,
                      bottom: bubbleInnerPadding,
                    ),
                    child: ChatSourceView(
                        forward_user_id: widget.messageMedia.forward_user_id,
                        maxWidth: jxDimension.groupTextMeMaxWidth(),
                        isSender: false),
                  ),
                if (widget.messageMedia.forward_user_id != 0)
                  const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: <Widget>[
                        NewAlbumGridView(
                          assetMessage: widget.message,
                          messageMedia: messageMedia,
                          onShowAlbum: (int index) {
                            if (controller.isCTRLPressed()) {
                              DesktopGeneralDialog(
                                context,
                                color: Colors.transparent,
                                widgetChild: DesktopMessagePopMenu(
                                  offset: tapPosition,
                                  isSender: true,
                                  emojiSelector: EmojiSelector(
                                    chat: widget.chat,
                                    message: widget.message,
                                    emojiMapList: emojiUserList,
                                  ),
                                  popMenu: ChatPopMenuSheet(
                                    message: widget.message,
                                    chat: widget.chat,
                                    sendID: widget.message.send_id,
                                  ),
                                  menuHeight: ChatPopMenuSheet.getMenuHeight(
                                      widget.message, widget.chat,
                                      extr: false),
                                ),
                              );
                            } else {
                              if (!widget.message.isSendOk) return;
                              controller.showLargePhoto(
                                context,
                                widget.message,
                                albumIdx: index,
                              );
                            }
                          },
                          isSender: false,
                          isForwardMessage:
                              widget.messageMedia.forward_user_id != 0,
                          isBorderRadius: true,
                        ),
                        if (isPressed.value)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: bubbleSideRadius(
                                  position,
                                  BubbleType.sendBubble,
                                ),
                                color: JXColors.outlineColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.messageMedia.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(bubbleInnerPadding),
                        child: Material(
                          color: Colors.transparent,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                ...BuildTextUtil.buildSpanList(
                                  widget.message,
                                  widget.messageMedia.caption,
                                  launchLink:
                                      controller.chatController.popupEnabled
                                          ? null
                                          : onLinkOpen,
                                  onMentionTap:
                                      controller.chatController.popupEnabled
                                          ? null
                                          : onMentionTap,
                                  openLinkPopup: (value) =>
                                      controller.chatController.popupEnabled
                                          ? null
                                          : onLinkLongPress(value, context),
                                  openPhonePopup: (value) =>
                                      controller.chatController.popupEnabled
                                          ? null
                                          : onPhoneLongPress(value, context),
                                  textColor: JXColors.chatBubbleMeTextColor,
                                  isSender: true,
                                ),
                                const WidgetSpan(child: SizedBox(width: 70)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: controller.chatController.pinMessageList
                        .firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
                    null,
                backgroundColor: widget.messageMedia.caption.isEmpty
                    ? JXColors.black48
                    : Colors.transparent,
                sender: false,
              ),
            ),
          ],
        ),
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.message.isSendOk)
                Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        widget.chat.typ == chatTypeSmallSecretary ? 0.0 : 20,
                    right: 4,
                  ),
                  child: _buildState(widget.message),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  body,

                  /// react emoji 表情栏
                  Obx(() {
                    List<Map<String, int>> emojiCountList = [];
                    emojiUserList.forEach((emoji) {
                      final emojiCountMap = {
                        MessageReactEmoji.emojiNameOldToNew(emoji.emoji):
                            emoji.uidList.length,
                      };
                      emojiCountList.add(emojiCountMap);
                    });

                    return Visibility(
                      visible: emojiUserList.length > 0,
                      child: GestureDetector(
                        onTap: () =>
                            controller.onViewReactList(context, emojiUserList),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 4.w),
                          child: EmojiListItem(
                            specialBgColor: true,
                            emojiModelList: emojiUserList,
                            message: widget.message,
                            controller: controller,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(key: Key(time.toString()), message: msg);
  }
}
