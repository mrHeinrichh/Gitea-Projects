import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/main.dart';
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
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class GroupTextSenderItem extends StatefulWidget {
  const GroupTextSenderItem({
    Key? key,
    required this.controller,
    required this.messageText,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  }) : super(key: key);
  final ChatContentController controller;
  final Message message;
  final MessageText messageText;
  final int index;
  final isPrevious;
  final bool isPinOpen;

  @override
  _GroupTextSenderItemState createState() => _GroupTextSenderItemState();
}

class _GroupTextSenderItemState extends State<GroupTextSenderItem>
    with MessageWidgetMixin {
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
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

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
      print('on message delete');
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

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.controller.chat?.chat_id) {
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

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.controller.chat?.isSaveMsg ?? false) {
      sendID = widget.messageText.forward_user_id;
      if (widget.messageText.forward_user_name == 'Secretary') {
        isSmallSecretary = true;
      }
    }
    if (widget.controller.chat?.typ == chatTypeSmallSecretary) {
      isSmallSecretary = true;
    }
  }

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody();

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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.controller.chat!,
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
                        bubbleType: BubbleType.receiverBubble,
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                            widget.message, widget.controller.chat!),
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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.controller.chat!,
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
                  top: 0.0,
                  bottom: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    chatController: widget.controller.chatController,
                    message: widget.message,
                    chat: widget.controller.chat!,
                  ),
                )
              ],
            ),
    );
  }

  bool get showPinned =>
      widget.controller.chatController.pinMessageList
          .firstWhereOrNull((pinnedMsg) => pinnedMsg.id == widget.message.id) !=
      null;

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

  bool get showReplyContent => widget.messageText.reply.isNotEmpty;

  bool get showForwardContent =>
      widget.messageText.forward_user_id != 0 &&
      !widget.controller.chat!.isSaveMsg;

  bool get showAvatar =>
      !widget.controller.chat!.isSystem &&
      !isSmallSecretary &&
      !widget.controller.chat!.isSingle &&
      (isLastMessage || widget.controller.chatController.isPinnedOpened);

  Widget messageBody() {
    final textColor = groupMemberColor(sendID);
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 昵称
            if (showNickName &&
                !EmojiParser.hasOnlyEmojis(widget.messageText.text))
              isSmallSecretary
                  ? Text(
                      localized(chatSecretary),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: MFontWeight.bold5.value,
                        decoration: TextDecoration.none,
                        fontFamily: appFontfamily,
                        fontSize: 14,
                      ),
                    )
                  : NicknameText(
                      uid: sendID,
                      color: textColor,
                      fontWeight: Platform.isAndroid
                          ? MFontWeight.bold5.value
                          : MFontWeight.bold6.value,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                    ),
            // if (showNickName)
            //   const SizedBox(
            //     height: 2,
            //   ),
            if (showReplyContent)
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
                              menuHeight: ChatPopMenuSheet.getMenuHeight(
                                  widget.message, widget.controller.chat!,
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
                  chat: widget.controller.chat!,
                  maxWidth: jxDimension.groupTextSenderMaxWidth(
                      isMoreChoose:
                          widget.controller.chatController.chooseMore.value),
                  controller: widget.controller,
                ),
              ),

            if (showForwardContent)
              ChatSourceView(
                forward_user_id: widget.messageText.forward_user_id,
                maxWidth: jxDimension.groupTextMeMaxWidth(),
                isSender: true,
              ),

            if (widget.controller.chat!.isSystem) ...{
              Material(
                color: Colors.transparent,
                child: Text.rich(
                  TextSpan(
                    children: [
                      HTML.toTextSpan(
                          defaultTextStyle: jxTextStyle
                              .normalBubbleText(JXColors.primaryTextBlack),
                          context,
                          widget.messageText.richText.isEmpty
                              ? widget.messageText.text
                              : widget.messageText.richText,
                          linksCallback: (dynamic link) {
                        pdebug('You clicked on ${link.toString()}');
                        onLinkLongPress(link.toString(), context);
                      }),
                      WidgetSpan(
                        child: SizedBox(width: showPinned ? 55.w : 40.w),
                      ),
                    ],
                  ),
                ),
              )
            } else ...{
              /// 文本
              Container(
                constraints: BoxConstraints(
                  minWidth: widget.messageText.reply.isNotEmpty
                      ? jxDimension.groupTextSenderReplySize()
                      : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Text.rich(
                    TextSpan(
                      style: jxTextStyle.normalBubbleText(textColor),
                      children: [
                        ...BuildTextUtil.buildSpanList(
                          widget.message,
                          widget.messageText.text,
                          isReply: showReplyContent,
                          isEmojiOnly: EmojiParser.hasOnlyEmojis(
                              widget.messageText.text),
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
                          textColor: JXColors.chatBubbleSenderTextColor,
                        ),
                        if (!EmojiParser.hasOnlyEmojis(
                                widget.messageText.text) ||
                            showReplyContent ||
                            emojiUserList.length <= 11) // 解决点赞后的行间距问题
                          WidgetSpan(
                            child: SizedBox(width: showPinned ? 55 : 40),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            }
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

      bool messageEmojiOnly = widget.messageText.reply.isEmpty &&
          !(widget.messageText.forward_user_id != 0) &&
          EmojiParser.hasOnlyEmojis(widget.messageText.text);

      body = messageEmojiOnly
          ? Padding(
              padding:
                  EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
              child: body,
            )
          : Container(
              padding:
                  EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
              constraints: const BoxConstraints(
                minHeight: 32,
              ),
              child: ChatBubbleBody(
                position: position,
                style: position == BubblePosition.isMiddleMessage
                    ? BubbleStyle.round
                    : BubbleStyle.tail,
                verticalPadding: 6,
                horizontalPadding: 12,
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
                            eMargin: EmojiMargin.sender,
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
            );

      return Container(
        margin: EdgeInsets.only(
          right: jxDimension.chatRoomSideMarginMaxGap,
          left: widget.controller.chatController.chooseMore.value
              ? 40.w
              : (widget.controller.chat!.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginSingle
                  : jxDimension.chatRoomSideMargin),
          bottom: isPinnedOpen ? 4.w : 0,
        ),
        constraints: objectMgr.loginMgr.isDesktop
            ? BoxConstraints(
                maxWidth: jxDimension.groupTextSenderMaxWidth() +
                    (widget.message.isSendOk ? 30 : 0),
              )
            : null,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EmojiParser.hasOnlyEmojis(
                                          widget.messageText.text) &&
                                      widget.messageText.text.runes.length == 1
                                  ? Stack(
                                      children: [
                                        body,
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: ChatReadNumView(
                                            message: widget.message,
                                            chat: widget.controller.chat!,
                                            showPinned: showPinned,
                                            backgroundColor: JXColors.black48,
                                            sender: true,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        body,
                                        ChatReadNumView(
                                          message: widget.message,
                                          chat: widget.controller.chat!,
                                          showPinned: showPinned,
                                          backgroundColor: JXColors.black48,
                                          sender: true,
                                        ),
                                      ],
                                    )
                            ],
                          )
                        : Stack(
                            children: <Widget>[
                              body,
                              Positioned(
                                right: 12,
                                bottom: 6,
                                child: ChatReadNumView(
                                  message: widget.message,
                                  chat: widget.controller.chat!,
                                  showPinned: showPinned,
                                  sender: true,
                                ),
                              ),
                            ],
                          ),

                    /// react emoji 表情栏
                    if (messageEmojiOnly)
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
                              ),
                            ),
                          ),
                        );
                      })
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
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
      return CustomAvatar(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
        uid: sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(RouteName.chatInfo,
                    arguments: {
                      "uid": sendID,
                    },
                    id: objectMgr.loginMgr.isDesktop ? 1 : null);
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  widget.controller.inputController.addMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: widget.controller.chatController.popupEnabled
          ? null
          : avatarWidgetKey,
      width: widget.controller.chatController.chat.isSingle ||
              widget.controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }
}
