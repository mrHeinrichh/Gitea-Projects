import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/components/file_icon.dart';
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
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:open_filex/open_filex.dart';

class GroupFileMeItem extends StatefulWidget {
  const GroupFileMeItem({
    super.key,
    required this.messageFile,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  final MessageFile messageFile;
  final Chat chat;
  final Message message;
  final int index;
  final bool isPrevious;

  @override
  State<GroupFileMeItem> createState() => _GroupFileMeItemState();
}

class _GroupFileMeItemState extends MessageWidgetMixin<GroupFileMeItem> {
  late ChatContentController controller;
  late MessageFile msgFile;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  final downloadProgress = 0.0.obs;
  final isDownloaded = false.obs;
  CancelToken? cancelToken;
  String? cacheUrl;

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  RxString source = ''.obs;
  final thumbCancelToken = CancelToken();

  RxBool isDownloading = false.obs;

  bool shouldOpenFile = true;

  bool get isPinnedOpen => controller.chatController.isPinnedOpened;

  double get maxWidth => jxDimension.groupTextMeMaxWidth();

  double get extraWidth => getNewLineExtraWidth(
        showPinned: showPinned,
        isEdit: widget.message.edit_time > 0,
        isSender: false,
        emojiUserList: emojiUserList,
        groupTextMessageReadType: _readType,
        // messageEmojiOnly:messageEmojiOnly,
        showReplyContent: showReplyContent,
        showTranslationContent: showTranslationContent.value,
      );

  bool get showReplyContent => msgFile.reply.isNotEmpty;

  bool get showPinned {
    RxList<Message> pinList = controller.chatController.pinMessageList;
    return pinList.firstWhereOrNull((e) => e.id == widget.message.id) != null;
  }

  String get pathWithFileName {
    String str = widget.messageFile.url;
    int index = widget.messageFile.url.lastIndexOf("/");
    String name = widget.messageFile.file_name;
    int len = widget.messageFile.url.length;
    if (index > len - 1) {
      index = len - 1;
    }
    if (index < 0) {
      index = 0;
    }
    return '${str.substring(0, index)}/$name';
  }

  @override
  void dispose() {
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    objectMgr.off(ObjectMgr.eventAppLifeState, _onAppLifecycleChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
    msgFile = widget.messageFile;

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    objectMgr.on(ObjectMgr.eventAppLifeState, _onAppLifecycleChange);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;
    checkFileDownload();

    _preloadImageSync();
  }

  Future<File?> downloadToLocal() async {
    isDownloading.value = true;
    var pathStr = await cacheMediaMgr.downloadMediaWithCache(
      widget.messageFile.url,
      timeout: const Duration(seconds: 3000),
      cancelToken: cancelToken,
      onReceiveProgress: (double percentage) {
        downloadProgress.value = max(percentage, downloadProgress.value);
      },
    );

    isDownloading.value = false;

    if (pathStr != null) {
      final file = File(pathStr);
      if (!file.existsSync()) {
        isDownloaded.value = false;
        pdebug('Invalid File. Cannot open');
        return null;
      } else {
        isDownloaded.value = true;
        cacheUrl = pathStr;
        return File(pathStr);
      }
    } else {
      isDownloaded.value = false;
      downloadProgress.value = 0.0;
      return null;
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

  void _onAppLifecycleChange(_, __, data) {
    if (data is AppLifecycleState &&
        data == AppLifecycleState.resumed &&
        !isDownloaded.value) {
      checkFileDownload();
    }
  }

  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      controller.chatController.removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
    }
  }

  void checkFileDownload() {
    if (widget.messageFile.filePath != null &&
        (File(widget.messageFile.filePath).existsSync() ||
            File(downloadMgr.appDocumentRootPath + pathWithFileName)
                .existsSync())) {
      isDownloaded.value = true;
      if (File(widget.messageFile.filePath).existsSync()) {
        cacheUrl = widget.messageFile.filePath;
      } else {
        cacheUrl = '${downloadMgr.appDocumentRootPath}/$pathWithFileName';
      }
    } else {
      if (File('${downloadMgr.appDocumentRootPath}/$pathWithFileName')
          .existsSync()) {
        isDownloaded.value = true;
        cacheUrl = '${downloadMgr.appDocumentRootPath}/$pathWithFileName';
      }

      if (cacheUrl != null && cacheUrl!.isNotEmpty) {
        isDownloaded.value = true;
      } else {
        final fileExist = downloadMgrV2.getLocalPath(widget.messageFile.url);
        if (fileExist != null) {
          cacheUrl = fileExist;
          isDownloaded.value = true;
          return;
        }
        if (widget.messageFile.size != null &&
            widget.messageFile.size <= 5 * 1024 * 1024) {
          final fileExist = downloadMgrV2.getLocalPath(widget.messageFile.url);
          if (fileExist == null) {
            downloadToLocal();
            return;
          }

          isDownloaded.value = true;
          cacheUrl = fileExist;
        } else {
          final percentage =
              cacheMediaMgr.getDownloadPercentage(widget.messageFile.url);

          if (percentage != null) {
            shouldOpenFile = false;
            downloadToLocal();
            return;
          }

          isDownloaded.value = false;
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

  void refreshBubble(sender, type, data) {
    if (data is String) {
      msgFile = MessageFile()..applyJson(jsonDecode(data));
    }

    if (data is Message && widget.message.isSendOk) {
      _preloadImageSync();
    }

    if (mounted) setState(() {});
  }

  _preloadImageSync() {
    if (msgFile.gausPath.isEmpty) {
      source.value = msgFile.cover;
    } else {
      if (msgFile.gausPath.contains('Image/')) {
        source.value = msgFile.gausPath;
      } else {
        source.value = imageMgr.getBlurHashSavePath(msgFile.cover);

        if (source.value.isNotEmpty && !File(source.value).existsSync()) {
          imageMgr.genBlurHashImage(
            msgFile.gausPath,
            msgFile.cover,
          );
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      msgFile.cover,
      mini: Config().headMin,
    );

    if (thumbPath != null) {
      source.value = msgFile.cover;
      if (mounted) setState(() {});
      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    // final thumbPath = await downloadMgr.downloadFile(
    //   msgFile.cover,
    //   mini: Config().headMin,
    //   cancelToken: thumbCancelToken,
    //   priority: 3,
    // );
    DownloadResult result = await downloadMgrV2.download(msgFile.cover,
        mini: Config().headMin, cancelToken: thumbCancelToken);
    final thumbPath = result.localPath;
    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = msgFile.cover;
    }
  }

  @override
  Widget build(BuildContext context) {
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: widget.messageFile.caption,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      reply: null,
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: false,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      isReceiver: false,
      minWidth: 0,
    );
    _readType = bean.type;
    Widget child = messageBody(context, bean: bean);
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
                  onTapUp: (details) {
                    if (controller.isCTRLPressed()) {
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
                        ),
                        bubbleType: BubbleType.sendBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                          widget.message,
                          widget.chat,
                        ),
                        topWidget: EmojiSelector(
                          chat: widget.chat,
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
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
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

  Widget messageBody(BuildContext context, {required NewLineBean bean}) {
    final fileType = getFileType(msgFile.url);

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

      Widget topWidget = const SizedBox();
      if (msgFile.reply.isNotEmpty) {
        topWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.chatController.popupEnabled
              ? null
              : () => onPressReply(
                    controller.chatController,
                    widget.message,
                  ),
          child: MessageReplyComponent(
            replyModel: ReplyModel.fromJson(
              json.decode(msgFile.reply),
            ),
            message: widget.message,
            chat: widget.chat,
            maxWidth: maxWidth,
            controller: controller,
          ),
        );
      }
      if (msgFile.forward_user_id != 0) {
        topWidget = Padding(
          padding: const EdgeInsets.only(left: 4),
          child: MessageForwardComponent(
            forwardUserId: msgFile.forward_user_id,
            maxWidth: maxWidth,
            padding: const EdgeInsets.only(bottom: 4),
            isSender: false,
          ),
        );
      }

      Widget bottomWidget = SizedBox(
        key: ValueKey('bottom_widget_${widget.message.id}'),
      );
      if (msgFile.caption.isNotEmpty) {
        bottomWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 文本
            if (showOriginalContent.value)
              Container(
                padding: EdgeInsets.only(top: 4.w, bottom: getBottom(bean)),
                child: RichText(
                  text: TextSpan(
                    children: [
                      ...BuildTextUtil.buildSpanList(
                        widget.message,
                        msgFile.caption,
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
              MessageTranslateComponent(
                chat: baseController.chat,
                message: message,
                controller: controller,
                translatedText: translationText.value,
                locale: translationLocale.value,
                showDivider:
                    showOriginalContent.value && showTranslationContent.value,
                isSender: false,
                showPinned: showPinned,
              ),
          ],
        );
      }

      Widget fileTitle = ConstrainedBox(
        constraints: objectMgr.loginMgr.isDesktop
            ? BoxConstraints(maxWidth: maxWidth - 105.w)
            : BoxConstraints(maxWidth: maxWidth - 105.w, maxHeight: 42.w),
        child: Text(
          msgFile.file_name,
          style: jxTextStyle.headerText(color: bubblePrimary),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      );

      Widget fileSubtitle = SizedBox(
        height: objectMgr.loginMgr.isDesktop ? null : 18.w,
        child: Text(
          widget.message.isSendOk
              ? fileSize(msgFile.size)
              : '${fileSize((msgFile.size * widget.message.uploadProgress).toInt())} / ${fileSize(msgFile.size)}',
          style: jxTextStyle.normalSmallText(color: bubblePrimary),
        ),
      );

      if (msgFile.file_name.toLowerCase().contains('.pdf') &&
          (msgFile.cover.isNotEmpty || msgFile.isEncrypt == 1)) {
        return buildPdfBubble(
          context,
          position,
          showPinned,
          topWidget,
          bottomWidget,
          fileTitle,
          fileSubtitle,
        );
      }

      if ((fileType == FileType.image || fileType == FileType.video) &&
          msgFile.cover.isNotEmpty) {
        // 带封面图片
        return buildMediaBubble(
          context,
          position,
          showPinned,
          topWidget,
          bottomWidget,
          fileTitle,
          fileSubtitle,
        );
      }

      Widget fileDisplay = const SizedBox();
      if (widget.message.isSendOk) {
        fileDisplay = FileIcon(
          fileName: msgFile.file_name,
        );
      } else {
        if (widget.message.isSendFail) {
          fileDisplay = GestureDetector(
            key: UniqueKey(),
            onTap: controller.chatController.popupEnabled ? null : _onRetry,
            child: Container(
              alignment: Alignment.center,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bubblePrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                size: 20,
                color: colorWhite,
              ),
            ),
          );
        } else {
          fileDisplay = GestureDetector(
            key: ValueKey('file_upload_ ${widget.message.id}'),
            onTap: () {
              objectMgr.chatMgr.localDelMessage(widget.message);
              if (widget.message.sendState != MESSAGE_SEND_SUCCESS) {
                widget.message.sendState = MESSAGE_SEND_FAIL;
                widget.message.resetUploadStatus();
              }
              if (mounted) setState(() {});
            },
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: bubblePrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: colorWhite,
                    size: 20,
                  ),
                ),
                CircularLoadingBarRotate(
                  value: max(widget.message.uploadProgress, 0.05),
                ),
              ],
            ),
          );
        }
      }

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4 : 0,
          ),
          alignment: Alignment.centerRight,
          constraints: BoxConstraints(
            maxWidth: jxDimension.groupTextMeMaxWidth(),
          ),
          child: Stack(
            children: <Widget>[
              ChatBubbleBody(
                type: BubbleType.sendBubble,
                verticalPadding: 0,
                horizontalPadding: 12,
                position: position,
                isPressed: isPressed.value,
                constraints: BoxConstraints(maxWidth: maxWidth),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 12),
                    topWidget,
                    GestureDetector(
                      onTap: controller.chatController.popupEnabled
                          ? null
                          : onMsgTapped,
                      child: ConstrainedBox(
                        constraints: _buildBubbleConstraints(),
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOut,
                                child: fileDisplay,
                              ),
                              const SizedBox(width: 8.0),
                              _buildPdfWidget(fileTitle, fileSubtitle),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (bottomWidget.key !=
                        ValueKey('bottom_widget_${widget.message.id}'))
                      const SizedBox(height: 6),
                    bottomWidget,
                    SizedBox(height: emojiUserList.isNotEmpty ? 0 : 17.0),

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
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: EmojiListItem(
                              emojiModelList: emojiUserList,
                              message: widget.message,
                              controller: controller,
                              eMargin: EmojiMargin.me,
                              isSender: true,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 4,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned: showPinned,
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
          ),
        ),
      );
    });
  }

  //json file, 發送檔案時的過場
  BoxConstraints _buildBubbleConstraints() {
    if (objectMgr.loginMgr.isDesktop) {
      return BoxConstraints(
        minWidth: 150,
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      );
    } else {
      return BoxConstraints(
        minWidth: 150,
        maxWidth: maxWidth - 24.w,
      );
    }
  }

  Column _buildFileWidget(Widget fileTitle, Widget fileSubtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        fileTitle,
        fileSubtitle,
      ],
    );
  }

  Widget _buildPdfWidget(Widget fileTitle, Widget fileSubtitle) {
    if (objectMgr.loginMgr.isDesktop) {
      return Expanded(
        child: _buildFileWidget(
          fileTitle,
          fileSubtitle,
        ),
      );
    } else {
      return _buildFileWidget(fileTitle, fileSubtitle);
    }
  }

  Future<void> onMsgTapped() async {
    shouldOpenFile = true;
    final bool isMobile = objectMgr.loginMgr.isMobile;
    cancelToken?.cancel();
    cancelToken = null;
    cancelToken = CancelToken();
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
      if (!widget.message.isSendOk) return;
      File? file;
      if (isDownloaded.value) {
        final messageContent = jsonDecode(widget.message.content);
        if (File(messageContent['filePath'] ?? "").existsSync() ||
            File(downloadMgr.appDocumentRootPath + pathWithFileName)
                .existsSync()) {
          file = File(messageContent['filePath']).existsSync()
              ? File(messageContent['filePath'])
              : File(downloadMgr.appDocumentRootPath + pathWithFileName);
        } else {
          file = File(cacheUrl!);
        }
      } else {
        file = await downloadToLocal();
      }

      if (file != null) {
        final fileWithFileName =
            File('${downloadMgr.appDocumentRootPath}/$pathWithFileName');

        try {
          if (!fileWithFileName.existsSync()) {
            fileWithFileName.createSync(recursive: true);
            fileWithFileName.writeAsBytesSync(file.readAsBytesSync());
          }
          file = fileWithFileName;
        } catch (e, s) {
          pdebug('Error: $e', stackTrace: s);
          return;
        }

        if (!shouldOpenFile || !mounted) return;

        if (objectMgr.loginMgr.isDesktop && file.path.contains('.pdf')) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("选择操作"),
                content: const Text("请选择您想要执行的操作"),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // 打开按钮的逻辑
                          Navigator.of(context).pop();
                          final result = await OpenFilex.open(
                            file!.path,
                          );
                          if (result.type == ResultType.noAppToOpen) {
                            Toast.showToast(result.message);
                          } else if (result.type == ResultType.fileNotFound) {
                            Toast.showToast(result.message);
                          } else if (result.type != ResultType.done) {
                            if (isMobile) {
                              Toast.showToast(result.message);
                            } else {
                              await desktopDownloadMgr.desktopDownload(
                                  widget.message, context);
                            }
                          }
                        },
                        child: const Text("打开"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 下载按钮的逻辑
                          Navigator.of(context).pop();
                          desktopDownloadMgr.desktopDownload(
                            widget.message,
                            context,
                          );
                        },
                        child: const Text("下载"),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
          return;
        }

        final result = await OpenFilex.open(
          file.path,
        );
        if (result.type == ResultType.noAppToOpen) {
          Toast.showToast(result.message);
        } else if (result.type == ResultType.fileNotFound) {
          Toast.showToast(result.message);
        } else if (result.type != ResultType.done) {
          if (isMobile) {
            Toast.showToast(result.message);
          } else {
            await desktopDownloadMgr.desktopDownload(widget.message, context);
          }
        }
      }
      // }
    }
  }

  String showFileName() {
    if (msgFile.file_name.length > 15 + msgFile.suffix.length) {
      return msgFile.file_name.replaceRange(
        8,
        msgFile.file_name.length - msgFile.suffix.length - 3,
        '...',
      );
    }
    return msgFile.file_name;
  }

  Widget buildPdfBubble(
    BuildContext context,
    BubblePosition position,
    bool showPinned,
    Widget topWidget,
    Widget bottomWidget,
    Widget fileTitle,
    Widget fileSubtitle,
  ) {
    Widget fileDisplay = const SizedBox();

    fileDisplay = Stack(
      alignment: Alignment.center,
      children: [
        if (msgFile.isEncrypt == 1)
          SvgPicture.asset(
            'assets/svgs/pdf_encrypt_lock_outlined.svg',
            key: widget.message.isSendOk
                ? ValueKey('encrypt_icon_${widget.message.id}')
                : null,
            width: 24.w,
            height: 24.w,
            colorFilter: ColorFilter.mode(
              bubblePrimary,
              BlendMode.srcIn,
            ),
          )
        else if (msgFile.cover.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            key: ValueKey('file_cover_${widget.message.id}'),
            child: Obx(
              () => RemoteImageV2(
                src: source.value,
                width: 74.w,
                height: 74.w,
                fit: BoxFit.cover,
                mini:
                    source.value == imageMgr.getBlurHashSavePath(msgFile.cover)
                        ? null
                        : Config().headMin,
              ),
            ),
          ),
        _onProgressBuild(context),
      ],
    );

    fileDisplay = Container(
      height: 74.w,
      width: 74.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bubblePrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: fileDisplay,
    );

    // 带封面pdf
    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
          bottom: isPinnedOpen ? 4 : 0,
        ),
        alignment: Alignment.centerRight,
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: <Widget>[
            ChatBubbleBody(
              type: BubbleType.sendBubble,
              verticalPadding: emojiUserList.isNotEmpty ? 0 : 8.w,
              horizontalPadding: 8.w,
              position: position,
              isPressed: isPressed.value,
              constraints: objectMgr.loginMgr.isDesktop
                  ? const BoxConstraints(maxWidth: 480)
                  : null,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (emojiUserList.isNotEmpty)
                    SizedBox(
                      height: 8.w,
                    )
                  else
                    const SizedBox(
                      height: 0,
                    ),
                  topWidget,
                  GestureDetector(
                    onTap: controller.chatController.popupEnabled
                        ? null
                        : onMsgTapped,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 150,
                        maxWidth: maxWidth,
                      ),
                      child: IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            fileDisplay,
                            const SizedBox(width: 12.0),
                            _buildPdfWidget(fileTitle, fileSubtitle),
                          ],
                        ),
                      ),
                    ),
                  ),
                  bottomWidget,
                  SizedBox(height: emojiUserList.isNotEmpty ? 2 : 0),

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
                            controller.onViewReactList(context, emojiUserList),
                        child: EmojiListItem(
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: controller,
                          eMargin: EmojiMargin.me,
                          isSender: true,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Positioned(
              right: 8.w,
              bottom: 8.w,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: showPinned,
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
        ),
      ),
    );
  }

  Widget buildMediaBubble(
    BuildContext context,
    BubblePosition position,
    bool showPinned,
    Widget topWidget,
    Widget bottomWidget,
    Widget fileTitle,
    Widget fileSubtitle,
  ) {
    Widget fileDisplay = const SizedBox();

    fileDisplay = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (msgFile.cover.isNotEmpty)
          ClipRRect(
            key: ValueKey('file_cover_${widget.message.id}'),
            borderRadius: BorderRadius.circular(8.0),
            child: Obx(
              () => RemoteImageV2(
                src: source.value,
                width: 74.w,
                height: 74.w,
                fit: BoxFit.cover,
                mini:
                    source.value == imageMgr.getBlurHashSavePath(msgFile.cover)
                        ? null
                        : Config().headMin,
              ),
            ),
          ),
        _onProgressBuild(context),
      ],
    );

    fileDisplay = Container(
      height: 74.0,
      width: 74.0,
      alignment: Alignment.center,
      child: fileDisplay,
    );

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
          bottom: isPinnedOpen ? 4 : 0,
        ),
        alignment: Alignment.centerRight,
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: <Widget>[
            ChatBubbleBody(
              type: BubbleType.sendBubble,
              verticalPadding: 8.w,
              horizontalPadding: 8.w,
              position: position,
              isPressed: isPressed.value,
              constraints: BoxConstraints(maxWidth: maxWidth),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  topWidget,
                  GestureDetector(
                    onTap: controller.chatController.popupEnabled
                        ? null
                        : onMsgTapped,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 150,
                        maxWidth: maxWidth,
                      ),
                      child: _buildMediaFileWidget(
                        fileDisplay,
                        fileTitle,
                        fileSubtitle,
                      ),
                    ),
                  ),
                  bottomWidget,

                  // SizedBox(height: emojiUserList.isNotEmpty ? 2 : 0),

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
                            controller.onViewReactList(context, emojiUserList),
                        child: EmojiListItem(
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: controller,
                          eMargin: EmojiMargin.me,
                          isSender: true,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Positioned(
              right: 8.w,
              bottom: 8.w,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: showPinned,
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
        ),
      ),
    );
  }

  Widget _buildMediaFileWidget(
      Widget fileDisplay, Widget fileTitle, Widget fileSubtitle) {
    if (objectMgr.loginMgr.isDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: fileDisplay),
          Flexible(
              child: Container(
            padding: EdgeInsets.fromLTRB(8.w, 8.w, 0, 8.w),
            child: _buildFileWidget(fileTitle, fileSubtitle),
          )),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          fileDisplay,
          Container(
            padding: EdgeInsets.fromLTRB(8.w, 8.w, 0, 8.w),
            child: _buildFileWidget(fileTitle, fileSubtitle),
          )
        ],
      );
    }
  }

  Widget _onProgressBuild(BuildContext context) {
    if (isDownloaded.value) {
      return const SizedBox();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      child: widget.message.isSendOk
          ? isDownloading.value
              ? GestureDetector(
                  key: ValueKey('file_download_${widget.message.id}'),
                  onTap: () {
                    cancelToken?.cancel();
                    isDownloading.value = false;
                    downloadProgress.value = 0.0;
                    cacheMediaMgr.removeDownloadedMediaCache(
                      widget.messageFile.url,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colorTextPrimary.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: colorWhite,
                          size: 20,
                        ),
                      ),
                      CircularLoadingBarRotate(value: downloadProgress.value),
                    ],
                  ),
                )
              : Container(
                  key: UniqueKey(),
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: colorTextPrimary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svgs/download_file_icon.svg',
                    width: 24.0,
                    height: 24.0,
                    colorFilter: const ColorFilter.mode(
                      colorWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                )
          : widget.message.isSendFail
              ? GestureDetector(
                  key: UniqueKey(),
                  onTap:
                      controller.chatController.popupEnabled ? null : _onRetry,
                  child: Container(
                    alignment: Alignment.center,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bubblePrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: colorWhite,
                    ),
                  ),
                )
              : GestureDetector(
                  key: ValueKey('file_upload_ ${widget.message.id}'),
                  onTap: () {
                    objectMgr.chatMgr.localDelMessage(widget.message);
                    if (widget.message.sendState != MESSAGE_SEND_SUCCESS) {
                      if (widget.message.sendState != MESSAGE_SEND_FAIL) {
                        widget.message.sendState = MESSAGE_SEND_FAIL;
                      }
                      widget.message.resetUploadStatus();
                    }
                    if (mounted) setState(() {});
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: bubblePrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: colorWhite,
                          size: 20,
                        ),
                      ),
                      CircularLoadingBarRotate(
                        value: max(widget.message.uploadProgress, 0.05),
                      ),
                    ],
                  ),
                ),
    );
  }

  double getBottom(NewLineBean bean) {
    if (bean.type == GroupTextMessageReadType.beakLineType) {
      return 12.w;
    }
    return 0;
  }
}
