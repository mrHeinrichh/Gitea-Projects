import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class GroupVideoMeItem extends StatefulWidget {
  const GroupVideoMeItem({
    super.key,
    required this.controller,
    required this.messageVideo,
    required this.message,
    required this.chat,
    required this.index,
  });

  final ChatContentController controller;
  final MessageVideo messageVideo;
  final Chat chat;
  final Message message;
  final int index;

  @override
  State<GroupVideoMeItem> createState() => _GroupVideoMeItemState();
}

class _GroupVideoMeItemState extends State<GroupVideoMeItem>
    with MessageWidgetMixin, SingleTickerProviderStateMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  late MessageVideo msgVideo;

  //图片资源src
  Rx<Uint8List> gausPath = Uint8List(0).obs;
  RxString source = ''.obs;
  RxBool isThumbnailReady = false.obs;
  RxBool isDownloading = false.obs;
  RxDouble downloadPercentage = 0.0.obs;
  CancelToken thumbCancelToken = CancelToken();

  RxBool showDoneIcon = false.obs;

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    msgVideo = widget.messageVideo;
    showDoneIcon.value = widget.message.showDoneIcon;

    checkExpiredMessage(widget.message);

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);
    // 预加载视频m3u8以及ts第一片
    if (widget.message.message_id != 0) {
      _preloadVideo();
    }

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

  _preloadVideo() {
    videoMgr.preloadVideo(
      msgVideo.url,
      width: msgVideo.width,
      height: msgVideo.height,
    );
  }

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

  void refreshBubble(Object sender, Object type, Object? data) async {
    if (data is Message && widget.message.isSendOk) {
      widget.message.uploadStatus = 0;
      widget.message.showDoneIcon = true;
      showDoneIcon.value = true;
      msgVideo = widget.message.decodeContent(cl: MessageVideo.creator);

      _preloadImageSync();
      Future.delayed(const Duration(seconds: 2), () {
        widget.message.showDoneIcon = false;
        showDoneIcon.value = false;
      });
    }

    if (mounted) setState(() {});
  }

  _preloadImageSync() {
    if (source.value.isEmpty) {
      if (msgVideo.gausPath.isEmpty) {
        source.value = msgVideo.cover;
      } else {
        if (msgVideo.gausPath.contains('Image/')) {
          source.value = msgVideo.gausPath;
        } else {
          source.value = imageMgr.getBlurHashSavePath(msgVideo.cover);

          if (source.value.isNotEmpty && !File(source.value).existsSync()) {
            imageMgr.genBlurHashImage(
              msgVideo.gausPath,
              msgVideo.cover,
            );
          }
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgr.checkLocalFile(
      msgVideo.cover,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      isThumbnailReady.value = true;
      source.value = msgVideo.cover;
      gausPath.value = Uint8List(0);
      return;
    }

    if (File(msgVideo.coverPath).existsSync()) {
      isThumbnailReady.value = true;
    }

    if (msgVideo.coverPath.isEmpty || !File(msgVideo.coverPath).existsSync()) {
      isDownloading.value = true;
      gausPath.value = msgVideo.gausBytes ?? Uint8List(0);
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    final thumbPath = await downloadMgr.downloadFile(
      msgVideo.cover,
      mini: Config().messageMin,
      priority: 3,
      cancelToken: thumbCancelToken,
      onReceiveProgress: (received, total) {
        downloadPercentage.value = received / total;
      },
    );

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      isThumbnailReady.value = true;
      gausPath.value = Uint8List(0);
      source.value = msgVideo.cover;
    }

    isDownloading.value = false;
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  get extraWidth =>
      setWidth(isPinnedOpen, widget.message.edit_time > 0, isMe: true);

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: 16.w);
    }

    return EdgeInsets.zero;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

    // 计算文本宽带
    if (widget.messageVideo.caption.isNotEmpty) {
      _readType = caculateLastLineTextWidth(
        message: widget.message,
        messageText: widget.messageVideo.caption,
        maxWidth: width.value,
        extraWidth: extraWidth,
      );
    }

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
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
                  onTapCancel: () {
                    isPressed.value = false;
                  },
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
                          mediaSubType: widget.messageVideo.caption.isNotEmpty
                              ? MenuMediaSubType.subMediaVideoTxt
                              : MenuMediaSubType.none,
                        ),
                        bubbleType: BubbleType.sendBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                          widget.message,
                          widget.chat,
                          mediaSubType: widget.messageVideo.caption.isNotEmpty
                              ? MenuMediaSubType.subMediaVideoTxt
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
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
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
      if (widget.messageVideo.reply.isNotEmpty) {
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
                json.decode(widget.messageVideo.reply),
              ),
              message: widget.message,
              chat: widget.chat,
              maxWidth: jxDimension.groupTextMeMaxWidth(),
              controller: controller,
            ),
          ),
        );
      }

      if (widget.messageVideo.forward_user_id != 0) {
        topBody = MessageForwardComponent(
          padding: forwardTitlePadding,
          forwardUserId: widget.messageVideo.forward_user_id,
          maxWidth: width.value,
          isSender: false,
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageVideo.caption.isNotEmpty) {
        bottomBody = Container(
          padding: getTextSpanPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 文本
              if (showOriginalContent.value)
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4.w),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        ...BuildTextUtil.buildSpanList(
                          widget.message,
                          widget.messageVideo.caption,
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
                          WidgetSpan(child: SizedBox(width: extraWidth)),
                      ],
                    ),
                  ),
                ),
              if (showTranslationContent.value)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4.w),
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

      Widget body = Stack(
        children: <Widget>[
          ChatBubbleBody(
            type: BubbleType.sendBubble,
            position: position,
            isClipped: true,
            isPressed: isPressed.value,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                topBody,
                buildVideoContent(context, position),
                bottomBody,
              ],
            ),
          ),
          Positioned(
            right: 12.w,
            bottom: 4.w,
            child: ChatReadNumView(
              message: widget.message,
              chat: widget.chat,
              showPinned:
                  controller.chatController.pinMessageList.firstWhereOrNull(
                        (pinnedMsg) => pinnedMsg.id == widget.message.id,
                      ) !=
                      null,
              backgroundColor: widget.messageVideo.caption.isEmpty
                  ? colorTextSecondary
                  : Colors.transparent,
              sender: false,
            ),
          ),
        ],
      );

      return Container(
        width: double.infinity,
        alignment: Alignment.centerRight,
        margin: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: SizedBox(
          width: width.value,
          child: AbsorbPointer(
            absorbing: controller.chatController.popupEnabled,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                          onTap: () => controller.onViewReactList(
                            context,
                            emojiUserList,
                          ),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: width.value),
                            margin: const EdgeInsets.only(bottom: 4),
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
                if (isPlayingSound.value || isWaitingRead.value)
                  MessageReadTextIcon(
                    isWaitingRead: isWaitingRead.value,
                    isMe: true,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildVideoContent(BuildContext context, BubblePosition position) {
    BorderRadius videoBorderRadius = BorderRadius.zero;
    if ((widget.messageVideo.reply.isNotEmpty ||
            widget.messageVideo.forward_user_id != 0) &&
        widget.messageVideo.caption.isNotEmpty) {
      videoBorderRadius = BorderRadius.zero;
    } else if (widget.messageVideo.forward_user_id != 0 ||
        widget.messageVideo.reply.isNotEmpty) {
      videoBorderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(
          BubbleCorner.bottomLeftCorner(position, BubbleType.sendBubble),
        ),
        bottomRight: Radius.circular(
          BubbleCorner.bottomRightCorner(position, BubbleType.sendBubble),
        ),
      );
    } else if (widget.messageVideo.caption.isNotEmpty) {
      videoBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(
          BubbleCorner.topLeftCorner(position, BubbleType.sendBubble),
        ),
        topRight: Radius.circular(
          BubbleCorner.topRightCorner(position, BubbleType.sendBubble),
        ),
      );
    } else {
      videoBorderRadius = bubbleSideRadius(position, BubbleType.sendBubble);
    }

    final Widget childWidget = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: videoBorderRadius,
        color: isPressed.value ? colorBorder : null,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          buildAsset(),
          Obx(() {
            if (gausPath.value.isNotEmpty) {
              return Image.memory(
                gausPath.value,
                width: width.value,
                height: height.value,
                fit: BoxFit.cover,
              );
            }

            return const SizedBox();
          }),
          if (isPressed.value)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: videoBorderRadius,
                  color: colorBorder,
                ),
              ),
            ),
          _buildProgress(context),
          _buildStatus(),
        ],
      ),
    );
    return objectMgr.loginMgr.isDesktop
        ? DesktopGeneralButton(
            horizontalPadding: 0,
            onPressed: () async {
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
            child: childWidget,
          )
        : GestureDetector(
            onTap: controller.chatController.popupEnabled ||
                    widget.message.isSendFail ||
                    !widget.message.isSendOk
                ? null
                : () => controller.showLargePhoto(context, widget.message),
            child: childWidget,
          );
  }

  Widget buildAsset() {
    if (objectMgr.loginMgr.isDesktop) {
      return Hero(
        tag: 'media_detail_${widget.message.message_id}',
        child: widget.messageVideo.cover.isNotEmpty
            ? RemoteImage(
                src: widget.messageVideo.cover,
                width: width.toDouble(),
                height: height.toDouble(),
                mini: Config().messageMin,
                fit: BoxFit.cover,
              )
            : widget.messageVideo.coverPath.isNotEmpty
                ? Image.file(
                    File(widget.messageVideo.coverPath),
                    width: width.value,
                    height: height.value,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(),
      );
    }

    return Obx(() {
      final coverPath = msgVideo.coverPath;
      final remoteFileExist = downloadMgr.checkLocalFile(
            msgVideo.cover,
            mini: Config().messageMin,
          ) !=
          null;

      final bool coverExist = objectMgr.userMgr.isMe(widget.message.send_id) &&
          coverPath.isNotEmpty &&
          File(coverPath).existsSync() &&
          !remoteFileExist;

      return RemoteImageV2(
        src: coverExist ? coverPath : source.value,
        width: width.value,
        height: height.value,
        mini: source.value == imageMgr.getBlurHashSavePath(msgVideo.cover) ||
                source.value == msgVideo.gausPath ||
                coverExist
            ? null
            : Config().messageMin,
        isFile: source.value == imageMgr.getBlurHashSavePath(msgVideo.cover) ||
            coverExist,
        fit: BoxFit.cover,
        enableShimmer: false,
      );
    });
  }

  Widget _buildProgress(BuildContext context) {
    return Obx(() {
      Widget child = const SizedBox();

      if (showDoneIcon.value) {
        child = SvgPicture.asset(
          key: ValueKey('showDoneIcon_${widget.message.id}'),
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
        } else {
          child = SvgPicture.asset(
            key: ValueKey(
              'messageSendState_${widget.message.id}',
            ),
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          );
        }
      } else if (!widget.message.isSendOk) {
        child = _buildUploadProgress();
      } else {
        child = SvgPicture.asset(
          key: ValueKey(
            'messageSendState_${widget.message.id}',
          ),
          'assets/svgs/video_play_icon.svg',
          width: 40,
          height: 40,
        );
      }

      return AnimatedSwitcher(
        switchInCurve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
        child: child,
      );
    });
  }

  Widget _buildStatus() {
    int uploadStatus = widget.message.uploadStatus;

    if (widget.message.isSendOk) {
      uploadStatus = 0;
    }

    final String statusText;

    switch (uploadStatus) {
      case 1:
      case 2:
        statusText = localized(preparing);
        break;
      case 3:
        statusText =
            '${(fileMB((widget.message.totalSize * widget.message.uploadProgress).toInt()))} / ${fileMB(widget.message.totalSize)}';
        break;
      case 4:
        statusText = localized(uploadComplete);
        break;
      default:
        statusText = formatVideoDuration(msgVideo.second);
    }

    return Positioned(
      left: 6,
      top: 6,
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorTextSecondary,
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            fontSize: 12,
            color: colorWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    final int uploadStatus = widget.message.uploadStatus;
    double progress = 0.0;

    switch (uploadStatus) {
      case 3:
        progress = 0.05 + min(widget.message.uploadProgress * 0.95, 0.95);
        break;
      case 4:
        progress = 1.0;
        if (!showDoneIcon.value) {
          widget.message.showDoneIcon = true;
          showDoneIcon.value = true;

          Future.delayed(const Duration(seconds: 2), () {
            widget.message.showDoneIcon = false;
            showDoneIcon.value = false;
            widget.message.uploadStatus = 5;
            if (mounted) setState(() {});
          });
        }
        break;
      default:
        progress = 0.0;
    }

    if (widget.message.uploadStatus == 5) return const SizedBox();

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
                    value: progress,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (widget.message.sendState != MESSAGE_SEND_SUCCESS) {
                        widget.message.sendState = MESSAGE_SEND_FAIL;
                        widget.message.resetUploadStatus();
                        objectMgr.chatMgr.localDelMessage(widget.message);
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

  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      controller.chatController.removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
    }
  }
}

String formatVideoDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String formattedHours = hours > 0 ? hours.toString().padLeft(2, '0') : '';
  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');

  String duration = '';

  if (formattedHours.isNotEmpty) {
    duration += '$formattedHours:';
  }

  duration += '$formattedMinutes:$formattedSeconds';

  return duration;
}