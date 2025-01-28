import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
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
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class GroupMiniAppDetailSenderItem extends StatefulWidget {
  const GroupMiniAppDetailSenderItem({
    super.key,
    required this.controller,
    required this.messageText,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  });

  final ChatContentController controller;
  final Message message;
  final MessageMiniApp messageText;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;

  @override
  GroupMiniAppDetailSenderItemState createState() =>
      GroupMiniAppDetailSenderItemState();
}

class GroupMiniAppDetailSenderItemState
    extends MessageWidgetMixin<GroupMiniAppDetailSenderItem> {
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

  bool get messageEmojiOnly =>
      widget.messageText.reply.isEmpty &&
      !(widget.messageText.forward_user_id != 0) &&
      EmojiParser.hasOnlyEmojis(widget.messageText.text);

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

  final GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  double get maxWidth =>
      jxDimension.groupTextSenderMaxWidth(hasAvatar: !isSingleOrSystem);

  double get extraWidth => getNewLineExtraWidth(
        showPinned: showPinned,
        isEdit: widget.message.edit_time > 0,
        isSender: true,
        emojiUserList: emojiUserList,
        groupTextMessageReadType: _readType,
        messageEmojiOnly: messageEmojiOnly,
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
    Widget child = messageBody(context);
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
                  onTap: () {
                    objectMgr.miniAppMgr
                        .joinMiniAppOrder(context, widget.messageText.link,widget.controller.chat?.friend_id??0);
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

  Widget messageBody(BuildContext context) {
    double minW = 100;
    BubblePosition position = getPosition();
    return Obx(() {
      Widget body = Container(
        constraints: BoxConstraints(
          minWidth: minWidth(maxWidth, minW),
          maxWidth: maxWidth,
        ),
        padding: getTextSpanPadding(),
        child: buildTextContent(),
      );

      List<Map<String, int>> emojiCountList = [];
      for (var emoji in emojiUserList) {
        final emojiCountMap = {
          emoji.emoji: emoji.uidList.length,
        };
        emojiCountList.add(emojiCountMap);
      }

      position = getPosition();
      body = ChatBubbleBody(
        constraints: BoxConstraints(
          maxWidth: getBubbleMaxWidth(
            textWidth: maxWidth,
            emojiLen: emojiCountList.length,
            extraWidth: extraWidth,
            isSender: true,
          ),
        ),
        position: position,
        verticalPadding: chatBubbleBodyVerticalPadding,
        horizontalPadding: chatBubbleBodyHorizontalPadding,
        isPressed: isPressed.value,
        isHighlight: widget.message.select == 1,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            body,
            // const SizedBox(height: 4),
            // ChatReadNumView(
            //   message: widget.message,
            //   chat: widget.controller.chat!,
            //   showPinned: showPinned,
            //   sender: true,
            // ),
          ],
        ),
      );

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          left: widget.controller.chatController.chooseMore.value
              ? 40
              : jxDimension.chatRoomSideMarginNoAva,
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: AbsorbPointer(
          absorbing: widget.controller.chatController.popupEnabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body,

              // if (isPlayingSound.value || isWaitingRead.value)
              //   MessageReadTextIcon(
              //     isWaitingRead: isWaitingRead.value,
              //     isMe: false,
              //     isPause: isPauseRead.value,
              //   ),

              /// react emoji 表情栏
              // if (messageEmojiOnly)
              //   Obx(() {
              //     List<Map<String, int>> emojiCountList = [];
              //     for (var emoji in emojiUserList) {
              //       final emojiCountMap = {
              //         emoji.emoji: emoji.uidList.length,
              //       };
              //       emojiCountList.add(emojiCountMap);
              //     }
              //
              //     return Visibility(
              //       visible: emojiUserList.isNotEmpty,
              //       child: GestureDetector(
              //         onTap: () => widget.controller
              //             .onViewReactList(context, emojiUserList),
              //         child: Container(
              //           margin: EdgeInsets.only(
              //             left: jxDimension.chatBubbleLeftMargin,
              //             bottom: 4,
              //           ),
              //           child: EmojiListItem(
              //             emojiModelList: emojiUserList,
              //             message: widget.message,
              //             specialBgColor: true,
              //             controller: widget.controller,
              //             isSender: true,
              //             messageEmojiOnly: messageEmojiOnly,
              //           ),
              //         ),
              //       ),
              //     );
              //   }),
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

  Widget buildTextContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          widget.messageText.replaceSpaceTitle,
          style: jxTextStyle.textStyle17(),
        ),
        const SizedBox(height: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.messageText.showInfo,
              style: TextStyle(
                fontSize: MFontSize.size14.value,
                fontWeight: MFontWeight.bold4.value,
                color: colorTextSecondary,
                height: 1.4,
              ),
            ),
            Container(
              height: 36,
              margin: const EdgeInsets.only(top: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: 0.3,
                    color: colorDivider,
                  ),
                ),
              ),
              child: Text(
                localized(view),
                style: jxTextStyle.textStyleBold14(color: themeColor, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
