import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_read_text_icon.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';

class GroupEncryptedMeItem extends StatefulWidget {
  const GroupEncryptedMeItem({
    super.key,
    required this.controller,
    required this.message,
    required this.index,
    this.isPrevious = true,
  });

  final ChatContentController controller;
  final Message message;
  final int index;
  final bool isPrevious;

  @override
  GroupEncryptedMeItemState createState() => GroupEncryptedMeItemState();
}

class GroupEncryptedMeItemState extends State<GroupEncryptedMeItem>
    with MessageWidgetMixin {
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  var encryptedText = "";

  late Widget childBody;

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;
  double maxWidth = jxDimension.groupTextMeMaxWidth();

  double get extraWidth {
    return getNewLineExtraWidth(
          showPinned: showPinned,
          isEdit: false,
          isSender: false,
          emojiUserList: emojiUserList,
          groupTextMessageReadType: _readType,
          messageEmojiOnly: messageEmojiOnly,
          showReplyContent: showReplyContent,
          showTranslationContent: showTranslationContent.value,
        ) -
        17.w; //强制减去双钩区域
  }

  ///76 top, 52 btm, 24 chatBubble padding
  double get textMaxHeight => (1 -
          ((MediaQuery.of(context).viewPadding.top +
                  76 +
                  52 +
                  30 +
                  MediaQuery.of(context).viewPadding.bottom) /
              844))
      .sh;

  bool get showReplyContent => false;

  bool get isPinnedOpen => false;

  bool get showPinned {
    return false;
  }

  bool get messageEmojiOnly {
    return false;
  }

  @override
  void initState() {
    super.initState();
    encryptedText = localized(messageEncrypted);
    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(widget.controller.chatController, widget.index, widget.message);
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

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.controller.chat!.chat_id) {
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

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        widget.controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (widget.controller.chatController.popupEnabled) {
          return;
        }
        _showEnableFloatingWindow(context);
      },
    );
  }

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: lineSpacing);
    }

    return EdgeInsets.zero;
  }

  @override
  Widget build(BuildContext context) {
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: encryptedText,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      // reply: getReplyStr(widget.messageText.reply),
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      isReceiver: false,
      minWidth: 120.w,
    );
    _readType = bean.type;
    childBody = messageBody(bean: bean);
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
                /// 示例
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (details) {
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    isPressed.value = false;
                  },
                  onDoubleTap: () async {},
                  onSecondaryTapDown: (details) {
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
                      chatController: widget.controller.chatController,
                      message: widget.message,
                      chat: widget.controller.chatController.chat,
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
      widget.controller.chatController.chat.id,
      widget.message,
      childBody,
      targetWidgetKey,
      tapPosition,
      ChatPopMenuSheet(
        message: widget.message,
        chat: widget.controller.chatController.chat,
        sendID: widget.message.send_id,
      ),
      bubbleType: BubbleType.sendBubble,
      menuHeight: ChatPopMenuUtil.getMenuHeight(
          widget.message, widget.controller.chatController.chat),
      topWidget: EmojiSelector(
        chat: widget.controller.chatController.chat,
        message: widget.message,
        emojiMapList: emojiUserList,
      ),
    );
  }

  Widget messageBody({required NewLineBean bean}) {
    double maxWidth = bean.calculatedWidth;
    double minW = bean.minWidth;
    int lineCounts = bean.lineCounts;
    return Obx(() {
      Widget body = Column(
        crossAxisAlignment: messageEmojiOnly
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              padding: getTextSpanPadding(),
              child: buildTextContent(context, maxWidth, minW, lineCounts)),
        ],
      );

      // body = IntrinsicWidth(child: body);

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

      body = ChatBubbleBody(
        type: BubbleType.sendBubble,
        position: position,
        style: position == BubblePosition.isMiddleMessage
            ? BubbleStyle.round
            : BubbleStyle.tail,
        verticalPadding: chatBubbleBodyVerticalPadding,
        horizontalPadding: chatBubbleBodyHorizontalPadding,
        isPressed: isPressed.value,
        isHighlight: widget.message.select == 1 ? true : false,
        constraints: BoxConstraints(
            maxWidth: maxWidth, minWidth: getMinWidth(maxWidth, minW)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
          ],
        ),
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: EdgeInsets.only(
            // left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              messageEmojiOnly
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          body,
                          ChatReadNumView(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            showPinned: showPinned,
                            backgroundColor: Colors.black26,
                            sender: false,
                          ),

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
                                  specialBgColor: true,
                                  controller: widget.controller,
                                  isSender: true,
                                  showPinned: showPinned,
                                  messageEmojiOnly: messageEmojiOnly,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        body,
                        Positioned(
                          right: 12.w,
                          bottom: 5.w,
                          child: ChatReadNumView(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            showPinned: showPinned,
                            sender: false,
                          ),
                        ),
                        if (isPlayingSound.value || isWaitingRead.value)
                          MessageReadTextIcon(
                            isWaitingRead: isWaitingRead.value,
                            isMe: true,
                          ),
                      ],
                    ),
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

  Widget buildTextContent(
      BuildContext context, double maxW, double minW, int lineCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 文本
        ...[
          Container(
            constraints: BoxConstraints(
              maxWidth: /*messageTypeLink == widget.message.typ
                  ? getMessageLinkMaxWidth(widget.messageText.text, maxWidth)
                  : */
                  minTextWidth > maxW ? minTextWidth : maxW,
              minWidth: minTextWidth,
              maxHeight:
                  isExpandReadMore.value ? textMaxHeight : double.infinity,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    encryptedText,
                    isEmojiOnly: messageEmojiOnly,
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
                    textColor: colorTextPrimary,
                    isSender: true,
                  ),
                  if (_readType == GroupTextMessageReadType.inlineType &&
                      !messageEmojiOnly) // 解决点赞后的行间距问题
                    WidgetSpan(child: SizedBox(width: extraWidth)),
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
                isPressed.value = false;
              },
              child: Text(
                localized(readMore),
                style: jxTextStyle.textStyleBold17(color: colorReadColor),
              ),
            )
        ],
      ],
    );
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  getMinWidth(double maxWidth, double minW) {
    if (maxWidth > minW) {
      return minW;
    }
    return maxWidth;
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

  double get minTextWidth {
    return 0;
  }
}
