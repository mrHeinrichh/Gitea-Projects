import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_read_text_icon.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_reply_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupMiniAppShareMeItem extends StatefulWidget {
  const GroupMiniAppShareMeItem({
    super.key,
    required this.controller,
    required this.message,
    required this.messageText,
    required this.index,
    this.isPrevious = true,
  });

  final ChatContentController controller;
  final Message message;
  final MessageMiniAppShare messageText;
  final int index;
  final bool isPrevious;

  @override
  GroupMiniAppShareMeItemState createState() => GroupMiniAppShareMeItemState();
}

class GroupMiniAppShareMeItemState
    extends MessageWidgetMixin<GroupMiniAppShareMeItem> {
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;

  late Widget childBody;

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;
  double maxWidth = jxDimension.groupTextMeMaxWidth();

  double get extraWidth => getNewLineExtraWidth(
        showPinned: showPinned,
        isEdit: widget.message.edit_time > 0,
        isSender: false,
        emojiUserList: emojiUserList,
        groupTextMessageReadType: _readType,
        messageEmojiOnly: messageEmojiOnly,
        showReplyContent: showReplyContent,
        showTranslationContent: showTranslationContent.value,
      );

  ///76 top, 52 btm, 24 chatBubble padding
  double textMaxHeight(BuildContext context) => !mounted
      ? 1
      : (1 -
              ((MediaQuery.of(context).viewPadding.top +
                      76 +
                      52 +
                      30 +
                      MediaQuery.of(context).viewPadding.bottom) /
                  844))
          .sh;

  bool get showReplyContent => widget.messageText.reply.isNotEmpty;

  bool get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showPinned {
    return widget.controller.chatController.pinMessageList.firstWhereOrNull(
            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
        null;
  }

  bool get messageEmojiOnly {
    return widget.messageText.reply.isEmpty &&
        !(widget.messageText.forward_user_id != 0) &&
        EmojiParser.hasOnlyEmojis(widget.messageText.text);
  }

  @override
  void initState() {
    super.initState();

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(widget.controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;
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
    if (_readType == GroupTextMessageReadType.beakLineType &&
        !messageEmojiOnly) {
      return EdgeInsets.only(bottom: lineSpacing);
    }

    return EdgeInsets.zero;
  }

  @override
  Widget build(BuildContext context) {
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: "",
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      reply: null,
      showTranslationContent: showTranslationContent.value,
      translationText: "",
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
    childBody = messageBody(context, bean: bean);
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
                    if (widget.controller.isCTRLPressed()) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          isSender: true,
                          emojiSelector: EmojiSelector(
                            chat: widget.controller.chatController.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                              widget.message,
                              widget.controller.chatController.chat,
                              extr: false),
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
                      _showEnableFloatingWindow(context);
                      isPressed.value = false;
                    }
                  },
                  onDoubleTap: () async {
                    widget.controller.chatController.onDoubleTap(
                      message: widget.message,
                      text: widget.messageText.text,
                    );
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
                            chat: widget.controller.chatController.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                              widget.message,
                              widget.controller.chatController.chat,
                              extr: false),
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

  Widget messageBody(BuildContext context, {required NewLineBean bean}) {
    double maxWidth = bean.calculatedWidth;
    double minW = bean.minWidth;
    return Obx(() {
      Widget body = Column(
        crossAxisAlignment: messageEmojiOnly
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.messageText.reply.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.controller.chatController.popupEnabled
                  ? null
                  : () {
                      if (widget.controller.isCTRLPressed()) {
                        desktopGeneralDialog(
                          context,
                          color: Colors.transparent,
                          widgetChild: DesktopMessagePopMenu(
                            offset: tapPosition,
                            isSender: true,
                            emojiSelector: EmojiSelector(
                              chat: widget.controller.chatController.chat,
                              message: widget.message,
                              emojiMapList: emojiUserList,
                            ),
                            popMenu: ChatPopMenuSheet(
                              message: widget.message,
                              chat: widget.controller.chatController.chat,
                              sendID: widget.message.send_id,
                            ),
                            menuHeight: ChatPopMenuUtil.getMenuHeight(
                                widget.message,
                                widget.controller.chatController.chat,
                                extr: false),
                          ),
                        );
                      } else {
                        onPressReply(
                          widget.controller.chatController,
                          widget.message,
                        );
                      }
                    },
              child: MessageReplyComponent(
                replyModel: ReplyModel.fromJson(
                  json.decode(widget.messageText.reply),
                ),
                message: widget.message,
                chat: widget.controller.chatController.chat,
                maxWidth: getReplyMaxWidth(bean),
                controller: widget.controller,
              ),
            ),
          if (widget.messageText.forward_user_id != 0)
            MessageForwardComponent(
                forwardUserId: widget.messageText.forward_user_id,
                maxWidth: maxWidth,
                isSender: false),
          GestureDetector(
            onTap: () {
              if (!widget.controller.chatController.popupEnabled) {
                objectMgr.miniAppMgr
                    .onLaunchLinkOpen(widget.messageText.text, context);
              }
            },
            child: Container(
              padding: getTextSpanPadding(),
              child: buildTextContent(context, bean),
            ),
          ),
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

      List<Map<String, int>> emojiCountList = [];
      for (var emoji in emojiUserList) {
        final emojiCountMap = {
          emoji.emoji: emoji.uidList.length,
        };
        emojiCountList.add(emojiCountMap);
      }

      body = messageEmojiOnly
          ? body
          : ChatBubbleBody(
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
                maxWidth: getBubbleMaxWidth(
                    textWidth: maxWidth + 24.w > this.maxWidth
                        ? this.maxWidth
                        : maxWidth + 24.w,
                    emojiLen: emojiCountList.length,
                    extraWidth: extraWidth,
                    isSender: false),
                minWidth: getMinWidth(maxWidth, minW),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  body,

                  /// react emoji 表情栏
                  Obx(() {
                    return Visibility(
                      visible: emojiUserList.isNotEmpty,
                      child: GestureDetector(
                        onTap: () => widget.controller
                            .onViewReactList(context, emojiUserList),
                        child: EmojiListItem(
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: widget.controller,
                          eMargin: EmojiMargin.me,
                          isSender: true,
                          showPinned: showPinned,
                          messageEmojiOnly: messageEmojiOnly,
                        ),
                      ),
                    );
                  })
                ],
              ),
            );

      final bool isDesktop = objectMgr.loginMgr.isDesktop;
      double emojiSpace = isDesktop ? 4 : 2;
      final matches =
          EmojiParser.REGEX_EMOJI.allMatches(widget.messageText.text);
      final emojiLength = matches.length;

      if (messageEmojiOnly && !isDesktop) {
        if (emojiLength == 1) {
          emojiSpace = 2;
        }
      }

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
                  ? _buildMessageEmojiOnlyCell(
                      body, context, emojiSpace, emojiLength)
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
                            isPause: isPauseRead.value,
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

  Widget _buildMessageEmojiOnlyCell(
      Widget body, BuildContext context, double emojiSpace, int emojiLength) {
    if (objectMgr.loginMgr.isDesktop) {
      return _buildMessageEmojiOnlyDesktopCell(
          body, context, emojiSpace, emojiLength);
    } else {
      return Container(
        margin: EdgeInsets.symmetric(vertical: emojiSpace),
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
                  onTap: () =>
                      widget.controller.onViewReactList(context, emojiUserList),
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
      );
    }
  }

  Widget buildTextContent(BuildContext context, NewLineBean bean) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ImGap.vGap(6),
        _buildTitle(),
        ImGap.vGap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
         child: RemoteGaussianImage(
            src: widget.messageText.miniAppPicture,
            width: double.infinity,
            height: 167,
            fit: BoxFit.cover,
            gaussianPath: widget.messageText.miniAppPictureGaussian,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorTextPlaceholder,
                width: 0.3,
              ),
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/link2.svg',
                width: 16.67,
                height: 16.67,
                color: themeColor,
              ),
              ImGap.hGap4,
              Text(
                localized(chatMiniApp),
                style: jxTextStyle.textStyle13(color: colorTextSecondary),
              ),
            ],
          ),
        ),
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
    return widget.messageText.reply.isNotEmpty
        ? jxDimension.groupTextSenderReplySize()
        : showTranslationContent.value
            ? jxDimension.showTranslationContentMinSize()
            : 0;
  }

  Widget _buildMessageEmojiOnlyDesktopCell(
      Widget body, BuildContext context, double emojiSpace, int emojiLength) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: EdgeInsets.symmetric(vertical: emojiSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            emojiLength != 1
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      body,
                      ChatReadNumView(
                        message: widget.message,
                        chat: widget.controller.chatController.chat,
                        showPinned: showPinned,
                        backgroundColor: Colors.black26,
                        sender: false,
                      ),
                    ],
                  )
                : Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      body,
                      ChatReadNumView(
                        message: widget.message,
                        chat: widget.controller.chatController.chat,
                        showPinned: showPinned,
                        backgroundColor: Colors.black26,
                        sender: false,
                      ),
                    ],
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
                  onTap: () =>
                      widget.controller.onViewReactList(context, emojiUserList),
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
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: RemoteImageV2(
                key: ValueKey(widget.messageText.miniAppName),
                src: widget.messageText.miniAppAvatar,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                enableShimmer: false,
              ),
            ),
            ImGap.hGap(8),
            Text(
              widget.messageText.miniAppName,
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
            ),
          ],
        ),
        ImGap.vGap(6),

        Text(
          widget.messageText.miniAppTitle, //miniAppTip
          style: jxTextStyle.textStyle17(),
        )
      ],
    );
  }
}
