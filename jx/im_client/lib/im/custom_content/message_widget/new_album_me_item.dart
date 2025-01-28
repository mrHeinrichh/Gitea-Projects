import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_read_text_icon.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_translate_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/new_album_grid.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/new_album_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class NewAlbumMeItem extends StatefulWidget {
  const NewAlbumMeItem({
    super.key,
    required this.messageMedia,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  });

  final NewMessageMedia messageMedia;
  final Message message;
  final Chat chat;
  final int index;
  final bool isPrevious;

  @override
  State<NewAlbumMeItem> createState() => _NewAlbumMeItemState();
}

class _NewAlbumMeItemState extends MessageWidgetMixin<NewAlbumMeItem> {
  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  late Widget childBody;

  late NewMessageMedia messageMedia;

  final emojiUserList = <EmojiModel>[].obs;

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  get extraWidth =>
      setWidth(isPinnedOpen, widget.message.edit_time > 0, isMe: true);

  get maxWidth => isDesktop
      ? 400.0
      : NewAlbumUtil.getMaxWidth(messageMedia.albumList?.length ?? 0, 1.0);

  bool get showPinned {
    return controller.chatController.pinMessageList.firstWhereOrNull(
            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
        null;
  }

  bool get messageEmojiOnly {
    return widget.messageMedia.reply.isEmpty &&
        !(widget.messageMedia.forward_user_id != 0) &&
        EmojiParser.hasOnlyEmojis(widget.messageMedia.caption);
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

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

  void prepopulateAssetToMedia() {
    final assetList = widget.message.asset;

    for (int i = 0; i < assetList.length; i++) {
      AlbumDetailBean bean = messageMedia.albumList![i];
      bean.asset = assetList[i];
    }
  }

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: 12.w);
    }

