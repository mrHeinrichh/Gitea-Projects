import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_uploader.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/circular_progress.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class GroupFileMeItem extends StatefulWidget {
  const GroupFileMeItem({
    Key? key,
    required this.messageFile,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final MessageFile messageFile;
  final Chat chat;
  final Message message;
  final int index;
  final isPrevious;

  @override
  State<GroupFileMeItem> createState() => _GroupFileMeItemState();
}

class _GroupFileMeItemState extends State<GroupFileMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;

  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  final downloadProgress = 0.0.obs;

  final isDownloaded = false.obs;

  bool get isDownloading => downloadProgress > 0 && downloadProgress < 1.0;

  String? cacheUrl;

  Future<File?> downloadToLocal() async {
    var _pathStr = await cacheMediaMgr.downloadMedia(
      widget.messageFile.url,
      savePath: downloadMgr.getSavePath(widget.messageFile.file_name),
      timeoutSeconds: 3000,
      onReceiveProgress: (int received, int total) {
        downloadProgress.value = received / total;
      },
    );

    if (_pathStr != null) {
      final file = File(_pathStr);
      if (!file.existsSync()) {
        isDownloaded.value = false;
        mypdebug('Invalid File. Cannot open', toast: true);
        return null;
      } else {
        isDownloaded.value = true;
        cacheUrl = _pathStr;
        return File(_pathStr);
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

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
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

  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      controller.chatController.removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
    }
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;
    checkFileDownload();
  }

  void checkFileDownload() {
    final messageContent = jsonDecode(widget.message.content);

    if (File(messageContent['filePath']).existsSync()) {
      isDownloaded.value = true;
    } else {
      cacheUrl = cacheMediaMgr.checkLocalFile(widget.messageFile.url);
      if (cacheUrl != null && cacheUrl!.isNotEmpty) {
        isDownloaded.value = true;
      } else {
        if (messageContent['size'] <= 5 * 1024 * 1024) {
          downloadToLocal();
        } else {
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
    super.dispose();
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody();

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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
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
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                            widget.message, widget.chat),
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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
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

  Widget messageBody() {
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
      if (widget.messageFile.reply.isNotEmpty) {
        topWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.chatController.popupEnabled
              ? null
              : () => onPressReply(
                    controller.chatController,
                    widget.message,
                  ),
          child: GroupReplyItem(
            replyModel: ReplyModel.fromJson(
              json.decode(widget.messageFile.reply),
            ),
            message: widget.message,
            chat: widget.chat,
            maxWidth: jxDimension.groupTextMeMaxWidth(),
            controller: controller,
          ),
        );
      }
      if (widget.messageFile.forward_user_id != 0) {
        topWidget = Padding(
          padding: const EdgeInsets.only(left: 4),
          child: ChatSourceView(
              forward_user_id: widget.messageFile.forward_user_id,
              maxWidth: jxDimension.groupTextMeMaxWidth(),
              padding: const EdgeInsets.only(bottom: 3),
              isSender: false),
        );
      }

      Widget bottomWidget = const SizedBox();
      if (widget.messageFile.caption.isNotEmpty) {
        bottomWidget = Padding(
          padding: const EdgeInsets.only(top: 5, left: 4),
          child: Material(
            color: Colors.transparent,
            child: Text.rich(
              TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    '${widget.messageFile.caption}',
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
                    textColor: JXColors.chatBubbleMeTextColor,
                    isSender: true,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      Widget displayStatusWidget = const SizedBox();
      Widget fileSubtitle = const SizedBox();

      if (widget.message.isSendOk) {
        displayStatusWidget = Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const ShapeDecoration(
            shape: CircleBorder(),
            color: JXColors.chatBubbleFileMeBgColor,
          ),
          child: SvgPicture.asset(
            isDownloaded.value
                ? 'assets/svgs/file_icon.svg'
                : 'assets/svgs/download_file_icon.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              JXColors.chatBubbleFileMeIconColor,
              BlendMode.srcIn,
            ),
            fit: BoxFit.fill,
          ),
        );

        fileSubtitle = Text(
          '${fileSize(widget.messageFile.length)}',
          style: TextStyle(
            color: JXColors.chatBubbleTimeText,
            fontSize: 12,
            height: 1,
            decoration: TextDecoration.none,
            fontWeight: MFontWeight.bold4.value,
          ),
        );
      } else {
        if (widget.message.isSendFail) {
          displayStatusWidget = GestureDetector(
            onTap: controller.chatController.popupEnabled ? null : _onRetry,
            child: Container(
              alignment: Alignment.center,
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: JXColors.chatBubbleFileMeBgColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                size: 20,
                color: JXColors.chatBubbleFileMeIconColor,
              ),
            ),
          );
        } else {
          displayStatusWidget = CircularProgress(
            progressValue: widget.message.uploadProgress,
            onClosePressed: () {
              FileUploader.shared.cancelFile.add(widget.messageFile.file_name
                  .split(widget.messageFile.suffix)[0]);
              FileUploader.shared.sendTime.add(widget.message.send_time);
              widget.message.sendState = MESSAGE_SEND_FAIL;
              if (mounted) setState(() {});
            },
          );
        }

        fileSubtitle = Text(
          '${fileSize((widget.messageFile.length * widget.message.uploadProgress).toInt())} / ${fileSize(widget.messageFile.length)}',
          style: TextStyle(
            color: JXColors.chatBubbleFileMeSubTitle,
            fontSize: 12,
            height: 1,
            decoration: TextDecoration.none,
            fontWeight: MFontWeight.bold4.value,
          ),
        );
      }

      if (isDownloading) {
        displayStatusWidget = Stack(
          children: <Widget>[
            displayStatusWidget,
            Positioned(
              top: 2,
              left: 2,
              right: 2,
              bottom: 2,
              child: CircularLoadingBar(value: downloadProgress.value),
            ),
          ],
        );
      }

      displayStatusWidget = Container(
        decoration: BoxDecoration(
            color: JXColors.chatBubbleFileMeIconHolderColor,
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(right: 10),
        child: displayStatusWidget,
      );

      Widget messageWidget = Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            displayStatusWidget,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showFileName(),
                    style: TextStyle(
                      color: JXColors.chatBubbleFileMeTitle,
                      fontSize: 17,
                      height: 1,
                      decoration: TextDecoration.none,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                    ),
                    child: fileSubtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      Widget body = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            topWidget,
            GestureDetector(
              onTap:
                  controller.chatController.popupEnabled ? null : onMsgTapped,
              child: messageWidget,
            ),
            bottomWidget,
            // if (isPressed.value)
            //   Positioned.fill(
            //     child: Container(
            //       decoration: BoxDecoration(
            //         borderRadius: bubbleSideRadius(
            //           position,
            //           BubbleType.sendBubble,
            //         ),
            //         color: JXColors.outlineColor,
            //       ),
            //     ),
            //   ),
          ],
        ),
      );

      body = ChatBubbleBody(
        type: BubbleType.sendBubble,
        verticalPadding: 6,
        horizontalPadding: 6,
        position: position,
        isPressed: isPressed.value,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                ),
                child: body),

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
                  onTap: () =>
                      controller.onViewReactList(context, emojiUserList),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
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
          constraints: BoxConstraints(
            maxWidth: jxDimension.groupTextMeMaxWidth(),
          ),
          child: Stack(
            children: [
              body,
              Positioned(
                right: 12,
                bottom: 8,
                child: Obx(
                  () => ChatReadNumView(
                    message: widget.message,
                    chat: widget.chat,
                    showPinned: controller.chatController.pinMessageList
                            .firstWhereOrNull((pinnedMsg) =>
                                pinnedMsg.id == widget.message.id) !=
                        null,
                    sender: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> onMsgTapped() async {
    final bool isMobile = objectMgr.loginMgr.isMobile;
    if (controller.isCTRLPressed()) {
      DesktopGeneralDialog(
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
          menuHeight: ChatPopMenuSheet.getMenuHeight(
              widget.message, widget.chat,
              extr: false),
        ),
      );
    } else {
      if (!widget.message.isSendOk) return;
      if (isMobile) {
        var status = await Permission.storage.request();
        if (status.isDenied) {
          // The user did not grant permission, handle the situation as you see fit
        }
      }
      // final String extension = getFileExtension(widget.messageFile.url);
      // if (readableText.contains(extension) && isMobile) {
      //   getTextFileFromUrl(widget.messageFile.url).then((value) {
      //     if (value.isNotEmpty)
      //       Get.toNamed(RouteName.textViewer, arguments: value);
      //   });
      // } else {
      final File? file;
      if (isDownloaded.value) {
        final messageContent = jsonDecode(widget.message.content);
        if (File(messageContent['filePath']).existsSync()) {
          file = File(messageContent['filePath']);
        } else {
          file = File(cacheUrl!);
        }
      } else {
        file = await downloadToLocal();
      }
      if (file != null) {
        final result = await OpenFilex.open(
          file.path,
        );
        if (result.type == ResultType.noAppToOpen) {
          Toast.showToast('${result.message}');
        } else if (result.type == ResultType.fileNotFound) {
          Toast.showToast('${result.message}');
        } else if (result.type != ResultType.done) {
          if (isMobile)
            Toast.showToast('${result.message}');
          else {
            await desktopDownloadMgr.desktopDownload(widget.message, context);
          }
        }
      }
      // }
    }
  }

  String showFileName() {
    if (widget.messageFile.file_name.length >
        15 + widget.messageFile.suffix.length) {
      return widget.messageFile.file_name.replaceRange(
          8,
          widget.messageFile.file_name.length -
              widget.messageFile.suffix.length -
              3,
          '...');
    }
    return widget.messageFile.file_name;
  }
}
