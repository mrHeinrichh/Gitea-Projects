import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownItem extends StatefulWidget {
  const MarkdownItem({
    super.key,
    required this.message,
    required this.messageMarkdown,
    required this.chat,
    required this.controller,
    required this.index,
  });

  final Message message;
  final MessageMarkdown messageMarkdown;
  final Chat chat;
  final ChatContentController controller;
  final int index;

  @override
  MarkdownItemState createState() => MarkdownItemState();
}

class MarkdownItemState extends MessageWidgetMixin<MarkdownItem> {
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;
  bool isSmallSecretary = false;

  @override
  void initState() {
    super.initState();

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(widget.controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
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
        widget.controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.controller.chat?.chat_id) {
      return;
    }
    if (data['message'] != null) {
      pdebug('on message delete');
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.controller.chat?.isSaveMsg ?? false) {
      sendID = widget.messageMarkdown.forward_user_id;
      if (widget.messageMarkdown.forward_user_name == 'Secretary') {
        isSmallSecretary = true;
      }
    }
    if (widget.controller.chat?.typ == chatTypeSmallSecretary) {
      isSmallSecretary = true;
    }
  }

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showPinned =>
      widget.controller.chatController.pinMessageList
          .firstWhereOrNull((pinnedMsg) => pinnedMsg.id == widget.message.id) !=
      null;

  bool get showNickName => false;

  bool get showReplyContent => false;

  bool get showForwardContent => false;

  bool get showAvatar => objectMgr.userMgr.isMe(widget.message.send_id)
      ? false
      : !widget.controller.chat!.isSystem &&
          !isSmallSecretary &&
          !widget.controller.chat!.isSingle &&
          (isLastMessage || widget.controller.chatController.isPinnedOpened);

  bool get showAvatarGroupChat {
    if (widget.controller.chat!.isSaveMsg) return true;
    if ((widget.controller.chat!.isGroup && showAvatar)) return true;
    return false;
  }

  // 是否私聊
  bool get isSingleOrSystem {
    return widget.controller.chatController.chat.isSingle ||
        widget.controller.chatController.chat.isSystem ||
        widget.controller.chatController.chat.isSecretary;
  }

  EdgeInsets getTextSpanPadding() {
    if (!showTranslationContent.value &&
        emojiUserList.isEmpty &&
        _readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: lineSpacing);
    }