    return EdgeInsets.zero;
  }

  @override
  Widget build(BuildContext context) {
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: widget.messageMedia.caption,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: widget.messageMedia.reply,
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      isReceiver: false,
    );
    _readType = bean.type;
    childBody = messageBody(context,
        maxWidth: bean.calculatedWidth, minW: bean.minWidth);

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
                      _showEnableFloatingWindow(context);
                      isPressed.value = false;
                    }
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      desktopGeneralDialog(
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
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
                            extr: false,
                          ),
                        ),
                      );
                    }
                    isPressed.value = false;
                  },
                  child: childBody,
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

  void _showEnableFloatingWindow(BuildContext context) {
    enableFloatingWindow(
      context,
      widget.chat.id,
      widget.message,
      childBody,
      targetWidgetKey,
      tapPosition,
      ChatPopMenuSheet(
        message: widget.message,
        chat: widget.chat,
        sendID: widget.message.send_id,
        mediaSubType: widget.messageMedia.caption.isNotEmpty
            ? MenuMediaSubType.subMediaNewAlbumTxt
            : MenuMediaSubType.none,
      ),
      bubbleType: BubbleType.sendBubble,
      menuHeight: ChatPopMenuUtil.getMenuHeight(
        widget.message,
        widget.chat,
        mediaSubType: widget.messageMedia.caption.isNotEmpty
            ? MenuMediaSubType.subMediaNewAlbumTxt
            : MenuMediaSubType.none,
      ),
      topWidget: EmojiSelector(
        chat: widget.chat,
        message: widget.message,
        emojiMapList: emojiUserList,
      ),
    );
  }

  Widget messageBody(BuildContext context,
      {required double maxWidth, required double minW}) {
    return Obx(() {
      final bool showPinned =
          controller.chatController.pinMessageList.firstWhereOrNull(
                (pinnedMsg) => pinnedMsg.id == widget.message.id,
              ) !=
              null;
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
                  messageMedia.albumList?.length ?? 0,
                  1.0,
                ),
        ),
        body: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.messageMedia.forward_user_id != 0)
                  MessageForwardComponent(
                    padding: forwardTitlePadding,
                    forwardUserId: widget.messageMedia.forward_user_id,
                    maxWidth: jxDimension.groupTextMeMaxWidth(),
                    isSender: false,
                  ),
                // if (widget.messageMedia.forward_user_id != 0)
                //   const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: <Widget>[
                        NewAlbumGridView(
                          maxContentWidth: maxWidth,
                          assetMessage: widget.message,
                          messageMedia: messageMedia,
                          onShowAlbum: (int index) async {
                            if (controller.isCTRLPressed()) {
                              desktopGeneralDialog(
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
                                  menuHeight: ChatPopMenuUtil.getMenuHeight(
                                    widget.message,
                                    widget.chat,
                                    extr: false,
                                  ),
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
                          controller: controller,
                        ),
                        if (isPressed.value)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    widget.messageMedia.forward_user_id != 0
                                        ? BorderRadius.zero
                                        : bubbleSideRadius(
                                            position,
                                            BubbleType.sendBubble,
                                          ),
                                color: colorTextPlaceholder,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.messageMedia.caption.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: bubbleInnerPadding,
                          vertical: 4.w,
                        ),
                        constraints:
                            BoxConstraints(maxWidth: maxWidth, minWidth: minW),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            /// 文本
                            if (showOriginalContent.value)
                              Container(
                                padding: getTextSpanPadding(),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      ...BuildTextUtil.buildSpanList(
                                        widget.message,
                                        widget.messageMedia.caption,
                                        launchLink: controller
                                                .chatController.popupEnabled
                                            ? null
                                            : onLinkOpen,
                                        onMentionTap: controller
                                                .chatController.popupEnabled
                                            ? null
                                            : onMentionTap,
                                        openLinkPopup: (value) => controller
                                                .chatController.popupEnabled
                                            ? null
                                            : onLinkLongPress(value, context),
                                        openPhonePopup: (value) => controller
                                                .chatController.popupEnabled
                                            ? null
                                            : onPhoneLongPress(value, context),
                                        textColor: colorTextPrimary,
                                        isSender: true,
                                      ),
                                      if (_readType ==
                                          GroupTextMessageReadType.inlineType)
                                        WidgetSpan(
                                          child: SizedBox(width: extraWidth),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            if (showTranslationContent.value)
                              MessageTranslateComponent(
                                chat: baseController.chat,
                                message: message,
                                controller: controller,
                                translatedText: translationText.value,
                                locale: translationLocale.value,
                                showDivider: showOriginalContent.value &&
                                    showTranslationContent.value,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12.w,
              bottom: 2.w,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: showPinned,
                backgroundColor: widget.messageMedia.caption.isEmpty
                    ? colorTextSecondary
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        body,

                        /// react emoji 表情栏
                        Obx(() {
                          List<Map<String, int>> emojiCountList = [];
                          for (var emoji in emojiUserList) {
                            final emojiCountMap = {
                              emoji.emoji: emoji.uidList.length,
                            };
                            emojiCountList.add(emojiCountMap);
                          }

                          return Visibility(
                            visible: emojiUserList.isNotEmpty,
                            child: GestureDetector(
                              onTap: () => controller.onViewReactList(
                                context,
                                emojiUserList,
                              ),
                              child: Container(
                                constraints: BoxConstraints(maxWidth: maxWidth),
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
                    ),
                  ),
                  if (isPlayingSound.value || isWaitingRead.value)
                    MessageReadTextIcon(
                      isWaitingRead: isWaitingRead.value,
                      isPause: isPauseRead.value,
                      isMe: true,
                    ),
                ],
              )),
              if (!widget.message.isSendOk)
                Padding(
                  padding: EdgeInsets.only(
                    left: objectMgr.loginMgr.isDesktop
                        ? 5
                        : !message.isSendFail
                            ? 0
                            : 5.w,
                    bottom: 1,
                  ),
                  child: _buildState(widget.message),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (controller.chatController.popupEnabled) {
          return;
        }
        _showEnableFloatingWindow(context);
      },
    );
  }
}
