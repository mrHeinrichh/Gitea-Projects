import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/new_album_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class NewAlbumSenderItem extends StatefulWidget {
  const NewAlbumSenderItem({
    super.key,
    required this.messageMedia,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  });

  final NewMessageMedia messageMedia;
  final Chat chat;
  final Message message;
  final int index;
  final bool isPrevious;

  @override
  State<NewAlbumSenderItem> createState() => _NewAlbumSenderItemState();
}

class _NewAlbumSenderItemState extends MessageWidgetMixin<NewAlbumSenderItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  int sendID = 0;

  get isPinnedOpen => controller.chatController.isPinnedOpened;
  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

  bool get showPinned =>
      controller.chatController.pinMessageList
          .firstWhereOrNull((pinnedMsg) => pinnedMsg.id == widget.message.id) !=
      null;

  double get extraWidth => setWidth(
        showPinned,
        widget.message.edit_time > 0,
      );

  double get maxWidth {
    if (isDesktop) return 400;
    return NewAlbumUtil.getMaxWidth(widget.messageMedia.albumList!.length, 1.0);
  }

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: 12.w);
    }

    return EdgeInsets.zero;
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

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageMedia.forward_user_id;
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

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

    // 计算文本宽带
    if (widget.messageMedia.albumList!.isNotEmpty) {
      _readType = caculateLastLineTextWidth(
        message: widget.message,
        messageText: widget.messageMedia.caption,
        maxWidth: maxWidth - 24,
        extraWidth: setWidth(isPinnedOpen, widget.message.edit_time > 0),
      );
    }

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
                          mediaSubType: widget.messageMedia.caption.isNotEmpty
                              ? MenuMediaSubType.subMediaNewAlbumTxt
                              : MenuMediaSubType.none,
                        ),
                        bubbleType: BubbleType.receiverBubble,
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
                  child: child,
                ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  top: 0.0,
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
      /// 消息内容
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

      Widget body = AnimatedContainer(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        duration: const Duration(milliseconds: 100),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ChatBubbleBody(
          position: position,
          isClipped: true,
          isPressed: isPressed.value,
          body: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.messageMedia.forward_user_id != 0 &&
                      !widget.chat.isSaveMsg)
                    MessageForwardComponent(
                      padding: forwardTitlePadding,
                      forwardUserId: widget.messageMedia.forward_user_id,
                      maxWidth: maxWidth,
                      isSender: true,
                    ),
                  // if (widget.messageMedia.forward_user_id != 0 &&
                  //     !widget.chat.isSaveMsg)
                  //   const SizedBox(height: 5),
                  Stack(
                    children: <Widget>[
                      NewAlbumGridView(
                        maxContentWidth: maxWidth,
                        assetMessage: widget.message,
                        messageMedia: widget.messageMedia,
                        onShowAlbum: (int index) {
                          if (controller.isCTRLPressed()) {
                            desktopGeneralDialog(
                              context,
                              color: Colors.transparent,
                              widgetChild: DesktopMessagePopMenu(
                                offset: tapPosition,
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
                                          BubbleType.receiverBubble,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          /// 文本
                          if (showOriginalContent.value)
                            Container(
                              // color: Colors.red,
                              padding: getTextSpanPadding(),
                              child: RichText(
                                text: TextSpan(
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
              Positioned(
                right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                bottom: objectMgr.loginMgr.isDesktop ? 8 : 4.w,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned: showPinned,
                  backgroundColor: widget.messageMedia.caption.isEmpty
                      ? colorTextSecondary
                      : Colors.transparent,
                  sender: true,
                ),
              ),
            ],
          ),
        ),
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            right: controller.chatController.chooseMore.value
                ? jxDimension.chatRoomSideMargin
                : jxDimension.chatRoomSideMarginMaxGap,
            left: controller.chatController.chooseMore.value
                ? 40.w
                : (widget.chat.typ == chatTypeSingle
                    ? jxDimension.chatRoomSideMarginSingle
                    : jxDimension.chatRoomSideMargin),
            bottom: isPinnedOpen ? 4.w : 0,
          ),
          constraints: BoxConstraints(
            maxWidth: isDesktop
                ? 400
                : NewAlbumUtil.getMaxWidth(
                    widget.messageMedia.albumList?.length ?? 0,
                    1.0,
                  ),
          ),
          child: AbsorbPointer(
            absorbing: controller.chatController.popupEnabled,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /// 头像
                Opacity(
                  opacity: showAvatar ? 1 : 0,
                  child: buildAvatar(),
                ),

                Expanded(
                    child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                margin: EdgeInsets.only(
                                  left: jxDimension.chatBubbleLeftMargin,
                                  bottom: 4.w,
                                ),
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
                    if (isPlayingSound.value || isWaitingRead.value)
                      MessageReadTextIcon(
                        isWaitingRead: isWaitingRead.value,
                        isPause: isPauseRead.value,
                        isMe: false,
                        right: 0,
                      ),
                  ],
                )),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (controller.chat!.isSaveMsg) {
      return Container(
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color(0xFFFFD08E),
              Color(0xFFFFECD2),
            ],
          ),
        ),
        child: const SavedMessageIcon(),
      );
    }

    if (controller.chat!.isSecretary) {
      return Image.asset(
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar.normal(
        sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(
                  RouteName.chatInfo,
                  arguments: {
                    "uid": sendID,
                  },
                  id: objectMgr.loginMgr.isDesktop ? 1 : null,
                );
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  HapticFeedback.mediumImpact();
                  controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }
}
