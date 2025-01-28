import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupMiniAppShareSenderItem extends StatefulWidget {
  const GroupMiniAppShareSenderItem({
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
  final MessageMiniAppShare messageText;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;

  @override
  GroupMiniAppShareSenderItemState createState() => GroupMiniAppShareSenderItemState();
}

class GroupMiniAppShareSenderItemState extends MessageWidgetMixin<GroupMiniAppShareSenderItem> {
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

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

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
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: "",
      maxWidth: maxWidth -24.w,
      extraWidth: extraWidth,
      isReceiver: true,
      reply: null,
      showReplyContent: showReplyContent,
      showTranslationContent: showTranslationContent.value,
      translationText: "",
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
            onDoubleTap: () {
              widget.controller.chatController.onDoubleTap(
                message: widget.message,
                text: widget.messageText.text,
              );
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
          if (showNickName &&
              !EmojiParser.hasOnlyEmojis(widget.messageText.text))
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
          if (showReplyContent)
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
                chat: widget.controller.chat!,
                maxWidth: getReplyMaxWidth(bean),
                controller: widget.controller,
              ),
            ),

          if (showForwardContent)
            MessageForwardComponent(
              forwardUserId: widget.messageText.forward_user_id,
              maxWidth: maxWidth,
              isSender: true,
            ),
          GestureDetector(
            onTap: (){
              if (!widget.controller.chatController.popupEnabled) {
                objectMgr.miniAppMgr.onLaunchLinkOpen(
                    widget.messageText.text, context);
              }
            },
            child: Container(
              constraints: BoxConstraints(
                minWidth: minWidth(maxWidth, minW),
                maxWidth:
                maxWidth,),
              padding: getTextSpanPadding(),
              child: buildTextContent(context, showPinned, textColor, maxWidth,
                  minW, position == BubblePosition.isLastMessage,
                  bean: bean),
            ),
          ),
        ],
      );

      //  harry注释 _ Markdown 组建会导致文字大小不一致 (ios 字体会变得很小， 安卓还好)

      // var isMarkDown = isMarkdown(widget.messageText.text);
      // if (!isMarkDown) {
      // / markdown组件放入IntrinsicWidth会报错 所以非markdown才用IntrinsicWidth
      // body = IntrinsicWidth(child: body);
      // }
      double emojiSpace = objectMgr.loginMgr.isDesktop ? 8 : 2;
      final matches =
      EmojiParser.REGEX_EMOJI.allMatches(widget.messageText.text);
      final emojiLength = matches.length;
      if (messageEmojiOnly && !objectMgr.loginMgr.isDesktop) {
        if (emojiLength == 1) {
          emojiSpace = 2;
        }
      }
      List<Map<String, int>> emojiCountList = [];
      for (var emoji in emojiUserList) {
        final emojiCountMap = {
          emoji.emoji: emoji.uidList.length,
        };
        emojiCountList.add(emojiCountMap);
      }
      position = getPosition();
      body = messageEmojiOnly
          ? _buildOnlyEmojiOnly(body,emojiSpace)
          : Container(
        padding:
        EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        constraints: const BoxConstraints(minHeight: 32),
        child: ChatBubbleBody(
          constraints: BoxConstraints(
              maxWidth: getBubbleMaxWidth(
                  textWidth: maxWidth+24.w>this.maxWidth?this.maxWidth:maxWidth+24.w,
                  emojiLen: emojiCountList.length,
                  extraWidth: extraWidth,
                  isSender: true),
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
              Visibility(
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
              ),
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
                        ? _buildMessageEmojiOnly(body,emojiLength)
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

  Widget _buildMessageEmojiOnly(Widget body,int emojiLength) {
    if(objectMgr.loginMgr.isDesktop){
      /// 原来其他同事改造桌面版的代码
      if(emojiLength != 1){
        return  Column(
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
          ],
        );
      }else{
        return Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            body,
            ChatReadNumView(
              message: widget.message,
              chat: widget.controller.chat!,
              showPinned: showPinned,
              backgroundColor: colorTextSecondary,
              sender: true,
            ),
          ],
        );
      }
    } else {
      return Column(
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
            height: 2,
          ),
        ],
      );
    }

  }


  Widget _buildOnlyEmojiOnly(Widget body, double emojiSpace) {
    if(objectMgr.loginMgr.isDesktop){
      return _buildOnlyEmojiOnlyDesktop(body,emojiSpace);
    }else{
      return Padding(
        padding:
        EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: body,
      );
    }
  }

  Widget _buildOnlyEmojiOnlyDesktop(Widget body, double emojiSpace) {
    return Container(
      constraints:  const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginAvaR,
          top: emojiSpace,
          right: emojiSpace),
      child: body,
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: getTop(isLastMessage, bean, widget.messageText.text),
        ),
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
        showNickName && !EmojiParser.hasOnlyEmojis(widget.messageText.text);

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

  Widget _buildTitle() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: RemoteImage(
                src: widget.messageText.miniAppAvatar,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            ImGap.hGap(8),
            Text(
              widget.messageText.miniAppName,
              style: jxTextStyle.textStyle14(
                  color: colorTextSecondary
              ),
            ),
          ],
        ),
        ImGap.vGap(6),
        Text(
          widget.messageText.miniAppTitle, //mniAppTi//miniAppTip
          style: jxTextStyle.textStyle17(),
        )
      ],
    );
  }
}
