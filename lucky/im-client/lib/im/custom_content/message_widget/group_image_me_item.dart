import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class GroupImageMeItem extends StatefulWidget {
  const GroupImageMeItem({
    Key? key,
    required this.controller,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final ChatContentController controller;
  final MessageImage messageImage;
  final Message message;
  final Chat chat;
  final int index;
  final isPrevious;

  @override
  State<GroupImageMeItem> createState() => _GroupImageMeItemState();
}

class _GroupImageMeItemState extends State<GroupImageMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  double width = 0;
  double height = 0;
  late MessageImage msgImg;

  RxBool onThumbnailReady = false.obs;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    Size size = ChatHelp.getMediaRenderSize(
      widget.messageImage.width,
      widget.messageImage.height,
      caption: widget.messageImage.caption,
    );
    width = jxDimension.senderImageWidth(size.width);
    height = jxDimension.senderImageHeight(size.height);

    msgImg = widget.messageImage;

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);
    widget.message.on(Message.eventAssetUpdate, updateAsset);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;

    if (widget.message.showDoneIcon) {
      Future.delayed(const Duration(seconds: 2), () {
        widget.message.showDoneIcon = false;
        if (mounted) setState(() {});
      });
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

  void refreshBubble(sender, type, data) async {
    if (data is Message && data.isSendOk) {
      widget.message.showDoneIcon = true;
      Future.delayed(const Duration(seconds: 2), () {
        widget.message.showDoneIcon = false;
        if (mounted) setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  void updateAsset(sender, type, data) {
    if (widget.message == sender) {
      msgImg = widget.message.decodeContent(cl: MessageImage.creator);
      if (mounted) setState(() {});
    }
  }

  void onLoadCallback(CacheFile? f) async {
    Future.delayed(
        const Duration(milliseconds: 200), () => onThumbnailReady.value = true);
  }

  @override
  void dispose() {
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);
    widget.message.off(Message.eventAssetUpdate, updateAsset);
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
    Widget child = messageBody(context);

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
                    }

                    isPressed.value = false;
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
      final bool showPinned = widget.controller.chatController.pinMessageList
              .firstWhereOrNull(
                  (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
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

      Widget topBody = const SizedBox();
      if (widget.messageImage.reply.isNotEmpty) {
        topBody = Padding(
          padding: const EdgeInsets.all(bubbleInnerPadding),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.chatController.popupEnabled
                ? null
                : () => onPressReply(
                      controller.chatController,
                      widget.message,
                    ),
            child: GroupReplyItem(
              replyModel: ReplyModel.fromJson(
                json.decode(widget.messageImage.reply),
              ),
              message: widget.message,
              chat: widget.chat,
              maxWidth: jxDimension.groupTextMeMaxWidth(),
              controller: controller,
            ),
          ),
        );
      }

      if (widget.messageImage.forward_user_id != 0) {
        topBody = Padding(
          padding: const EdgeInsets.all(bubbleInnerPadding),
          child: ChatSourceView(
            forward_user_id: widget.messageImage.forward_user_id,
            maxWidth: width,
            isSender: false,
          ),
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageImage.caption.isNotEmpty) {
        bottomBody = Container(
          width: width,
          padding: const EdgeInsets.symmetric(
              vertical: bubbleInnerPadding, horizontal: 10),
          child: Material(
            color: Colors.transparent,
            child: Text.rich(
              TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    '${widget.messageImage.caption}',
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
                  WidgetSpan(
                    child: SizedBox(width: showPinned ? 68 : 52),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      bottomBody = SizedBox(
        width: width,
        child: Stack(
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
              bottom: objectMgr.loginMgr.isDesktop ? 8 : 8.w,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: controller.chatController.pinMessageList
                        .firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
                    null,
                backgroundColor: widget.messageImage.caption.isEmpty
                    ? JXColors.black48
                    : Colors.transparent,
                sender: false,
              ),
            ),
          ],
        ),
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
                      onTap: controller.chatController.popupEnabled
                          ? null
                          : () => controller.onViewReactList(
                              context, emojiUserList),
                      child: Container(
                        margin: EdgeInsets.only(
                            bottom: objectMgr.loginMgr.isDesktop ? 4 : 4.w),
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
            BubbleCorner.bottomLeftCorner(position, BubbleType.sendBubble)),
        bottomRight: Radius.circular(
            BubbleCorner.bottomRightCorner(position, BubbleType.sendBubble)),
      );
    } else if (widget.messageImage.caption.isNotEmpty) {
      imageBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(
            BubbleCorner.topLeftCorner(position, BubbleType.sendBubble)),
        topRight: Radius.circular(
            BubbleCorner.topRightCorner(position, BubbleType.sendBubble)),
      );
    } else {
      imageBorderRadius = bubbleSideRadius(position, BubbleType.sendBubble);
    }

    final Widget imageChild = Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: imageBorderRadius,
            color: isPressed.value ? JXColors.outlineColor : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: buildAsset(),
        ),
        if (isPressed.value)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: imageBorderRadius,
                color: JXColors.outlineColor,
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
              } else
                controller.showLargePhoto(context, widget.message);
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

  Widget buildAsset() {
    final filePath = msgImg.filePath;
    final fileExist = File(filePath).existsSync();
    final bool assetEmpty = widget.message.asset == null;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (msgImg.url.isNotEmpty)
          RemoteImage(
            key: ValueKey(
                '${widget.message.message_id}_${msgImg.url}_${Config().messageMin}'),
            src: msgImg.url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            mini: Config().messageMin,
            onLoadCallback: onLoadCallback,
          ),
        Obx(() {
          if (!onThumbnailReady.value) {
            if (!assetEmpty) {
              if (widget.message.asset is AssetEntity) {
                return Image(
                  image: AssetEntityImageProvider(
                    widget.message.asset!,
                    isOriginal: false,
                    thumbnailSize: ThumbnailSize.square(
                      max(
                        Config().sMessageMin,
                        Config().maxOriImageMin,
                      ),
                    ),
                  ),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                );
              } else {
                return Image.file(
                  widget.message.asset as File,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                );
              }
            } else if (filePath.isNotEmpty && fileExist) {
              return Image.file(
                File(filePath),
                width: width,
                height: height,
                fit: BoxFit.cover,
              );
            }
          }

          return const SizedBox();
        }),
        Positioned.fill(child: _buildProgress()),
        Positioned.fill(
          child: AnimatedSwitcher(
            child: widget.message.showDoneIcon
                ? SvgPicture.asset(
                    key: UniqueKey(),
                    'assets/svgs/done_upload_icon.svg',
                    width: 40,
                    height: 40,
                  )
                : SizedBox(
                    key: UniqueKey(),
                  ),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            duration: const Duration(
              milliseconds: 500,
            ),
          ),
        ),
      ],
    );
  }

  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      controller.chatController.removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
    }
  }

  Widget _buildProgress() {
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
          : widget.message.showDoneIcon
              ? SvgPicture.asset(
                  key: UniqueKey(),
                  'assets/svgs/done_upload_icon.svg',
                  width: 40,
                  height: 40,
                )
              : widget.message.isSendOk
                  ? const SizedBox()
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: JXColors.secondaryTextBlack,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            key: ValueKey(widget.message),
                            value: widget.message.uploadProgress,
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          // CircularLoadingBarRotate(
                          //   key: ValueKey(widget.message),
                          //   value: widget.message.uploadProgress == 0.0
                          //       ? 0.05
                          //       : widget.message.uploadProgress,
                          // ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (widget.message.sendState !=
                                  MESSAGE_SEND_SUCCESS) {
                                widget.message.sendState = MESSAGE_SEND_FAIL;
                                widget.message.resetUploadStatus();
                                objectMgr.chatMgr.mySendMgr
                                    .updateLasMessage(widget.message);
                                objectMgr.chatMgr.saveMessage(widget.message);
                              }
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}
