import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class GroupFileSenderItem extends StatefulWidget {
  const GroupFileSenderItem({
    Key? key,
    required this.messageFile,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final Chat chat;
  final Message message;
  final MessageFile messageFile;
  final int index;
  final isPrevious;

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

  final downloadProgress = 0.0.obs;

  final isDownloaded = false.obs;

  bool get isDownloading => downloadProgress > 0 && downloadProgress < 1.0;

  CancelToken? _cancelToken;

  String? cacheUrl;

  Future<File?> downloadToLocal() async {
    _cancelToken = CancelToken();
    var _pathStr = await cacheMediaMgr.downloadMedia(
      widget.messageFile.url,
      savePath: downloadMgr.getSavePath(widget.messageFile.file_name),
      timeoutSeconds: 3000,
      onReceiveProgress: (int received, int total) {
        downloadProgress.value = received / total;
      },
      cancelToken: _cancelToken,
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

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
    checkFileDownload();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageFile.forward_user_id;
    }
  }

  void checkFileDownload() {
    cacheUrl = cacheMediaMgr.checkLocalFile(widget.messageFile.url);
    if (cacheUrl != null && cacheUrl!.isNotEmpty) {
      isDownloaded.value = true;
    } else {
      final messageContent = jsonDecode(widget.message.content);
      if (messageContent['size'] <= 5 * 1024 * 1024) {
        downloadToLocal();
      } else {
        isDownloaded.value = false;
      }
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

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);

    super.dispose();
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

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
                      DesktopGeneralDialog(
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
                        bubbleType: BubbleType.receiverBubble,
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
          child: GroupReplyItem(
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
          child: ChatSourceView(
              forward_user_id: widget.messageFile.forward_user_id,
              maxWidth: jxDimension.groupTextMeMaxWidth(),
              isSender: true),
        );
      }

      Widget bottomWidget = const SizedBox();
      if (widget.messageFile.caption.isNotEmpty) {
        bottomWidget = Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 5, bottom: 5),
          child: Material(
            color: Colors.transparent,
            child: RichText(
              text: TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    '${widget.messageFile.caption}             \u202F',
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
                    textColor: JXColors.chatBubbleSenderTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      Widget body = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            /// 昵称
            if (isFirstMessage || isPinnedOpen)
              Offstage(
                offstage: widget.chat.isSingle ||
                    widget.chat.typ == chatTypeSystem ||
                    widget.chat.typ == chatTypeSmallSecretary,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: NicknameText(
                    uid: sendID,
                    // color: accentColor,
                    isRandomColor: true,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                topWidget,

                /// 文件部分
                Padding(
                  padding:
                      (isFirstMessage || isPinnedOpen) && !widget.chat.isSingle
                          ? const EdgeInsets.only(top: 3.0)
                          : EdgeInsets.zero,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 文件Icon
                      buildFileIcon(),

                      /// 文件名称
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              showFileName(),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 17,
                                color: JXColors.chatBubbleFileSenderTitle,
                                decoration: TextDecoration.none,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${fileSize(widget.messageFile.length)}',
                              style: TextStyle(
                                color: JXColors.chatBubbleFileSenderSubTitle,
                                fontSize: 12,
                                height: 1,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomWidget,
              ],
            ),
          ],
        ),
      );

      body = GestureDetector(
        onTap: controller.chatController.popupEnabled ? null : msgOnTapped,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: body,
        ),
      );

      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      body = Container(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: ChatBubbleBody(
          position: position,
          verticalPadding: 6,
          horizontalPadding: 6,
          isPressed: isPressed.value,
          body: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                body,
                // if (isPressed.value)
                // Positioned.fill(
                //   child: Container(
                //     decoration: BoxDecoration(
                //       borderRadius: bubbleSideRadius(
                //         position,
                //         BubbleType.sendBubble,
                //       ),
                //       color: JXColors.outlineColor,
                //     ),
                //   ),
                // ),
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
                          eMargin: EmojiMargin.sender,
                        ),
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      );

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
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              Stack(
                children: [
                  body,
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: ChatReadNumView(
                      message: widget.message,
                      chat: widget.chat,
                      showPinned: controller.chatController.pinMessageList
                              .firstWhereOrNull((pinnedMsg) =>
                                  pinnedMsg.id == widget.message.id) !=
                          null,
                      sender: true,
                    ),
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
      return CustomAvatar(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        uid: sendID,
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
                  id: 1,
                );
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
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

  Widget buildFileIcon() {
    return Container(
      decoration: BoxDecoration(
          color: JXColors.chatBubbleFileIconHolderColor,
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              shape: CircleBorder(),
              color: JXColors.chatBubbleFileSenderBgColor,
            ),
            child: SvgPicture.asset(
              isDownloading
                  ? "assets/svgs/close_icon.svg"
                  : isDownloaded.value
                      ? 'assets/svgs/file_icon.svg'
                      : 'assets/svgs/download_file_icon.svg',
              width: 16,
              height: 16,
              fit: BoxFit.fill,
              colorFilter: const ColorFilter.mode(
                JXColors.chatBubbleFileSenderIconColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          if (isDownloading)
            Positioned(
              top: 2,
              left: 2,
              right: 2,
              bottom: 2,
              child: CircularLoadingBarRotate(
                key: ValueKey(widget.message),
                value: downloadProgress.value,
              ),
              // child: CircularLoadingBar(
              //   value: downloadProgress.value,
              // ),
            ),
        ],
      ),
    );
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
        DesktopGeneralDialog(
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
            menuHeight: ChatPopMenuSheet.getMenuHeight(
                widget.message, widget.chat,
                extr: false),
          ),
        );
      } else {
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
        File? file;
        if (isDownloaded.value) {
          file = File(cacheUrl!);
        } else {
          downloadProgress.value = 0.05;
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
