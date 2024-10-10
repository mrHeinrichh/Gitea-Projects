import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/circular_progress.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class GroupFileSenderItem extends StatefulWidget {
  const GroupFileSenderItem({
    super.key,
    required this.messageFile,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  final Chat chat;
  final Message message;
  final MessageFile messageFile;
  final int index;
  final bool isPrevious;

  @override
  State<GroupFileSenderItem> createState() => _GroupFileSenderItemState();
}

class _GroupFileSenderItemState extends State<GroupFileSenderItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  bool isSend = false;

  File? file;
  int sendID = 0;

  //图片资源src
  RxString source = ''.obs;
  final thumbCancelToken = CancelToken();

  final downloadProgress = 0.0.obs;

  final isDownloaded = false.obs;

  bool get isDownloading => downloadProgress > 0 && downloadProgress < 1.0;

  CancelToken? _cancelToken;

  String? cacheUrl;

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    objectMgr.on(ObjectMgr.eventAppLifeState, _onAppLifecycleChange);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
    checkFileDownload();

    _preloadImageSync();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageFile.forward_user_id;
    }
  }

  void _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
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

  _preloadImageSync() {
    if (widget.messageFile.gausPath.isEmpty) {
      source.value = widget.messageFile.cover;
    } else {
      if (widget.messageFile.gausPath.contains('Image/')) {
        source.value = widget.messageFile.gausPath;
      } else {
        source.value = imageMgr.getBlurHashSavePath(widget.messageFile.cover);

        if (source.value.isNotEmpty && !File(source.value).existsSync()) {
          imageMgr.genBlurHashImage(
            widget.messageFile.gausPath,
            widget.messageFile.cover,
          );
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgr.checkLocalFile(
      widget.messageFile.cover,
      mini: Config().headMin,
    );

    if (thumbPath != null) {
      source.value = widget.messageFile.cover;
      if (mounted) setState(() {});
      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    final thumbPath = await downloadMgr.downloadFile(
      widget.messageFile.cover,
      mini: Config().headMin,
      cancelToken: thumbCancelToken,
      priority: 3,
    );
    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = widget.messageFile.cover;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    objectMgr.off(ObjectMgr.eventAppLifeState, _onAppLifecycleChange);

    super.dispose();
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

  String get pathWithFileName =>
      '/${widget.messageFile.url.substring(0, widget.messageFile.url.lastIndexOf("/"))}/${widget.messageFile.file_name}';

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

  void checkFileDownload() {
    if (File('${downloadMgr.appDocumentRootPath}/$pathWithFileName')
        .existsSync()) {
      isDownloaded.value = true;
      cacheUrl = '${downloadMgr.appDocumentRootPath}/$pathWithFileName';
    }

    if (cacheUrl != null && cacheUrl!.isNotEmpty) {
      isDownloaded.value = true;
    } else {
      final messageContent = jsonDecode(widget.message.content);
      if ((messageContent['size'] != null &&
              messageContent['size'] <= 5 * 1024 * 1024) ||
          widget.messageFile.length <= 5 * 1024 * 1024) {
        downloadToLocal();
      } else {
        isDownloaded.value = false;
      }
    }
  }

  Future<File?> downloadToLocal() async {
    _cancelToken = CancelToken();
    var pathStr = await cacheMediaMgr.downloadMedia(
      widget.messageFile.url,
      timeout: const Duration(seconds: 3000),
      onReceiveProgress: (int received, int total) {
        downloadProgress.value = received / total;
      },
      cancelToken: _cancelToken,
    );
    if (pathStr != null) {
      final file = File(pathStr);
      if (!file.existsSync()) {
        isDownloaded.value = false;
        pdebug('Invalid File. Cannot open', toast: true);
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

  Future<void> msgOnTapped() async {
    if (isDownloading) {
      downloadProgress.value = 0.0;
      if (_cancelToken != null) {
        _cancelToken!.cancel('User cancel');
      }
    } else {
      final bool isMobile = objectMgr.loginMgr.isMobile;
      if (controller.isCTRLPressed()) {
        desktopGeneralDialog(
          context,
          color: Colors.transparent,
          widgetChild: DesktopMessagePopMenu(
            offset: tapPosition,
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
        if (isMobile) {
          var status = await Permission.storage.request();
          if (status.isDenied) {
            // The user did not grant permission, handle the situation as you see fit
          }
        }

        File? file;
        if (isDownloaded.value) {
          file = File(cacheUrl!);
        } else {
          downloadProgress.value = 0.05;
          file = await downloadToLocal();
        }

        final fileWithFileName =
            File('${downloadMgr.appDocumentRootPath}/$pathWithFileName');

        try {
          if (!fileWithFileName.existsSync()) {
            fileWithFileName.createSync(recursive: true);
            fileWithFileName.writeAsBytesSync(file!.readAsBytesSync());
            file.deleteSync();
          }
          file = fileWithFileName;
        } catch (e) {
          pdebug('Error: $e', toast: true);
        }

        if (file != null) {
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
  }

  String showFileName() {
    if (widget.messageFile.file_name.length >
        15 + widget.messageFile.suffix.length) {
      return widget.messageFile.file_name.replaceRange(
        8,
        widget.messageFile.file_name.length -
            widget.messageFile.suffix.length -
            3,
        '...',
      );
    }
    return widget.messageFile.file_name;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

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
                  onTapUp: (details) {
                    if (controller.isCTRLPressed()) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
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
                        bubbleType: BubbleType.receiverBubble,
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
    final fileType = getFileType(widget.messageFile.url);

    return Obx(() {
      final showPinned =
          controller.chatController.pinMessageList.firstWhereOrNull(
                (pinnedMsg) => pinnedMsg.id == widget.message.id,
              ) !=
              null;

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

      /// 消息内容
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
          child: MessageReplyComponent(
            replyModel:
                ReplyModel.fromJson(json.decode(widget.messageFile.reply)),
            message: widget.message,
            chat: widget.chat,
            maxWidth: jxDimension.groupTextMeMaxWidth(),
            controller: controller,
          ),
        );
      }
      if (widget.messageFile.forward_user_id != 0 && !widget.chat.isSaveMsg) {
        topWidget = Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: MessageForwardComponent(
            padding: const EdgeInsets.only(bottom: 4),
            forwardUserId: widget.messageFile.forward_user_id,
            maxWidth: jxDimension.groupTextMeMaxWidth(),
            isSender: true,
          ),
        );
      }

      Widget bottomWidget = SizedBox(
        key: ValueKey('bottom_widget_${widget.message.id}'),
      );
      if (widget.messageFile.caption.isNotEmpty) {
        bottomWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 文本
            if (showOriginalContent.value)
              RichText(
                text: TextSpan(
                  children: [
                    ...BuildTextUtil.buildSpanList(
                      widget.message,
                      widget.messageFile.caption,
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
                    ),
                    WidgetSpan(
                      child: SizedBox(
                        width: setWidth(
                          showPinned,
                          widget.message.edit_time > 0,
                        ),
                      ),
                    ),
                  ],
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
              ),
          ],
        );
      }

      Widget fileTitle = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7 - 105.w,
        ),
        child: Text(
          widget.messageFile.file_name,
          style: jxTextStyle.headerText(color: themeColor).copyWith(height: 1),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      );
      Widget fileSubtitle = Text(
        fileSize(widget.messageFile.length),
        style: jxTextStyle.supportText(color: colorTextSecondary),
      );

      bool specialPadding =
          (widget.messageFile.file_name.toLowerCase().contains('.pdf') ||
                  fileType == FileType.image ||
                  fileType == FileType.video) &&
              (widget.messageFile.cover.isNotEmpty ||
                  widget.messageFile.isEncrypt == 1);

      Widget body = const SizedBox();
      if (specialPadding) {
        body = buildSpecialFile(
          context,
          position,
          topWidget,
          bottomWidget,
          fileTitle,
          fileSubtitle,
        );
      } else {
        body = buildNormalFile(
          context,
          position,
          topWidget,
          bottomWidget,
          fileTitle,
          fileSubtitle,
        );
      }

      return Container(
        margin: EdgeInsets.only(
          right: controller.chatController.chooseMore.value
              ? jxDimension.chatRoomSideMargin
              : jxDimension.chatRoomSideMarginMaxGap,
          left: controller.chatController.chooseMore.value
              ? 40
              : (widget.chat.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginSingle
                  : jxDimension.chatRoomSideMargin),
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),
              Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                      left: jxDimension.chatRoomSideMarginAvaR,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: body,
                  ),
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: ChatReadNumView(
                      message: widget.message,
                      chat: widget.chat,
                      showPinned: showPinned,
                      sender: true,
                    ),
                  ),
                  if (isPlayingSound.value || isWaitingRead.value)
                    MessageReadTextIcon(
                      isWaitingRead: isWaitingRead.value,
                      isMe: false,
                      right: 0,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (controller.chat!.isSaveMsg) {
      return Container(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
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

    if (controller.chat!.isSecretary) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar.normal(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
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
                  controller.inputController.addMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget buildSpecialFile(
    BuildContext context,
    BubblePosition position,
    Widget topWidget,
    Widget bottomWidget,
    Widget fileTitle,
    Widget fileSubtitle,
  ) {
    Widget fileDisplay = const SizedBox();

    // 加密 pdf 文件
    if (widget.messageFile.isEncrypt == 1) {
      fileDisplay = SvgPicture.asset(
        'assets/svgs/pdf_encrypt_lock_outlined.svg',
        key: widget.message.isSendOk
            ? ValueKey('encrypt_icon_${widget.message.id}')
            : null,
        width: 24.0,
        height: 24.0,
        colorFilter: ColorFilter.mode(
          themeColor,
          BlendMode.srcIn,
        ),
      );
    } else {
      fileDisplay = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        key: widget.message.isSendOk
            ? ValueKey('file_cover_${widget.message.id}')
            : null,
        child: Obx(() {
          return RemoteImageV2(
            src: source.value,
            width: 74.0,
            height: 74.0,
            fit: BoxFit.cover,
            mini: Config().headMin,
            isFile: source.value ==
                imageMgr.getBlurHashSavePath(widget.messageFile.cover),
          );
        }),
      );
    }

    fileDisplay = Container(
      height: 74.0,
      width: 74.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bubblePrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          fileDisplay,
          _onProgressBuild(context),
        ],
      ),
    );

    return ChatBubbleBody(
      type: BubbleType.receiverBubble,
      verticalPadding: 8.w,
      horizontalPadding: 8.w,
      position: position,
      isPressed: isPressed.value,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // SizedBox(height: emojiUserList.isNotEmpty ? 8 : 0),

          /// 昵称
          if (isFirstMessage || isPinnedOpen)
            Offstage(
              offstage: widget.chat.isSingle ||
                  widget.chat.typ == chatTypeSystem ||
                  widget.chat.typ == chatTypeSmallSecretary,
              child: Column(
                children: [
                  NicknameText(
                    uid: sendID,
                    // color: themeColor,
                    isRandomColor: true,
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: bubbleNicknameSize,
                    groupId: widget.chat.isGroup ? widget.chat.id : null,
                  ),
                  const SizedBox(height: 4.0),
                ],
              ),
            ),

          topWidget,

          GestureDetector(
            onTap: controller.chatController.popupEnabled ? null : msgOnTapped,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 150,
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  fileDisplay,
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      fileTitle,
                      fileSubtitle,
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomWidget,

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
                onTap: () => controller.onViewReactList(context, emojiUserList),
                child: EmojiListItem(
                  emojiModelList: emojiUserList,
                  message: widget.message,
                  controller: controller,
                  eMargin: EmojiMargin.sender,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildNormalFile(
    BuildContext context,
    BubblePosition position,
    Widget topWidget,
    Widget bottomWidget,
    Widget fileTitle,
    Widget fileSubtitle,
  ) {
    Widget fileDisplay = const SizedBox();
    if (isDownloading) {
      fileDisplay = CircularProgress(
        progressValue: downloadProgress.value,
        color: themeColor,
        onClosePressed: msgOnTapped,
      );
    } else {
      if (isDownloaded.value) {
        fileDisplay = FileIcon(
          fileName: widget.messageFile.file_name,
        );
      } else {
        fileDisplay = Container(
          height: 40.0,
          width: 40.0,
          decoration: BoxDecoration(
            color: themeColor,
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
        );
      }
    }

    return ChatBubbleBody(
      type: BubbleType.receiverBubble,
      verticalPadding: 4,
      horizontalPadding: 12,
      position: position,
      isPressed: isPressed.value,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isFirstMessage && !isPinnedOpen) const SizedBox(height: 8.0),

          /// 昵称
          if (isFirstMessage || isPinnedOpen)
            Offstage(
              offstage: widget.chat.isSingle ||
                  widget.chat.typ == chatTypeSystem ||
                  widget.chat.typ == chatTypeSmallSecretary,
              child: Column(
                children: [
                  NicknameText(
                    uid: sendID,
                    // color: themeColor,
                    isRandomColor: true,
                    fontWeight: MFontWeight.bold5.value,
                    groupId: widget.chat.isGroup ? widget.chat.id : null,
                  ),
                  const SizedBox(height: 4.0),
                ],
              ),
            ),

          topWidget,
          GestureDetector(
            onTap: controller.chatController.popupEnabled ? null : msgOnTapped,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  fileDisplay,
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      fileTitle,
                      fileSubtitle,
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomWidget,
          SizedBox(height: emojiUserList.isNotEmpty ? 0 : 17.0),

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
                onTap: () => controller.onViewReactList(context, emojiUserList),
                child: EmojiListItem(
                  emojiModelList: emojiUserList,
                  message: widget.message,
                  controller: controller,
                  eMargin: EmojiMargin.sender,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _onProgressBuild(BuildContext context) {
    if (isDownloaded.value) {
      return const SizedBox();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      child: isDownloading
          ? CircularProgress(
              progressValue: downloadProgress.value,
              color: colorTextPrimary.withOpacity(0.4),
              onClosePressed: msgOnTapped,
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
            ),
    );
  }
}
