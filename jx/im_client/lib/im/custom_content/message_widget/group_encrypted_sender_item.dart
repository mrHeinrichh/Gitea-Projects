import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_read_text_icon.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';

class GroupEncryptedSenderItem extends StatefulWidget {
  const GroupEncryptedSenderItem({
    super.key,
    required this.controller,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  });

  final ChatContentController controller;
  final Message message;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;

  @override
  GroupEncryptedSenderItemState createState() =>
      GroupEncryptedSenderItemState();
}

class GroupEncryptedSenderItemState
    extends MessageWidgetMixin<GroupEncryptedSenderItem> {
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;
  bool isSmallSecretary = false;
  var encryptedText = "".obs;

  @override
  void initState() {
    super.initState();

    encryptedText.value =
        getEncryptionText(widget.message, widget.controller.chat!);
    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventDecryptChat, _onDecryptChat);

    initMessage(widget.controller.chatController, widget.index, widget.message);

    getRealSendID();
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

  void _onDecryptChat(Object sender, Object type, Object? data) {
    if (data is int && data == widget.controller.chat?.chat_id) {
      encryptedText.value =
          getEncryptionText(widget.message, widget.controller.chat!);
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
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventDecryptChat, _onDecryptChat);
    super.dispose();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.controller.chat?.typ == chatTypeSmallSecretary) {
      isSmallSecretary = true;
    }
  }

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showPinned {
    return false; //不展示pinned
  }

  bool get showNickName =>
      (isFirstMessage || widget.controller.chatController.isPinnedOpened) &&
      !(showReplyContent &&
          widget.message.hasReply &&
          ReplyModel.fromJson(
                json.decode(widget.message.replyModel!),
              ).userId ==
              sendID) &&
      !showForwardContent &&
      widget.controller.chat!.isGroup &&
      !widget.controller.chat!.isSaveMsg;

  bool get showReplyContent => false;

  bool get showForwardContent => false;

  bool get showAvatar =>
      !widget.controller.chat!.isSystem &&
      !isSmallSecretary &&
      !widget.controller.chat!.isSingle &&
      (isLastMessage || widget.controller.chatController.isPinnedOpened);

  bool get messageEmojiOnly => false;

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
    if (emojiUserList.isEmpty &&
        _readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: lineSpacing);
    }

    return EdgeInsets.only(bottom: 0.w);
  }

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  double get maxWidth =>
      jxDimension.groupTextSenderMaxWidth(hasAvatar: !isSingleOrSystem);

  double get extraWidth {
    return getNewLineExtraWidth(
      showPinned: showPinned,
      isEdit: false,
      isSender: true,
      emojiUserList: emojiUserList,
      groupTextMessageReadType: _readType,
      messageEmojiOnly: messageEmojiOnly,
      showReplyContent: showReplyContent,
      showTranslationContent: showTranslationContent.value,
    );
  }

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
      messageText: encryptedText.value,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      isReceiver: true,
      // reply: getReplyStr(widget.messageText.reply),
      showReplyContent: showReplyContent,
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: messageEmojiOnly,
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
                    //不必做任何处理
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onDoubleTap: () {
                    //不必做任何处理
                  },
                  onLongPress: () {
                    //不必做任何处理
                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) {
                    //不必做任何处理
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
    double maxWidth = bean.calculatedWidth;
    double minW = bean.minWidth;
    final textColor = groupMemberColor(sendID);
    BubblePosition position = getPosition();
    return Obx(() {
      Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 昵称
          if (showNickName)
            isSmallSecretary
                ? Text(
                    localized(chatSecretary),
                    style: jxTextStyle.normalText(color: textColor),
                  )
                : NicknameText(
                    uid: sendID,
                    color: textColor,
                    fontWeight: MFontWeight.bold5.value,
                    overflow: TextOverflow.ellipsis,
                    fontSize: bubbleNicknameSize,
                    groupId: widget.controller.chat!.isGroup
                        ? widget.controller.chat!.id
                        : null,
                  ),

          Container(
            constraints: BoxConstraints(
                minWidth: minWidth(maxWidth, minW),
                maxWidth: /*messageTypeLink == widget.message.typ
                    ? getMessageLinkMaxWidth(widget.messageText.text, maxWidth)
                    : */
                    maxWidth),
            padding: getTextSpanPadding(),
            child: buildTextContent(context, showPinned, textColor, maxWidth,
                minW, position == BubblePosition.isLastMessage,
                bean: bean),
          ),
        ],
      );

      position = getPosition();
      body = messageEmojiOnly
          ? Padding(
              padding:
                  EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
              child: body,
            )
          : Container(
              padding:
                  EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
              constraints: const BoxConstraints(minHeight: 32),
              child: ChatBubbleBody(
                constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight:
                        showAvatar ? jxDimension.chatRoomAvatarSize() : 0),
                position: position,
                style: position == BubblePosition.isMiddleMessage
                    ? BubbleStyle.round
                    : BubbleStyle.tail,
                verticalPadding: chatBubbleBodyVerticalPadding,
                horizontalPadding: chatBubbleBodyHorizontalPadding,
                isPressed: isPressed.value,
                isHighlight: widget.message.select == 1 ? true : false,
                body: Column(
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
                          onTap: () => widget.controller
                              .onViewReactList(context, emojiUserList),
                          child: EmojiListItem(
                            emojiModelList: emojiUserList,
                            message: widget.message,
                            controller: widget.controller,
                            eMargin: EmojiMargin.sender,
                            showPinned: showPinned,
                            messageEmojiOnly: messageEmojiOnly,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );

      return Container(
        constraints: BoxConstraints(
          minHeight: showAvatar ? jxDimension.chatRoomAvatarSize() : 0,
        ),
        margin: EdgeInsets.only(
          // right: jxDimension.chatRoomSideMarginMaxGap,
          left: widget.controller.chatController.chooseMore.value
              ? 40.w
              : (widget.controller.chat!.typ == chatTypeGroup
                  ? jxDimension.chatRoomSideMargin
                  : jxDimension.chatRoomSideMarginSingle),
          bottom: isPinnedOpen ? 4.w : 0,
        ),
        child: AbsorbPointer(
          absorbing: widget.controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    messageEmojiOnly
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              body,
                              ChatReadNumView(
                                message: widget.message,
                                chat: widget.controller.chat!,
                                showPinned: showPinned,
                                backgroundColor: colorTextSecondary,
                                sender: true,
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                            ],
                          )
                        : Stack(
                            alignment: Alignment.topRight,
                            children: <Widget>[
                              body,
                              Positioned(
                                right: 12.w,
                                bottom: 6.w,
                                child: ChatReadNumView(
                                  message: widget.message,
                                  chat: widget.controller.chat!,
                                  showPinned: showPinned,
                                  sender: true,
                                ),
                              ),
                              if (isPlayingSound.value || isWaitingRead.value)
                                MessageReadTextIcon(
                                  isWaitingRead: isWaitingRead.value,
                                  isMe: false,
                                  isPause: isPauseRead.value,
                                ),
                            ],
                          ),

                    /// react emoji 表情栏
                    if (messageEmojiOnly)
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
                            onTap: () => widget.controller
                                .onViewReactList(context, emojiUserList),
                            child: Container(
                              margin: EdgeInsets.only(
                                left: jxDimension.chatBubbleLeftMargin,
                                bottom: 4,
                              ),
                              child: EmojiListItem(
                                emojiModelList: emojiUserList,
                                message: widget.message,
                                specialBgColor: true,
                                controller: widget.controller,
                                isSender: true,
                                messageEmojiOnly: messageEmojiOnly,
                              ),
                            ),
                          ),
                        );
                      }),
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
    double
        maxW = /*messageTypeLink == widget.message.typ
        ? getMessageLinkMaxWidth(widget.messageText.text, maxWidth)
        :*/
        maxWidth;
    if (maxW > minW) {
      return minW;
    }
    return maxW;
  }

  Widget buildAvatar() {
    if (widget.controller.chat!.isSaveMsg) {
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

    if (widget.controller.chat!.isGroup && showAvatar) {
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
                  widget.controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
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
    int lineCounts = bean.lineCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: getTop(isLastMessage, bean, encryptedText.value),
        ),

        /// 文本
        Container(
          constraints: BoxConstraints(
            maxHeight: isExpandReadMore.value ? textMaxHeight : double.infinity,
          ),
          child: Text.rich(
            TextSpan(
              style: jxTextStyle.normalBubbleText(textColor),
              children: [
                WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Column(
                      children: [
                        const SizedBox(height: 1),
                        SvgPicture.asset(
                          'assets/svgs/chat_icon_encrypted.svg',
                          height: 17.0,
                          width: 17.0,
                        ),
                      ],
                    )),
                ...BuildTextUtil.buildSpanList(
                  widget.message,
                  encryptedText.value,
                  isReply: showReplyContent,
                  isEmojiOnly: false,
                  // EmojiParser.hasOnlyEmojis(widget.messageText.text),
                  launchLink: widget.controller.chatController.popupEnabled
                      ? null
                      : onLinkOpen,
                  onMentionTap: widget.controller.chatController.popupEnabled
                      ? null
                      : onMentionTap,
                  openLinkPopup: (value) =>
                      widget.controller.chatController.popupEnabled
                          ? null
                          : onLinkLongPress(value, context),
                  openPhonePopup: (value) =>
                      widget.controller.chatController.popupEnabled
                          ? null
                          : onPhoneLongPress(value, context),
                  textColor: colorTextSecondary,
                ),
                if (_readType == GroupTextMessageReadType.inlineType &&
                    (!messageEmojiOnly || showReplyContent))
                  textWidgetSpan(), // 解决点赞后的行间距问题
              ],
            ),
            maxLines: isExpandReadMore.value ? textMaxHeight ~/ 22 : null,
            overflow: isExpandReadMore.value ? TextOverflow.ellipsis : null,
          ),
        ),
        if (textMaxHeight ~/ 22 < lineCounts && isExpandReadMore.value)
          GestureDetector(
            onTap: () {
              widget.controller.chatController
                  .openReadMoreTextEvent(widget.message);
            },
            child: Text(
              localized(readMore),
              style: jxTextStyle.textStyleBold17(color: colorReadColor),
            ),
          )
      ],
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
    bool k1 = showNickName && !EmojiParser.hasOnlyEmojis(encryptedText.value);

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

  double getReplyMaxWidth(NewLineBean bean) {
    double minX = jxDimension.groupTextSenderReplySize();
    double k = bean.actualWidth;
    if (bean.replyWidth != 0) {
      k = bean.replyWidth;
    }
    if (minX < k) {
      return k + 24.w;
    }
    double b = bean.actualWidth + extraWidth;
    if (b < maxWidth) {
      return b + 24.w;
    }
    return maxWidth;
  }
}
