import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
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
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupLinkMeItem extends StatefulWidget {
  final ChatContentController controller;
  final Message message;
  final MessageLink messageLink;
  final int index;

  const GroupLinkMeItem({
    super.key,
    required this.controller,
    required this.message,
    required this.messageLink,
    required this.index,
  });

  @override
  State<GroupLinkMeItem> createState() => _GroupLinkMeItemState();
}

class _GroupLinkMeItemState extends MessageWidgetMixin<GroupLinkMeItem> {
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;
  double maxWidth = jxDimension.groupTextMeMaxWidth();

  bool get showReplyContent => widget.messageLink.reply.isNotEmpty;

  bool get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showPinned {
    return widget.controller.chatController.pinMessageList.firstWhereOrNull(
            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
        null;
  }

  double get extraWidth => getNewLineExtraWidth(
        showPinned: showPinned,
        isEdit: widget.message.edit_time > 0,
        isSender: false,
        emojiUserList: emojiUserList,
        groupTextMessageReadType: _readType,
        messageEmojiOnly: false,
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
    return widget.messageLink.reply.isNotEmpty
        ? jxDimension.groupTextSenderReplySize()
        : showTranslationContent.value
            ? jxDimension.showTranslationContentMinSize()
            : 0;
  }

  bool get needExtraSpace {
    return (_readType == GroupTextMessageReadType.inlineType &&
            !showTranslationContent.value) ||
        widget.messageLink.reply.isNotEmpty;
  }

  RxString source = ''.obs;
  CancelToken thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(widget.controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;

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

  @override
  void didUpdateWidget(GroupLinkMeItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message != oldWidget.message ||
        widget.messageLink != oldWidget.messageLink) {
      _preloadImageSync();
    }
  }

  @override
  void dispose() {
    thumbCancelToken.cancel();
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
    DownloadResult result = await downloadMgrV2.download(
      widget.messageLink.linkImageSrc,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
    );
    final thumbPath = result.localPath;

    // final thumbPath = await downloadMgr.downloadFile(
    //   widget.messageLink.linkImageSrc,
    //   mini: Config().messageMin,
    //   priority: 3,
    //   cancelToken: thumbCancelToken,
    // );

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = widget.messageLink.linkImageSrc;
      return;
    }
  }

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: lineSpacing);
    }

    return EdgeInsets.zero;
  }

  void _showEnableFloatingWindow(BuildContext context, NewLineBean bean) {
    enableFloatingWindow(
      context,
      widget.controller.chatController.chat.id,
      widget.message,
      _messageBody(context, bean: bean),
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

  @override
  Widget build(BuildContext context) {
    // 计算文本宽带
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText:
          widget.messageLink.linkPreviewData?.desc ?? widget.messageLink.text,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      reply: getReplyStr(widget.messageLink.reply),
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: false,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      isReceiver: false,
      minWidth: 120.w,
    );
    _readType = bean.type;

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
                      _showEnableFloatingWindow(context, bean);
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
                  child: _messageBody(context, bean: bean),
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

  Widget _messageBody(BuildContext context, {required NewLineBean bean}) {
    double maxWidth = bean.calculatedWidth;
    double minW = bean.minWidth;

    return Obx(() {
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

      final bool isBigHorizontalPadding =
          widget.messageLink.forwardUserId != 0 ||
              widget.messageLink.reply.isNotEmpty;

      Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.messageLink.reply.isNotEmpty) const SizedBox(height: 2.0),
          if (widget.messageLink.reply.isNotEmpty)
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
                replyModel:
                    ReplyModel.fromJson(jsonDecode(widget.messageLink.reply)),
                message: widget.message,
                chat: widget.controller.chatController.chat,
                maxWidth: getReplyMaxWidth(bean),
                controller: widget.controller,
              ),
            ),
          if (widget.messageLink.forwardUserId != 0)
            MessageForwardComponent(
              forwardUserId: widget.messageLink.forwardUserId,
              maxWidth: maxWidth,
              isSender: false,
            ),
          if (widget.messageLink.linkPreviewData != null &&
              widget.messageLink.linkPreviewData!.hasData)
            _buildLinkPreview(context, bean, position, isBigHorizontalPadding),
          Padding(
            padding: getTextSpanPadding().add(
              EdgeInsets.symmetric(
                horizontal: isBigHorizontalPadding
                    ? 0.0
                    : chatBubbleBodyHorizontalPadding,
              ),
            ),
            child: _buildTextContent(context, bean),
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

      body = ChatBubbleBody(
        type: BubbleType.sendBubble,
        position: position,
        style: position == BubblePosition.isMiddleMessage
            ? BubbleStyle.round
            : BubbleStyle.tail,
        verticalPadding: chatBubbleBodyVerticalPadding,
        horizontalPadding:
            isBigHorizontalPadding ? chatBubbleBodyHorizontalPadding : 0.0,
        isPressed: isPressed.value,
        isHighlight: widget.message.select == 1 ? true : false,
        constraints: BoxConstraints(
          maxWidth: getBubbleMaxWidth(
            textWidth: maxWidth + 24.w > this.maxWidth
                ? this.maxWidth
                : maxWidth + 24.w,
            emojiLen: emojiCountList.length,
            extraWidth: extraWidth,
            isSender: false,
          ),
          minWidth: getMinWidth(maxWidth, minW),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            body,

            /// react emoji 表情栏
            Obx(() {
              return Visibility(
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
                      eMargin: EmojiMargin.me,
                      isSender: true,
                      showPinned: showPinned,
                      messageEmojiOnly: false,
                    ),
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
          padding: EdgeInsets.only(
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Stack(
                children: <Widget>[
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
                  child: _buildState(widget.message, bean),
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

    final sideRadius = bubbleSideRadius(
      position,
      BubbleType.sendBubble,
    );

    return GestureDetector(
      onTap: () => onLinkOpen(linkPreviewData.url!),
      child: Container(
        margin: EdgeInsets.only(
          top: (hasMedia && linkPreviewData.isBigMedia) ||
                  !isBigHorizontalPadding
              ? 0.0
              : 6.0,
          bottom: 8.0,
          left: isBigHorizontalPadding ? 0.0 : chatBubbleBodyVerticalPadding,
          right: isBigHorizontalPadding ? 0.0 : chatBubbleBodyVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: bubblePrimary.withOpacity(0.08),
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
          maxWidth: widget.messageLink.reply.isNotEmpty
              ? getReplyMaxWidth(bean)
              : max(
                  bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                  bean.calculatedWidth +
                      (!isBigHorizontalPadding
                          ? chatBubbleBodyHorizontalPadding + 4.0
                          : 0.0),
                ),
        ),
        child: Column(
          children: <Widget>[
            // 大图片
            if (hasMedia && linkPreviewData.isBigMedia)
              _buildAsset(
                context,
                linkPreviewData,
                bean,
                isBigHorizontalPadding: isBigHorizontalPadding,
              ),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.messageLink.reply.isNotEmpty
                    ? getReplyMaxWidth(bean)
                    : max(
                        bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                        bean.calculatedWidth,
                      ),
              ),
              child: Row(
                children: <Widget>[
                  // 小图片
                  if (hasMedia && !linkPreviewData.isBigMedia)
                    _buildAsset(
                      context,
                      linkPreviewData,
                      bean,
                      isSmall: true,
                      isBigHorizontalPadding: isBigHorizontalPadding,
                    ),

                  // 详情
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      constraints: BoxConstraints(
                        maxWidth: widget.messageLink.reply.isNotEmpty
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
                                  color: colorTextSecondary,
                                ),
                                maxLines: linkPreviewData.isBigMedia ? 5 : 1,
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
    bool isBigHorizontalPadding = false,
  }) {
    return Obx(
      () {
        final filePath = downloadMgrV2.getLocalPath(linkPreviewData.image!);
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
              : widget.messageLink.reply.isNotEmpty
                  ? getReplyMaxWidth(bean)
                  : max(
                      bean.actualWidth + (needExtraSpace ? extraWidth : 0),
                      bean.calculatedWidth +
                          (!isBigHorizontalPadding
                              ? chatBubbleBodyHorizontalPadding + 4.0
                              : 0.0),
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

  Widget _buildTextContent(BuildContext context, NewLineBean bean) {
    double maxW = bean.calculatedWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 文本
        if (showOriginalContent.value) ...[
          Container(
            constraints: BoxConstraints(
              maxWidth: minTextWidth > maxW ? minTextWidth : maxW,
              minWidth: minTextWidth,
              maxHeight: isExpandReadMore.value
                  ? textMaxHeight(context)
                  : double.infinity,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    widget.messageLink.text,
                    isReply: widget.messageLink.reply.isNotEmpty,
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
                    groupId: widget.controller.chat!.isGroup
                        ? widget.controller.chat!.chat_id
                        : null,
                  ),
                  if ((_readType == GroupTextMessageReadType.inlineType &&
                          !showTranslationContent.value) ||
                      widget.messageLink.reply.isNotEmpty) // 解决点赞后的行间距问题
                    WidgetSpan(child: SizedBox(width: extraWidth)),
                ],
              ),
              maxLines: isExpandReadMore.value
                  ? max(textMaxHeight(context) ~/ bean.itemLineHeight, 1)
                  : null,
              overflow: isExpandReadMore.value ? TextOverflow.ellipsis : null,
            ),
          ),
          if (mounted &&
              textMaxHeight(context) ~/ bean.itemLineHeight < bean.lineCounts &&
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
        ],

        if (showTranslationContent.value)
          MessageTranslateComponent(
            chat: baseController.chat,
            message: message,
            translatedText: translationText.value,
            locale: translationLocale.value,
            controller: widget.controller,
            constraints:
                BoxConstraints(maxWidth: maxW, minWidth: bean.minWidth),
            showDivider:
                showOriginalContent.value && showTranslationContent.value,
            isSender: false,
            showPinned: showPinned,
          ),
      ],
    );
  }

  Widget _buildState(Message msg, NewLineBean bean) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (widget.controller.chatController.popupEnabled) {
          return;
        }
        _showEnableFloatingWindow(context, bean);
      },
    );
  }
}
