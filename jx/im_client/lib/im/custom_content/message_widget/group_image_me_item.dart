import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupImageMeItem extends StatefulWidget {
  const GroupImageMeItem({
    super.key,
    required this.controller,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
  });

  final ChatContentController controller;
  final MessageImage messageImage;
  final Message message;
  final Chat chat;
  final int index;

  @override
  State<GroupImageMeItem> createState() => _GroupImageMeItemState();
}

class _GroupImageMeItemState extends MessageWidgetMixin<GroupImageMeItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  late MessageImage msgImg;

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  //图片资源src
  Rx<Uint8List> gausPath = Uint8List(0).obs;
  RxString source = ''.obs;
  RxBool isThumbnailReady = false.obs;
  RxBool isDownloading = false.obs;
  RxDouble downloadPercentage = 0.0.obs;
  CancelToken thumbCancelToken = CancelToken();

  RxBool showDoneIcon = false.obs;

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  get extraWidth =>
      setWidth(isPinnedOpen, widget.message.edit_time > 0, isMe: true);

  @override
  void dispose() {
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);

    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    msgImg = widget.messageImage;
    showDoneIcon.value = widget.message.showDoneIcon;

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;

    _preloadImageSync();

    if (showDoneIcon.value) {
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 -
              widget.message.create_time <=
          3) {
        Future.delayed(const Duration(seconds: 1), () {
          widget.message.showDoneIcon = false;
          showDoneIcon.value = false;
        });
      } else {
        widget.message.showDoneIcon = false;
        showDoneIcon.value = false;
      }
    }
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
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
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

  void refreshBubble(sender, type, data) async {
    if (data is Message && data.isSendOk) {
      widget.message.showDoneIcon = true;
      showDoneIcon.value = true;
      msgImg = widget.message.decodeContent(cl: MessageImage.creator);

      _preloadImageSync();
      Future.delayed(const Duration(seconds: 2), () {
        widget.message.showDoneIcon = false;
        showDoneIcon.value = false;
      });
    } else {
      if (mounted) setState(() {});
    }
  }

  _preloadImageSync() {
    if (msgImg.gausPath.isEmpty) {
      source.value = msgImg.url;
    } else {
      if (msgImg.gausPath.contains('Image/')) {
        source.value = msgImg.gausPath;
      } else {
        source.value = imageMgr.getBlurHashSavePath(msgImg.url);

        if (source.value.isNotEmpty && !File(source.value).existsSync()) {
          imageMgr.genBlurHashImage(
            msgImg.gausPath,
            msgImg.url,
          );
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      msgImg.url,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      isThumbnailReady.value = true;
      source.value = msgImg.url;
      gausPath.value = Uint8List(0);
      return;
    }

    if (File(msgImg.filePath).existsSync()) isThumbnailReady.value = true;

    if (msgImg.filePath.isEmpty || !File(msgImg.filePath).existsSync()) {
      isDownloading.value = true;
      gausPath.value = msgImg.gausBytes ?? Uint8List(0);
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    DownloadResult result = await downloadMgrV2.download(
      msgImg.url,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
      onReceiveProgress: (received, total) {
        downloadPercentage.value = received / total;
      },
    );
    final thumbPath = result.localPath;

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      isThumbnailReady.value = true;
      gausPath.value = Uint8List(0);
      source.value = msgImg.url;
    }

    isDownloading.value = false;
  }

  EdgeInsets getTextSpanPadding() {
    if (showTranslationContent.value) return const EdgeInsets.only(bottom: 0);

    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: 16.w);
    }

    return EdgeInsets.only(bottom: 4.w);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

    // 计算文本宽带
    if (widget.messageImage.caption.isNotEmpty) {
      _readType = caculateLastLineTextWidth(
        message: widget.message,
        messageText: widget.messageImage.caption,
        maxWidth: width.value - 24,
        extraWidth: extraWidth,
      );
    }

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: <Widget>[
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (_) {
                    controller.chatController.onCancelFocus();
                    isPressed.value = false;
                  },
                  onTapCancel: () => isPressed.value = false,
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
                      enableFloatingWindow(
                        context,
                        widget.chat.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                          mediaSubType: widget.messageImage.caption.isNotEmpty
                              ? MenuMediaSubType.subMediaImageTxt
                              : MenuMediaSubType.none,
                        ),
                        bubbleType: BubbleType.sendBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                          widget.message,
                          widget.chat,
                          mediaSubType: widget.messageImage.caption.isNotEmpty
                              ? MenuMediaSubType.subMediaImageTxt
                              : MenuMediaSubType.none,
                        ),
                        topWidget: EmojiSelector(
                          chat: widget.chat,
                          message: widget.message,
                          emojiMapList: emojiUserList,
                        ),
                      );
                    }

                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) async {
                    if (objectMgr.loginMgr.isDesktop) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          isSender: true,
                          emojiSelector: EmojiSelector(
                            chat: widget.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
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
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: RepaintBoundary(
                    child: MoreChooseView(
                      chatController: controller.chatController,
                      message: widget.message,
                      chat: widget.chat,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      if (controller.chatController.isPinnedOpened) {
        position = BubblePosition.isLastMessage;
      }

      Widget topBody = const SizedBox();
      if (widget.messageImage.reply.isNotEmpty) {
        topBody = Padding(
          padding: EdgeInsets.all(bubbleInnerPadding),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.chatController.popupEnabled
                ? null
                : () => onPressReply(
                      controller.chatController,
                      widget.message,
                    ),
            child: MessageReplyComponent(
              replyModel: ReplyModel.fromJson(
                json.decode(widget.messageImage.reply),
              ),
              message: widget.message,
              chat: widget.chat,
              maxWidth: width.value,
              controller: controller,
            ),
          ),
        );
      }

      if (widget.messageImage.forward_user_id != 0) {
        topBody = Padding(
          padding: forwardTitlePadding,
          child: MessageForwardComponent(
            forwardUserId: widget.messageImage.forward_user_id,
            maxWidth: width.value,
            isSender: false,
          ),
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageImage.caption.isNotEmpty) {
        bottomBody = Container(
          width: width.value,
          padding: getTextSpanPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 文本
              if (showOriginalContent.value)
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: bubbleInnerPadding)
                      .copyWith(top: bubbleInnerPadding),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        ...BuildTextUtil.buildSpanList(
                          widget.message,
                          widget.messageImage.caption,
                          launchLink: controller.chatController.popupEnabled
                              ? null
                              : onLinkOpen,
                          onMentionTap: controller.chatController.popupEnabled
                              ? null
                              : onMentionTap,
                          openLinkPopup: (value) =>
                              controller.chatController.popupEnabled
                                  ? null
                                  : onLinkLongPress(value, context),
                          openPhonePopup: (value) =>
                              controller.chatController.popupEnabled
                                  ? null
                                  : onPhoneLongPress(value, context),
                          textColor: colorTextPrimary,
                          isSender: true,
                        ),
                        if (_readType == GroupTextMessageReadType.inlineType)
                          WidgetSpan(
                            child: SizedBox(width: extraWidth),
                          ),
                      ],
                    ),
                  ),
                ),
              if (showTranslationContent.value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MessageTranslateComponent(
                    chat: baseController.chat,
                    message: message,
                    controller: widget.controller,
                    translatedText: translationText.value,
                    locale: translationLocale.value,
                    showDivider: showOriginalContent.value &&
                        showTranslationContent.value,
                  ),
                ),
            ],
          ),
        );
      }

      bottomBody = Stack(
        children: [
          ChatBubbleBody(
            type: BubbleType.sendBubble,
            position: position,
            isClipped: true,
            isPressed: isPressed.value,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                topBody,
                buildImageContent(context, position),
                bottomBody,
              ],
            ),
          ),
          Positioned(
            right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
            bottom: objectMgr.loginMgr.isDesktop ? 8 : 6.w,
            child: ChatReadNumView(
              message: widget.message,
              chat: widget.chat,
              showPinned:
                  controller.chatController.pinMessageList.firstWhereOrNull(
                        (pinnedMsg) => pinnedMsg.id == widget.message.id,
                      ) !=
                      null,
              backgroundColor: widget.messageImage.caption.isEmpty
                  ? colorTextSecondary
                  : Colors.transparent,
              sender: false,
            ),
          ),
          if (isPlayingSound.value || isWaitingRead.value)
            MessageReadTextIcon(
              isWaitingRead: isWaitingRead.value,
              isMe: true,
              isPause: isPauseRead.value,
            ),
        ],
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4.w : 0,
          ),
          child: AbsorbPointer(
            absorbing: controller.chatController.popupEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                bottomBody,

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
                      onTap: controller.chatController.popupEnabled
                          ? null
                          : () => controller.onViewReactList(
                                context,
                                emojiUserList,
                              ),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: width.value),
                        margin: EdgeInsets.only(
                          bottom: objectMgr.loginMgr.isDesktop ? 4 : 4.w,
                        ),
                        child: EmojiListItem(
                          specialBgColor: true,
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: controller,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildImageContent(BuildContext context, BubblePosition position) {
    BorderRadius imageBorderRadius = BorderRadius.zero;
    if ((widget.messageImage.reply.isNotEmpty ||
            widget.messageImage.forward_user_id != 0) &&
        widget.messageImage.caption.isNotEmpty) {
      imageBorderRadius = BorderRadius.zero;
    } else if (widget.messageImage.forward_user_id != 0 ||
        widget.messageImage.reply.isNotEmpty) {
      imageBorderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(
          BubbleCorner.bottomLeftCorner(position, BubbleType.sendBubble),
        ),
        bottomRight: Radius.circular(
          BubbleCorner.bottomRightCorner(position, BubbleType.sendBubble),
        ),
      );
    } else if (widget.messageImage.caption.isNotEmpty) {
      imageBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(
          BubbleCorner.topLeftCorner(position, BubbleType.sendBubble),
        ),
        topRight: Radius.circular(
          BubbleCorner.topRightCorner(position, BubbleType.sendBubble),
        ),
      );
    } else {
      imageBorderRadius = bubbleSideRadius(position, BubbleType.sendBubble);
    }

    final Widget imageChild = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: imageBorderRadius,
            color: isPressed.value ? colorTextPlaceholder : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildAsset(),
        ),
        Obx(() {
          if (gausPath.value.isNotEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: isPressed.value ? colorTextPlaceholder : null,
                borderRadius: imageBorderRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                gausPath.value,
                width: width.value,
                height: height.value,
                fit: BoxFit.cover,
              ),
            );
          }

          return const SizedBox();
        }),
        _buildProgress(context),
        if (isPressed.value)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: imageBorderRadius,
                color: colorTextPlaceholder,
              ),
            ),
          ),
      ],
    );

    return isDesktop
        ? DesktopGeneralButton(
            horizontalPadding: 0,
            onPressed: () {
              if (controller.isCTRLPressed()) {
                desktopGeneralDialog(
                  context,
                  color: Colors.transparent,
                  widgetChild: DesktopMessagePopMenu(
                    offset: tapPosition,
                    isSender: true,
                    emojiSelector: EmojiSelector(
                      chat: widget.chat,
                      message: widget.message,
                      emojiMapList: emojiUserList,
                    ),
                    popMenu: ChatPopMenuSheet(
                      message: widget.message,
                      chat: widget.chat,
                      sendID: widget.message.send_id,
                    ),
                    menuHeight: ChatPopMenuUtil.getMenuHeight(
                      widget.message,
                      widget.chat,
                      extr: false,
                    ),
                  ),
                );
              } else {
                controller.showLargePhoto(context, widget.message);
              }
            },
            child: imageChild,
          )
        : GestureDetector(
            onTap: controller.chatController.popupEnabled ||
                    widget.message.isSendFail ||
                    !widget.message.isSendOk
                ? null
                : () => controller.showLargePhoto(context, widget.message),
            child: imageChild,
          );
  }

  Widget _buildAsset() {
    return Obx(() {
      final filePath = msgImg.filePath;
      final remoteFileExist = downloadMgrV2.getLocalPath(
            msgImg.url,
            mini: Config().messageMin,
          ) !=
          null;
      final fileExist = objectMgr.userMgr.isMe(widget.message.send_id) &&
          filePath.isNotEmpty &&
          File(filePath).existsSync() &&
          !remoteFileExist;

      return RemoteImageV2(
        src: fileExist ? filePath : source.value,
        width: width.value,
        height: height.value,
        mini: source.value == imageMgr.getBlurHashSavePath(msgImg.url) ||
                source.value == msgImg.gausPath ||
                fileExist
            ? null
            : Config().messageMin,
        fit: BoxFit.cover,
        enableShimmer: true,
      );
    });
  }

  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      controller.chatController.removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
    }
  }

  Widget _buildProgress(BuildContext context) {
    return Obx(() {
      Widget child = const SizedBox();

      if (showDoneIcon.value) {
        child = SvgPicture.asset(
          key: UniqueKey(),
          'assets/svgs/done_upload_icon.svg',
          width: 40,
          height: 40,
        );
      } else if (widget.message.isSendOk) {
        if (isDownloading.value) {
          child = _buildDownloadProgress(context);
        } else if (widget.message.asset == null &&
            !isThumbnailReady.value &&
            !isDownloading.value) {
          child = _buildDownload(context);
        }
      } else if (!widget.message.isSendOk) {
        child = _buildUploadProgress(context);
      }

      return AnimatedSwitcher(
        switchInCurve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
        child: child,
      );
    });
  }

  Widget _buildUploadProgress(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.message.isSendFail
          ? GestureDetector(
              key: UniqueKey(),
              onTap: controller.chatController.popupEnabled ? null : _onRetry,
              child: SvgPicture.asset(
                'assets/svgs/resend_icon.svg',
                width: 40,
                height: 40,
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorTextSecondary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularLoadingBarRotate(
                    key: ValueKey(widget.index),
                    value: widget.message.uploadProgress,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      objectMgr.chatMgr.localDelMessage(widget.message);
                      if (widget.message.sendState != MESSAGE_SEND_SUCCESS) {
                        if (widget.message.sendState != MESSAGE_SEND_FAIL) {
                          widget.message.sendState = MESSAGE_SEND_FAIL;
                        }
                        widget.message.resetUploadStatus();
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    return Container(
      key: UniqueKey(),
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2.0),
      child: Stack(
        children: <Widget>[
          CircularLoadingBarRotate(
            key: ValueKey(widget.index),
            value: downloadPercentage.value,
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () {
              thumbCancelToken.cancel();
              thumbCancelToken = CancelToken();
              isDownloading.value = false;
              downloadPercentage.value = 0.0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownload(BuildContext context) {
    return GestureDetector(
      onTap: _preloadImageSync,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: UniqueKey(),
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(2.0),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/svgs/download_file_icon.svg',
          width: 20.0,
          height: 20.0,
          colorFilter: const ColorFilter.mode(
            colorWhite,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
