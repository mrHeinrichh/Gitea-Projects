import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';

import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class GroupTextMeItem extends StatefulWidget {
  const GroupTextMeItem({
    Key? key,
    required this.controller,
    required this.message,
    required this.messageText,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final ChatContentController controller;
  final Message message;
  final MessageText messageText;
  final int index;
  final isPrevious;

  @override
  _GroupTextMeItemState createState() => _GroupTextMeItemState();
}

class _GroupTextMeItemState extends State<GroupTextMeItem>
    with MessageWidgetMixin {
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;

  @override
  void initState() {
    super.initState();

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

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

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

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

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.controller.chat!.chat_id) {
      return;
    }
    if (data['message'] != null) {
      Message item = data['message'];
      if (item.id == widget.message.id) {
        widget.message.content = item.content;
        widget.message.edit_time = item.edit_time;
        widget.message.sendState = item.sendState;
        MessageText edit_msg = item.decodeContent(cl: MessageText.creator);
        widget.messageText.text = edit_msg.text;
        //暂时使用此方法刷新，后面需要替换成高效的方式
        setState(() {});
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

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody();

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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
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
                      enableFloatingWindow(
                        context,
                        widget.controller.chatController.chat.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.controller.chatController.chat,
                          sendID: widget.message.send_id,
                        ),
                        bubbleType: BubbleType.sendBubble,
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                            widget.message,
                            widget.controller.chatController.chat),
                        topWidget: EmojiSelector(
                          chat: widget.controller.chatController.chat,
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
                            chat: widget.controller.chatController.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message,
                              widget.controller.chatController.chat,
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

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(key: Key(time.toString()), message: msg);
  }

  Widget messageBody() {
    return Obx(() {
      final bool showPinned = widget.controller.chatController.pinMessageList
              .firstWhereOrNull(
                  (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
          null;

      bool messageEmojiOnly = widget.messageText.reply.isEmpty &&
          !(widget.messageText.forward_user_id != 0) &&
          EmojiParser.hasOnlyEmojis(widget.messageText.text);

      Widget body = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.messageText.reply.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.controller.chatController.popupEnabled
                    ? null
                    : () {
                        if (widget.controller.isCTRLPressed()) {
                          DesktopGeneralDialog(
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
                              menuHeight: ChatPopMenuSheet.getMenuHeight(
                                  widget.message,
                                  widget.controller.chatController.chat,
                                  extr: false),
                            ),
                          );
                        } else
                          onPressReply(
                            widget.controller.chatController,
                            widget.message,
                          );
                      },
                child: GroupReplyItem(
                  replyModel: ReplyModel.fromJson(
                    json.decode(widget.messageText.reply),
                  ),
                  message: widget.message,
                  chat: widget.controller.chatController.chat,
                  maxWidth: jxDimension.groupTextMeMaxWidth(),
                  controller: widget.controller,
                ),
              ),
            if (widget.messageText.forward_user_id != 0)
              ChatSourceView(
                  forward_user_id: widget.messageText.forward_user_id,
                  maxWidth: jxDimension.groupTextMeMaxWidth(),
                  isSender: false),

            /// 文本
            Container(
              constraints: BoxConstraints(
                maxWidth: jxDimension.groupTextMeMaxWidth(),
                minWidth: widget.messageText.reply.isNotEmpty
                    ? jxDimension.groupTextSenderReplySize()
                    : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: Text.rich(
                  TextSpan(
                    children: [
                      ...BuildTextUtil.buildSpanList(
                        widget.message,
                        widget.messageText.text,
                        isReply: widget.messageText.reply.isNotEmpty,
                        isEmojiOnly:
                            EmojiParser.hasOnlyEmojis(widget.messageText.text),
                        launchLink:
                            widget.controller.chatController.popupEnabled
                                ? null
                                : onLinkOpen,
                        onMentionTap:
                            widget.controller.chatController.popupEnabled
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
                        textColor: JXColors.chatBubbleMeTextColor,
                        isSender: true,
                      ),
                      if (!EmojiParser.hasOnlyEmojis(widget.messageText.text) ||
                          widget.messageText.reply.isNotEmpty) // 解决点赞后的行间距问题
                        WidgetSpan(
                          child: SizedBox(width: showPinned ? 75 : 60),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

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

      body = messageEmojiOnly
          ? body
          : ChatBubbleBody(
              type: BubbleType.sendBubble,
              position: position,
              style: position == BubblePosition.isMiddleMessage
                  ? BubbleStyle.round
                  : BubbleStyle.tail,
              verticalPadding: 6,
              horizontalPadding: 11.5,
              isPressed: isPressed.value,
              isHighlight: widget.message.select == 1 ? true : false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        onTap: () => widget.controller
                            .onViewReactList(context, emojiUserList),
                        child: EmojiListItem(
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: widget.controller,
                          eMargin: EmojiMargin.me,
                          isSender: true,
                        ),
                      ),
                    );
                  })
                ],
              ),
            );

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen
                ? objectMgr.loginMgr.isDesktop
                    ? 4
                    : 4.w
                : 0,
          ),
          constraints: BoxConstraints(
            maxWidth: jxDimension.groupTextSenderMaxWidth() +
                (widget.message.isSendOk ? 30 : 0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.message.isSendOk)
                Padding(
                  padding: EdgeInsets.only(
                      right: objectMgr.loginMgr.isDesktop ? 4 : 4.w),
                  child: _buildState(widget.message),
                ),
              messageEmojiOnly
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        EmojiParser.hasOnlyEmojis(widget.messageText.text) &&
                                widget.messageText.text.runes.length == 1
                            ? Stack(
                                children: [
                                  body,
                                  Positioned(
                                    bottom: 10,
                                    right: 0,
                                    child: ChatReadNumView(
                                      message: widget.message,
                                      chat:
                                          widget.controller.chatController.chat,
                                      showPinned: showPinned,
                                      backgroundColor: Colors.black26,
                                      sender: false,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
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
                                ],
                              ),

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
                              onTap: () => widget.controller
                                  .onViewReactList(context, emojiUserList),
                              child: EmojiListItem(
                                emojiModelList: emojiUserList,
                                message: widget.message,
                                specialBgColor: true,
                                controller: widget.controller,
                                isSender: true,
                              ),
                            ),
                          );
                        }),
                      ],
                    )
                  : Stack(
                      children: [
                        body,
                        Positioned(
                          right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                          bottom: objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                          child: ChatReadNumView(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            showPinned: showPinned,
                            sender: false,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }
}
