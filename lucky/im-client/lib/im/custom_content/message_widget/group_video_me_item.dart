import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class GroupVideoMeItem extends StatefulWidget {
  const GroupVideoMeItem({
    Key? key,
    required this.controller,
    required this.messageVideo,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final ChatContentController controller;
  final MessageVideo messageVideo;
  final Chat chat;
  final Message message;
  final int index;
  final isPrevious;

  @override
  State<GroupVideoMeItem> createState() => _GroupVideoMeItemState();
}

class _GroupVideoMeItemState extends State<GroupVideoMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  double width = 0;
  double height = 0;
  late MessageVideo msgVideo;

  RxBool onThumbnailReady = false.obs;

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    msgVideo = widget.messageVideo;

    Size size = ChatHelp.getMediaRenderSize(
      widget.messageVideo.width,
      widget.messageVideo.height,
      caption: widget.messageVideo.caption,
    );

    width = jxDimension.videoSenderWidth(size).abs();
    height = jxDimension.videoSenderHeight(size).abs();

    checkExpiredMessage(widget.message);

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);
    widget.message.on(Message.eventAssetUpdate, updateAsset);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);
    // 预加载视频m3u8以及ts第一片
    if (widget.message.message_id != 0) {
      videoMgr.preloadVideo(msgVideo.url);
    }

    emojiUserList.value = widget.message.emojis;

    if (widget.message.showDoneIcon) {
      Future.delayed(const Duration(seconds: 2), () {
        widget.message.showDoneIcon = false;
        if (mounted) setState(() {});
      });
    }
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
    if (mounted) setState(() {});
  }

  void updateAsset(Object sender, Object type, Object? data) {
    if (widget.message == sender) {
      msgVideo = widget.message.decodeContent(cl: MessageVideo.creator);
      if (mounted) setState(() {});
    }
  }

  void onLoadCallback(CacheFile? f) async {
    Future.delayed(
        const Duration(milliseconds: 200), () => onThumbnailReady.value = true);
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

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
      if (widget.messageVideo.reply.isNotEmpty) {
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
        topBody = Container(
          padding: const EdgeInsets.all(bubbleInnerPadding),
          child: ChatSourceView(
            forward_user_id: widget.messageVideo.forward_user_id,
            maxWidth: width,
            isSender: false,
          ),
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageVideo.caption.isNotEmpty) {
        bottomBody = Padding(
          padding: const EdgeInsets.symmetric(
              vertical: bubbleInnerPadding, horizontal: 10),
          child: Material(
            color: Colors.transparent,
            child: Text.rich(
              TextSpan(
                children: [
                  ...BuildTextUtil.buildSpanList(
                    widget.message,
                    '${widget.messageVideo.caption}',
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

      Widget body = ChatBubbleBody(
        type: BubbleType.sendBubble,
        position: position,
        isClipped: true,
        isPressed: isPressed.value,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                topBody,
                buildVideoContent(context, position),
                bottomBody,
              ],
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: controller.chatController.pinMessageList
                        .firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
                    null,
                backgroundColor: widget.messageVideo.caption.isEmpty
                    ? JXColors.black48
                    : Colors.transparent,
                sender: false,
              ),
            ),
          ],
        ),
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
          width: width,
          child: AbsorbPointer(
            absorbing: controller.chatController.popupEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                body,

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
                      child: Container(
                        margin: EdgeInsets.only(bottom: 4),
                        child: EmojiListItem(
                          specialBgColor: true,
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: controller,
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
        color: isPressed.value ? JXColors.outlineColor : null,
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          buildAsset(),
          if (isPressed.value)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: videoBorderRadius,
                  color: JXColors.outlineColor,
                ),
              ),
            ),
          _buildStatus(),
          Positioned.fill(
            child: _buildProgress(),
          ),
        ],
      ),
    );
    return objectMgr.loginMgr.isDesktop
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
        child: widget.messageVideo.cover != '0'
            ? RemoteImage(
                key: ValueKey(
                    '${widget.message.message_id}_${widget.messageVideo.url}_${Config().messageMin}'),
                src: widget.messageVideo.cover,
                width: width.toDouble(),
                height: height.toDouble(),
                fit: BoxFit.cover,
              )
            : const SizedBox(),
      );
    }

    final coverPath = msgVideo.coverPath;
    final bool coverExist =
        coverPath.isNotEmpty && File(coverPath).existsSync();
    final bool assetEmpty = widget.message.asset == null ||
        (widget.message.asset is File && msgVideo.cover.startsWith('Image'));

    return Stack(
      children: <Widget>[
        if (notBlank(msgVideo.cover))
          RemoteImage(
            key: ValueKey(
                '${widget.message.message_id}_${msgVideo.cover}_${Config().messageMin}'),
            src: msgVideo.cover,
            width: width.toDouble(),
            height: height.toDouble(),
            mini: Config().messageMin,
            fit: BoxFit.cover,
            onLoadCallback: onLoadCallback,
          ),
        Obx(() {
          if (!onThumbnailReady.value) {
            if (!assetEmpty) {
              if (widget.message.asset is File) {
                return Image.file(
                  File(coverPath),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                );
              }

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
                  width: width.toDouble(),
                  height: height.toDouble(),
                  fit: BoxFit.cover,
                );
              }
            }

            if (coverPath.isNotEmpty && coverExist) {
              return Image.file(
                File(coverPath),
                width: width,
                height: height,
                fit: BoxFit.cover,
              );
            }
          }
          return SizedBox(
            width: width.toDouble(),
            height: height.toDouble(),
          );
        }),
      ],
    );
  }

  Widget _buildStatus() {
    final int uploadStatus = widget.message.uploadStatus;

    final String statusText;

    switch (uploadStatus) {
      case 1:
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
          color: JXColors.chatBubbleVideoMeStatusBgColor,
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            fontSize: 12,
            color: JXColors.chatBubbleVideoMeStatusTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final int uploadStatus = widget.message.uploadStatus;
    double progress = 0.0;

    switch (uploadStatus) {
      case 1:
        // progress = min(widget.message.uploadProgress * 0.4, 0.4);
        break;
      case 2:
        // progress = 0.45;
        break;
      case 3:
        // progress = 0.45 + min(widget.message.uploadProgress * 0.45, 0.45);
        progress = widget.message.uploadProgress;
        break;
      case 4:
        progress = 1.0;
        break;
      case 5:
        progress = 1.0;
        if (!widget.message.showDoneIcon) {
          widget.message.showDoneIcon = true;
          Future.delayed(const Duration(seconds: 1), () {
            widget.message.showDoneIcon = false;
            widget.message.uploadStatus = 0;
            if (mounted) setState(() {});
          });
        }
        break;
      default:
        progress = 0.0;
    }

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
                  ? SvgPicture.asset(
                      key: UniqueKey(),
                      'assets/svgs/video_play_icon.svg',
                      width: 40,
                      height: 40,
                    )
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
                          // CircularLoadingBarRotate(
                          //   key: ValueKey(widget.message),
                          //   value: progress == 0.0 ? 0.05 : progress,
                          // ),
                          CircularProgressIndicator(
                            key: ValueKey(widget.message),
                            value: progress,
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
