import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
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
import 'package:jxim_client/im/custom_content/message_widget/message_reply_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_translate_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
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
import 'package:simple_html_css/simple_html_css.dart';

class GroupLinkSenderItem extends StatefulWidget {
  final ChatContentController controller;
  final Message message;
  final MessageLink messageLink;
  final int index;

  const GroupLinkSenderItem({
    super.key,
    required this.controller,
    required this.message,
    required this.messageLink,
    required this.index,
  });

  @override
  State<GroupLinkSenderItem> createState() => _GroupLinkSenderItemState();
}

class _GroupLinkSenderItemState
    extends MessageWidgetMixin<GroupLinkSenderItem> {
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;

  int sendID = 0;
  bool isSmallSecretary = false;

  RxString source = ''.obs;
  CancelToken thumbCancelToken = CancelToken();

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showPinned =>
      widget.controller.chatController.pinMessageList
          .firstWhereOrNull((pinnedMsg) => pinnedMsg.id == widget.message.id) !=
      null;

  bool get showNickName =>
      (isFirstMessage || widget.controller.chatController.isPinnedOpened) &&
      !(showReplyContent &&
          widget.message.hasReply &&
          ReplyModel.fromJson(jsonDecode(widget.message.replyModel!)).userId ==
              sendID) &&
      !showForwardContent &&
      widget.controller.chat!.isGroup &&
      !widget.controller.chat!.isSaveMsg;

  bool get showReplyContent => widget.messageLink.reply.isNotEmpty;

  bool get showForwardContent =>
      widget.messageLink.forwardUserId != 0 &&
      !widget.controller.chat!.isSaveMsg;

  bool get showAvatar =>
      !widget.controller.chat!.isSystem &&
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

  /// 当消息在聊天室内，只有一条，并且只有一行，并且是连续消息中的最后一跳消息
  double getTop(bool isLastMessage, NewLineBean bean, String text) {
    /// 无用户名
    bool k1 = showNickName;

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

  BubblePosition get getPosition {
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

  bool get needExtraSpace {
    return (_readType == GroupTextMessageReadType.inlineType &&
            !showTranslationContent.value) ||
        widget.messageLink.reply.isNotEmpty;
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
    getRealSendID();

    _preloadImageSync();
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

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.controller.chat?.isSaveMsg ?? false) {
      sendID = widget.messageLink.forwardUserId;
      if (widget.messageLink.forwardUserName == 'Secretary') {
        isSmallSecretary = true;
      }
    }
    if (widget.controller.chat?.typ == chatTypeSmallSecretary) {
      isSmallSecretary = true;
    }
  }

  @override
  void didUpdateWidget(GroupLinkSenderItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message != oldWidget.message ||
        widget.messageLink != oldWidget.messageLink) {
      _preloadImageSync();
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

  _preloadImageSync() {
    if (widget.messageLink.linkPreviewData == null) return;

    source.value =
        imageMgr.getBlurHashSavePath(widget.messageLink.linkImageSrc);

    if (source.value.isNotEmpty && !File(source.value).existsSync()) {
      imageMgr.genBlurHashImage(
        widget.messageLink.linkImageSrcGaussian,
        widget.messageLink.linkImageSrc,
      );
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      widget.messageLink.linkImageSrc,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      source.value = widget.messageLink.linkImageSrc;
      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    // final thumbPath = await downloadMgr.downloadFile(
    //   widget.messageLink.linkImageSrc,
    //   mini: Config().messageMin,
    //   priority: 3,
    //   cancelToken: thumbCancelToken,
    // );

    DownloadResult result = await downloadMgrV2.download(
      widget.messageLink.linkImageSrc,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
    );
    final thumbPath = result.localPath;

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = widget.messageLink.linkImageSrc;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText:
          widget.messageLink.linkPreviewData?.desc ?? widget.messageLink.text,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      isReceiver: true,
      reply: getReplyStr(widget.messageLink.reply),
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

    final Widget child = _messageBody(context, bean);

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
                      text: widget.messageLink.text,
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

  Widget _messageBody(BuildContext context, NewLineBean bean) {
    double maxWidth = bean.calculatedWidth;
    double minW = bean.minWidth;
    final textColor = groupMemberColor(sendID);

    final isBigHorizontalPadding =
        showNickName || showReplyContent || showForwardContent;

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
                  json.decode(widget.messageLink.reply),
                ),
                message: widget.message,
                chat: widget.controller.chat!,
                maxWidth: getReplyMaxWidth(bean),
                controller: widget.controller,
              ),
            ),

          if (showForwardContent)
            MessageForwardComponent(
              forwardUserId: widget.messageLink.forwardUserId,
              maxWidth: maxWidth,
              isSender: true,
            ),

          if (widget.messageLink.linkPreviewData != null &&
              widget.messageLink.linkPreviewData!.hasData)
            _buildLinkPreview(
              context,
              bean,
              getPosition,
              isBigHorizontalPadding,
            ),

          Container(
            constraints: BoxConstraints(
              minWidth: minWidth(maxWidth, minW),
              maxWidth: maxWidth,
            ),
            padding: getTextSpanPadding().add(
              EdgeInsets.symmetric(
                horizontal: isBigHorizontalPadding
                    ? 0.0
                    : chatBubbleBodyHorizontalPadding,
              ),
            ),
            child: _buildTextContent(
              context,
              showPinned,
              textColor,
              maxWidth,
              minW,
              getPosition == BubblePosition.isLastMessage,
              bean: bean,
            ),
          ),
        ],
      );

      List<Map<String, int>> emojiCountList = [];
      for (var emoji in emojiUserList) {
        final emojiCountMap = {
          emoji.emoji: emoji.uidList.length,
        };
        emojiCountList.add(emojiCountMap);
      }

      body = Container(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        constraints: const BoxConstraints(minHeight: 32),
        child: ChatBubbleBody(
          constraints: BoxConstraints(
              maxWidth: getBubbleMaxWidth(
                textWidth: maxWidth + 24.w > this.maxWidth
                    ? this.maxWidth
                    : maxWidth + 24.w,
                emojiLen: emojiCountList.length,
                extraWidth: extraWidth,
                isSender: true,
              ),
              minHeight: showAvatar ? jxDimension.chatRoomAvatarSize() : 0),
          position: getPosition,
          style: getPosition == BubblePosition.isMiddleMessage
              ? BubbleStyle.round
              : BubbleStyle.tail,
          verticalPadding: chatBubbleBodyVerticalPadding,
          horizontalPadding:
              isBigHorizontalPadding ? chatBubbleBodyHorizontalPadding : 0.0,
          isPressed: isPressed.value,
          isHighlight: widget.message.select == 1 ? true : false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body,
              Visibility(
                visible: emojiUserList.isNotEmpty,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: !isBigHorizontalPadding
                        ? chatBubbleBodyHorizontalPadding
                        : 0.0,
                  ),
                  child: GestureDetector(
                    onTap: () => widget.controller
                        .onViewReactList(context, emojiUserList),
                    child: EmojiListItem(
                      emojiModelList: emojiUserList,
                      message: widget.message,
                      controller: widget.controller,
                      eMargin: EmojiMargin.sender,
                      showPinned: showPinned,
                      messageEmojiOnly: false,
                    ),
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
                child: _buildAvatar(),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLinkPreview(
    BuildContext context,
    NewLineBean bean,
    BubblePosition position,
    bool isBigHorizontalPadding,
  ) {
    final linkPreviewData = widget.messageLink.linkPreviewData!;
    final hasMedia = linkPreviewData.hasMedia;
    final bool isBigMedia;

    if (hasMedia &&
        (notBlank(linkPreviewData.imageWidth) ||
            notBlank(linkPreviewData.imageHeight))) {
      isBigMedia = min(int.parse(linkPreviewData.imageWidth ?? '1'),
              int.parse(linkPreviewData.imageHeight ?? '1')) >
          Config().messageMin;
    } else {
      isBigMedia = false;
    }

    final sideRadius = bubbleSideRadius(
      position,
      BubbleType.receiverBubble,
    );

    return GestureDetector(
      onTap: () => onLinkOpen(linkPreviewData.url!),
      child: Container(
        margin: EdgeInsets.only(
          top: (hasMedia && isBigMedia) || !isBigHorizontalPadding ? 0.0 : 6.0,
          bottom: 8.0,
          left: isBigHorizontalPadding ? 0.0 : chatBubbleBodyVerticalPadding,
          right: isBigHorizontalPadding ? 0.0 : chatBubbleBodyVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: widget.controller.chatController.chat.isGroup &&
                  !objectMgr.userMgr.isMe(widget.message.send_id)
              ? groupMemberColor(widget.message.send_id).withOpacity(0.08)
              : themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: isBigHorizontalPadding
                ? const Radius.circular(4.0)
                : sideRadius.topLeft,
            topRight: isBigHorizontalPadding
                ? const Radius.circular(4.0)
                : sideRadius.topRight,
            bottomRight: const Radius.circular(4.0),
            bottomLeft: const Radius.circular(4.0),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        constraints: BoxConstraints(
          maxWidth: showReplyContent
              ? getReplyMaxWidth(bean)
              : max(
                  bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                  bean.calculatedWidth,
                ),
        ),
        child: Column(
          children: <Widget>[
            // 大图片
            if (hasMedia && isBigMedia)
              _buildAsset(context, linkPreviewData, bean),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: showReplyContent
                    ? getReplyMaxWidth(bean)
                    : max(
                        bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                        bean.calculatedWidth,
                      ),
              ),
              child: Row(
                children: <Widget>[
                  // 小图片
                  if (hasMedia && !isBigMedia)
                    _buildAsset(context, linkPreviewData, bean, isSmall: true),

                  // 详情
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      constraints: BoxConstraints(
                        maxWidth: showReplyContent
                            ? getReplyMaxWidth(bean)
                            : max(
                                bean.actualWidth +
                                    (needExtraSpace ? extraWidth : 0),
                                bean.calculatedWidth,
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: linkPreviewData.desc == null &&
                                      !linkPreviewData.hasMedia
                                  ? 14.0
                                  : 4.0,
                            ),
                            child: Text(
                              '${linkPreviewData.title ?? Uri.parse(linkPreviewData.url ?? '').host.toString()}${linkPreviewData.titleExceedMaximum ? "..." : ""}',
                              style: jxTextStyle.textStyleBold14(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (linkPreviewData.desc != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '${linkPreviewData.desc!}${linkPreviewData.descExceedMaximum ? "..." : ""}',
                                style: jxTextStyle.textStyle12(
                                  color: colorTextSecondarySolid,
                                ),
                                maxLines: isBigMedia ? 5 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsset(
    BuildContext context,
    Metadata linkPreviewData,
    NewLineBean bean, {
    bool isSmall = false,
  }) {
    return Obx(
      () {
        final filePath = linkPreviewData.image;
        final remoteFileExist = downloadMgrV2.getLocalPath(
              widget.messageLink.linkImageSrc,
              mini: Config().messageMin,
            ) !=
            null;

        final fileExist = objectMgr.userMgr.isMe(widget.message.send_id) &&
            filePath != null &&
            File(filePath).existsSync() &&
            !remoteFileExist;

        // check local file exist
        return RemoteImageV2(
          src: fileExist ? filePath : source.value,
          width: isSmall
              ? 66.0
              : showReplyContent
                  ? getReplyMaxWidth(bean)
                  : max(
                      bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                      bean.calculatedWidth,
                    ),
          height: isSmall ? 66.0 : 270,
          fit: BoxFit.cover,
          mini: source.value ==
                      imageMgr.getBlurHashSavePath(
                          widget.messageLink.linkImageSrc) ||
                  fileExist
              ? null
              : Config().messageMin,
        );
      },
    );
  }

  Widget _buildTextContent(
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
          height: getTop(isLastMessage, bean, widget.messageLink.text),
        ),
        if (showOriginalContent.value)
          if (widget.controller.chat!.isSystem) ...{
            Text.rich(
              textWidthBasis: TextWidthBasis.longestLine,
              TextSpan(
                children: [
                  HTML.toTextSpan(
                    defaultTextStyle:
                        jxTextStyle.normalBubbleText(colorTextPrimary),
                    context,
                    widget.messageLink.text,
                    linksCallback: (dynamic link) {
                      onLinkLongPress(link.toString(), context);
                    },
                  ),
                  if (_readType == GroupTextMessageReadType.inlineType &&
                      showReplyContent &&
                      !showTranslationContent.value)
                    _textWidgetSpan(),
                ],
              ),
            ),
          } else ...{
            /// 文本
            Container(
              constraints: BoxConstraints(
                maxHeight:
                    isExpandReadMore.value ? textMaxHeight : double.infinity,
              ),
              child: Text.rich(
                TextSpan(
                  style: jxTextStyle.normalBubbleText(textColor),
                  children: [
                    ...BuildTextUtil.buildSpanList(
                      widget.message,
                      widget.messageLink.text,
                      isReply: showReplyContent,
                      isEmojiOnly: false,
                      isLinkMsg: true,
                      launchLink:(String text){
                        if(!widget.controller.chatController.popupEnabled) {
                          if (text.contains(objectMgr.miniAppMgr.miniAppShareUrlPrefix)) {
                            objectMgr.miniAppMgr.onLaunchLinkOpen(text,context);
                          } else {
                            onLinkOpen(text);
                          }
                        }
                      },
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
                      textColor: colorTextPrimary,
                      groupId: widget.controller.chat!.isGroup
                          ? widget.controller.chat!.id
                          : null,
                    ),
                    if ((_readType == GroupTextMessageReadType.inlineType &&
                            !showTranslationContent.value) ||
                        showReplyContent)
                      _textWidgetSpan(), // 解决点赞后的行间距问题
                  ],
                ),
                maxLines: isExpandReadMore.value
                    ? textMaxHeight ~/ bean.itemLineHeight
                    : null,
                overflow: isExpandReadMore.value ? TextOverflow.ellipsis : null,
              ),
            ),
            if (textMaxHeight ~/ bean.itemLineHeight < lineCounts &&
                isExpandReadMore.value) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  widget.controller.chatController
                      .openReadMoreTextEvent(widget.message);
                  isPressed.value = false;
                },
                child: Text(
                  localized(readMore),
                  style: jxTextStyle.textStyle17(color: colorReadColor),
                ),
              )
            ]
          },
        if (showTranslationContent.value)
          MessageTranslateComponent(
            chat: baseController.chat,
            message: message,
            translatedText: translationText.value,
            locale: translationLocale.value,
            controller: widget.controller,
            constraints: BoxConstraints(maxWidth: maxW),
            showDivider:
                showOriginalContent.value && showTranslationContent.value,
            isSender: true,
            showPinned: showPinned,
          ),
      ],
    );
  }

  WidgetSpan _textWidgetSpan() {
    return WidgetSpan(child: SizedBox(width: extraWidth));
  }

  Widget _buildAvatar() {
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
}