    return EdgeInsets.only(bottom: 0.w);
  }

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  double get maxWidth =>
      jxDimension.groupTextSenderMaxWidth(hasAvatar: !isSingleOrSystem);

  double get extraWidth => getNewLineExtraWidth(
        showPinned: showPinned,
        isEdit: widget.message.edit_time > 0,
        isSender: true,
        emojiUserList: emojiUserList,
        groupTextMessageReadType: _readType,
        messageEmojiOnly: false,
        showReplyContent: showReplyContent,
        showTranslationContent: showTranslationContent.value,
      );

  double get textMaxHeight => (1 -
          ((MediaQuery.of(context).viewPadding.top +
                  76 +
                  52 +
                  34 +
                  MediaQuery.of(context).viewPadding.bottom) /
              844))
      .sh;

  @override
  Widget build(BuildContext context) {
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText:
          widget.messageMarkdown.text + widget.messageMarkdown.links.toString(),
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      isReceiver: false,
      showReplyContent: showReplyContent,
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: false,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
    );
    _readType = bean.type;
    Widget child = messageBody(context, bean: bean);
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: <Widget>[
                /// 示例
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (details) {
                    if (widget.controller.isCTRLPressed()) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          emojiSelector: EmojiSelector(
                            chat: widget.controller.chat!,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chat!,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.controller.chat!,
                            extr: false,
                          ),
                        ),
                      );
                    }
                    widget.controller.chatController.onCancelFocus();
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
                      enableFloatingWindow(
                        context,
                        widget.controller.chat!.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.controller.chat!,
                          sendID: widget.message.send_id,
                        ),
                        bubbleType: objectMgr.userMgr.isMe(message.send_id)
                            ? BubbleType.sendBubble
                            : BubbleType.receiverBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                          widget.message,
                          widget.controller.chat!,
                        ),
                        topWidget: isSmallSecretary ||
                                widget.controller.chatController.chat.isSystem
                            ? null
                            : EmojiSelector(
                                chat: widget.controller.chat!,
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
                            chat: widget.controller.chat!,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chat!,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.controller.chat!,
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
                  top: 0.0,
                  bottom: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    chatController: widget.controller.chatController,
                    message: widget.message,
                    chat: widget.controller.chat!,
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context, {required NewLineBean bean}) {
    double maxWidth =
        widget.messageMarkdown.width > 0 ? width.value : bean.calculatedWidth;
    double minW = bean.minWidth;
    BubblePosition position = getPosition();
    bool isMe = objectMgr.userMgr.isMe(message.send_id);
    return Obx(() {
      Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.messageMarkdown.forward_user_id != 0)
            MessageForwardComponent(
                forwardUserId: widget.messageMarkdown.forward_user_id,
                maxWidth: maxWidth,
                padding: EdgeInsets.fromLTRB(12.w, 4.w, 12.w, 0),
                isSender: !isMe),
          Container(
            padding: getTextSpanPadding(),
            constraints: BoxConstraints(
                minWidth: minWidth(maxWidth, minW), maxWidth: maxWidth),
            child: buildTextContent(
              context,
              showPinned,
              colorTextPrimary,
              maxWidth,
              minW,
              position == BubblePosition.isLastMessage,
              bean: bean,
            ),
          ),
        ],
      );

      position = getPosition();
      body = Padding(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: ChatBubbleBody(
          type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
          constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: showAvatar ? jxDimension.chatRoomAvatarSize() : 0),
          position: position,
          style: position == BubblePosition.isMiddleMessage
              ? BubbleStyle.round
              : BubbleStyle.tail,
          verticalPadding: 0,
          horizontalPadding: 0,
          isPressed: isPressed.value,
          isHighlight: widget.message.select == 1 ? true : false,
          body: body,
        ),
      );

      // no avatar need extra padding
      bool needExtraPadding = false;
      if (!showAvatar &&
          position != BubblePosition.isFirstMessage &&
          !widget.chat.isSystem) {
        needExtraPadding = true;
      }

      return Container(
        constraints: BoxConstraints(
          minHeight: showAvatar ? jxDimension.chatRoomAvatarSize() : 0,
        ),
        margin: isMe
            ? EdgeInsets.only(
                right: jxDimension.chatRoomSideMarginNoAva,
                bottom: isPinnedOpen ? 4 : 0,
              )
            : EdgeInsets.only(
                left: widget.controller.chatController.chooseMore.value
                    ? 40.w
                    : jxDimension.chatRoomSideMargin +
                        (needExtraPadding ? jxDimension.chatRoomSideMargin : 0),
                right: jxDimension.chatRoomSideMarginMaxGap,
                bottom: isPinnedOpen ? 4.w : 0,
              ),
        child: AbsorbPointer(
          absorbing: widget.controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: AlignmentDirectional.bottomEnd,
                      children: <Widget>[
                        body,
                        Positioned(
                          right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                          bottom: objectMgr.loginMgr.isDesktop ? 8 : 6.w,
                          child: ChatReadNumView(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            showPinned: showPinned,
                            sender: !isMe,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  BubblePosition getPosition() {
    BubblePosition position = isFirstMessage && isLastMessage
        ? BubblePosition.isFirstAndLastMessage
        : isLastMessage
            ? BubblePosition.isLastMessage
            : isFirstMessage
                ? BubblePosition.isFirstMessage
                : BubblePosition.isMiddleMessage;

    if (widget.controller.chatController.isPinnedOpened) {
      position = BubblePosition.isLastMessage;
    }
    return position;
  }

  double minWidth(double maxWidth, double minW) {
    double maxW = maxWidth;
    if (maxW > minW) {
      return minW;
    }
    return maxW;
  }

  Widget buildAvatar() {
    if (widget.controller.chat!.isSaveMsg) {
      return Container(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
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

    if (widget.controller.chat!.isGroup && showAvatar) {
      return CustomAvatar.normal(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
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
                  widget.controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: widget.controller.chatController.popupEnabled
          ? null
          : avatarWidgetKey,
      width: isSingleOrSystem ? 0 : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget buildTextContent(
    BuildContext context,
    bool showPinned,
    Color textColor,
    double maxW,
    double minW,
    bool isLastMessage, {
    required NewLineBean bean,
  }) {
    bool isMe = objectMgr.userMgr.isMe(message.send_id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: getTop(isLastMessage, bean, widget.messageMarkdown.text),
        ),

        // image
        if (widget.messageMarkdown.image.isNotEmpty)
          GestureDetector(
            onTap: () {
              widget.controller.showLargePhoto(context, message);
            },
            child: Padding(
              padding: EdgeInsets.only(
                  top: widget.messageMarkdown.forward_user_id != 0 ? 4.w : 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: widget.messageMarkdown.forward_user_id != 0
                          ? null
                          : BorderRadius.only(
                              topLeft: Radius.circular(
                                BubbleCorner.topLeftCorner(
                                  getPosition(),
                                  BubbleType.sendBubble,
                                ),
                              ),
                              topRight: Radius.circular(
                                BubbleCorner.topRightCorner(
                                  getPosition(),
                                  BubbleType.sendBubble,
                                ),
                              ),
                            ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RemoteImage(
                      src: widget.messageMarkdown.image,
                      width: widget.messageMarkdown.width > 0
                          ? width.value
                          : bean.calculatedWidth,
                    ),
                  ),
                  if (widget.messageMarkdown.video.isNotEmpty)
                    SvgPicture.asset(
                      key: ValueKey(
                        'messageSendState_${widget.message.id}',
                      ),
                      'assets/svgs/video_play_icon.svg',
                      width: 40,
                      height: 40,
                    ),
                ],
              ),
            ),
          ),

        // title
        buildTitle(),

        // markdown
        Container(
          constraints: BoxConstraints(
            maxHeight: isExpandReadMore.value ? textMaxHeight : double.infinity,
          ),
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 4),
          child: MarkdownBody(
            data: widget.messageMarkdown.text,
            styleSheet: MarkdownStyleSheet(
              p: jxTextStyle.textStyle17(),
              listBullet: jxTextStyle.textStyle17(),
              listIndent: 16.0,
              strong: TextStyle(
                fontWeight: MFontWeight.bold5.value,
              ),
            ),
            onTapLink: (linkText, linkUrl, value) async {
              if (linkUrl != null) {
                if (linkUrl.startsWith("directTo-")) {
                  String route = linkUrl.substring("directTo-".length);
                  Get.toNamed(route);
                } else {
                  Uri uri = Uri.parse(linkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              }
            },
            softLineBreak: true,
          ),
        ),

        // button link
        if (widget.messageMarkdown.links.isNotEmpty)
          ...List.generate(
            widget.messageMarkdown.links.length,
            (i) => OpacityEffect(
              child: GestureDetector(
                onTap: () async {
                  Uri uri = Uri.parse(widget.messageMarkdown.links[i]['href']!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 11.0, horizontal: 16.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorTextPlaceholder,
                        width: 0.33,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svgs/link_button.svg',
                        color: isMe ? bubblePrimary : themeColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.messageMarkdown.links[i]['label'] ?? '',
                          style: jxTextStyle
                              .textStyle17(
                                color: isMe ? bubblePrimary : themeColor,
                              )
                              .copyWith(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildTitle() {
    Widget titleWidget = const SizedBox();
    if (widget.messageMarkdown.version == 2) {
      titleWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          widget.messageMarkdown.title,
          style: jxTextStyle.headerText(
            fontWeight: MFontWeight.bold5.value,
            color: colorLink,
          ),
        ),
      );
    } else {
      titleWidget = Text(
        widget.messageMarkdown.title,
        style: jxTextStyle.headerText(
          fontWeight: MFontWeight.bold5.value,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: titleWidget,
    );
  }

  WidgetSpan textWidgetSpan() {
    return WidgetSpan(
      child: Container(
        width: extraWidth,
      ),
    );
  }

  /// 当消息在聊天室内，只有一条，并且只有一行，并且是连续消息中的最后一跳消息
  double getTop(bool isLastMessage, NewLineBean bean, String text) {
    /// 无用户名
    bool k1 =
        showNickName && !EmojiParser.hasOnlyEmojis(widget.messageMarkdown.text);

    /// 是否超过最大宽度
    bool k2 = bean.actualWidth < maxWidth - 24.w;

    ///是否是最后一条消息
    bool k3 = isLastMessage;

    /// 是否有换行
    bool k4 = text.contains("\n");
    if (!k1 && k2 && k3 && !k4 && showAvatar) {
      return 8.w;
    }
    return 0;
  }
}
