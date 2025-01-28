import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupVideoSenderItem extends StatefulWidget {
  const GroupVideoSenderItem({
    super.key,
    required this.controller,
    required this.messageVideo,
    required this.chat,
    required this.message,
    required this.index,
  });

  final ChatContentController controller;
  final MessageVideo messageVideo;
  final Message message;
  final Chat chat;
  final int index;

  @override
  GroupVideoSenderItemState createState() => GroupVideoSenderItemState();
}

class GroupVideoSenderItemState
    extends MessageWidgetMixin<GroupVideoSenderItem> {
  late ChatContentController controller;

  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  int sendID = 0;

  //图片资源src
  Rx<Uint8List> gausPath = Uint8List(0).obs;
  RxString source = ''.obs;
  RxBool isThumbnailReady = false.obs;
  RxBool isDownloading = false.obs;
  RxDouble downloadPercentage = 0.0.obs;
  CancelToken thumbCancelToken = CancelToken();

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

  double get maxWidth => width.value;

  get extraWidth =>
      setWidth(isPinnedOpen, widget.message.edit_time > 0, isMe: true);

  @override
  void dispose() {
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
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);
    // 预加载视频m3u8以及ts第一片
    _preloadVideo();

    emojiUserList.value = widget.message.emojis;
    getRealSendID();

    _preloadImageSync();
  }

  _preloadVideo() {
    if (widget.message.message_id != 0) {
      videoMgr.preloadVideo(
        widget.messageVideo.url,
        width: widget.messageVideo.width,
        height: widget.messageVideo.height,
      );
    }
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageVideo.forward_user_id;
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

  _preloadImageSync() {
    if (source.value.isEmpty) {
      if (widget.messageVideo.gausPath.isEmpty) {
        source.value = widget.messageVideo.cover;
      } else {
        if (widget.messageVideo.gausPath.contains('Image/')) {
          source.value = widget.messageVideo.gausPath;
        } else {
          source.value =
              imageMgr.getBlurHashSavePath(widget.messageVideo.cover);

          if (source.value.isNotEmpty && !File(source.value).existsSync()) {
            imageMgr.genBlurHashImage(
              widget.messageVideo.gausPath,
              widget.messageVideo.cover,
            );
          }
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      widget.messageVideo.cover,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      isThumbnailReady.value = true;
      source.value = widget.messageVideo.cover;
      gausPath.value = Uint8List(0);
      return;
    }

    gausPath.value = widget.messageVideo.gausBytes ?? Uint8List(0);

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    isDownloading.value = true;
    DownloadResult result = await downloadMgrV2.download(
      widget.messageVideo.cover,
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
      source.value = widget.messageVideo.cover;
    }

    isDownloading.value = false;
  }

  EdgeInsets getTextSpanPadding() {
    if (_readType == GroupTextMessageReadType.beakLineType) {
      return EdgeInsets.only(bottom: 12.w);
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
                        bubbleType: BubbleType.receiverBubble,
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
                  child: MoreChooseView(
                    chatController: controller.chatController,
                    message: widget.message,
                    chat: widget.chat,
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      ///消息内容
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
              maxWidth: width.value,
              controller: controller,
            ),
          ),
        );
      }

      if (widget.messageVideo.forward_user_id != 0 && !widget.chat.isSaveMsg) {
        topBody = MessageForwardComponent(
          padding: forwardTitlePadding,
          forwardUserId: widget.messageVideo.forward_user_id,
          maxWidth: width.value,
          isSender: true,
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageVideo.caption.isNotEmpty) {
        bottomBody = Container(
          padding: EdgeInsets.symmetric(
            horizontal: bubbleInnerPadding,
            vertical: 4.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 文本
              if (showOriginalContent.value)
                Container(
                  padding: getTextSpanPadding(),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      //horizontal: bubbleInnerPadding,
                      // vertical: 4.w,
                      ),
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

      Widget body = Container(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: Container(
          constraints: BoxConstraints(maxWidth: width.value),
          child: ChatBubbleBody(
            position: position,
            isClipped: true,
            isPressed: isPressed.value,
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 昵称
                    if (widget.messageVideo.forward_user_id != 0 &&
                        (isFirstMessage || isPinnedOpen) &&
                        !widget.chat.isSaveMsg)
                      Offstage(
                        offstage: widget.chat.isSingle ||
                            widget.chat.typ == chatTypeSystem ||
                            widget.chat.typ == chatTypeSmallSecretary,
                        child: Padding(
                          padding: BubblePadding.nickname,
                          child: NicknameText(
                            uid: sendID,
                            // color: themeColor,
                            isRandomColor: true,
                            fontWeight: MFontWeight.bold5.value,
                            fontSize: bubbleNicknameSize,
                            groupId:
                                widget.chat.isGroup ? widget.chat.id : null,
                          ),
                        ),
                      ),
                    topBody,
                    if (objectMgr.loginMgr.isDesktop)
                      DesktopGeneralButton(
                        horizontalPadding: 0,
                        onPressed: () async {
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
                            controller.showLargePhoto(context, widget.message);
                          }
                        },
                        child: getVideo(position),
                      )
                    else
                      GestureDetector(
                        onTap: controller.chatController.popupEnabled
                            ? null
                            : () => controller.showLargePhoto(
                                  context,
                                  widget.message,
                                ),
                        child: getVideo(position),
                      ),
                    bottomBody,
                  ],
                ),
                Positioned(
                  right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                  bottom: objectMgr.loginMgr.isDesktop ? 8 : 4.w,
                  child: ChatReadNumView(
                    message: widget.message,
                    chat: widget.chat,
                    showPinned: controller.chatController.pinMessageList
                            .firstWhereOrNull(
                          (pinnedMsg) => pinnedMsg.id == widget.message.id,
                        ) !=
                        null,
                    backgroundColor: widget.messageVideo.caption.isEmpty
                        ? colorTextSecondary
                        : Colors.transparent,
                    sender: true,
                  ),
                ),
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
              ? 40.w
              : (widget.chat.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginSingle
                  : jxDimension.chatRoomSideMargin),
          bottom: isPinnedOpen ? 4.w : 0,
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            onTap: controller.chatController.popupEnabled
                                ? null
                                : () => controller.onViewReactList(
                                      context,
                                      emojiUserList,
                                    ),
                            child: Container(
                              constraints:
                                  BoxConstraints(maxWidth: width.value),
                              margin: EdgeInsets.only(
                                left: jxDimension.chatBubbleLeftMargin,
                                bottom: 4.w,
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
                  if (isPlayingSound.value || isWaitingRead.value)
                    MessageReadTextIcon(
                      isWaitingRead: isWaitingRead.value,
                      isPause: isPauseRead.value,
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
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar.normal(
        sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () async {
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
                  controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget getVideo(BubblePosition position) {
    BorderRadius videoBorderRadius = BorderRadius.zero;
    if ((widget.messageVideo.reply.isNotEmpty ||
            widget.messageVideo.forward_user_id != 0) &&
        widget.messageVideo.caption.isNotEmpty) {
      videoBorderRadius = BorderRadius.zero;
    } else if (widget.messageVideo.forward_user_id != 0 ||
        widget.messageVideo.reply.isNotEmpty) {
      videoBorderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(
          BubbleCorner.bottomLeftCorner(
            position,
            BubbleType.receiverBubble,
          ),
        ),
        bottomRight: Radius.circular(
          BubbleCorner.bottomRightCorner(
            position,
            BubbleType.receiverBubble,
          ),
        ),
      );
    } else if (widget.messageVideo.caption.isNotEmpty) {
      videoBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(
          BubbleCorner.topLeftCorner(
            position,
            BubbleType.receiverBubble,
          ),
        ),
        topRight: Radius.circular(
          BubbleCorner.topRightCorner(
            position,
            BubbleType.receiverBubble,
          ),
        ),
      );
    } else {
      videoBorderRadius = bubbleSideRadius(position, BubbleType.receiverBubble);
    }

    return Stack(
      children: <Widget>[
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: videoBorderRadius,
            color: isPressed.value ? colorTextPlaceholder : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Obx(() {
                return RemoteImageV2(
                  src: source.value,
                  width: width.value,
                  height: height.value,
                  mini: source.value ==
                              imageMgr.getBlurHashSavePath(
                                  widget.messageVideo.cover) ||
                          source.value == widget.messageVideo.gausPath
                      ? null
                      : Config().messageMin,
                  fit: BoxFit.cover,
                  enableShimmer: false,
                );
              }),
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
              Obx(() {
                if (isDownloading.value) {
                  return _buildProgress(context);
                }

                if (widget.message.asset == null &&
                    !isThumbnailReady.value &&
                    !isDownloading.value) {
                  return _buildDownload(context);
                }

                return SvgPicture.asset(
                  'assets/svgs/video_play_icon.svg',
                  width: 40,
                  height: 40,
                );
              }),
              Positioned.fill(
                left: 5,
                top: 6,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorTextSecondary,
                    ),
                    child: Text(
                      formatVideoDuration(widget.messageVideo.second),
                      style: jxTextStyle.supportSmallText(
                        color: colorBrightPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPressed.value)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: videoBorderRadius,
                color: colorTextPlaceholder,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Container(
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
