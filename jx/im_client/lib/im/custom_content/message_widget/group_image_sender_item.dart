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

class GroupImageSenderItem extends StatefulWidget {
  const GroupImageSenderItem({
    super.key,
    required this.controller,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
  });

  final ChatContentController controller;
  final MessageImage messageImage;
  final Chat chat;
  final Message message;
  final int index;

  @override
  GroupImageSenderItemState createState() => GroupImageSenderItemState();
}

class GroupImageSenderItemState
    extends MessageWidgetMixin<GroupImageSenderItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();

  final isLongPress = false.obs;

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;

  //图片资源src
  Rx<Uint8List> gausPath = Uint8List(0).obs;
  RxString source = ''.obs;
  RxBool isThumbnailReady = false.obs;
  RxBool isDownloading = false.obs;
  RxDouble downloadPercentage = 0.0.obs;
  CancelToken thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();

    _preloadImageSync();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageImage.forward_user_id;
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

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  _preloadImageSync() {
    if (widget.messageImage.gausPath.isEmpty) {
      source.value = widget.messageImage.url;
    } else {
      if (widget.messageImage.gausPath.contains('Image/')) {
        source.value = widget.messageImage.gausPath;
      } else {
        source.value = imageMgr.getBlurHashSavePath(widget.messageImage.url);

        if (source.value.isNotEmpty && !File(source.value).existsSync()) {
          imageMgr.genBlurHashImage(
            widget.messageImage.gausPath,
            widget.messageImage.url,
          );
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      widget.messageImage.url,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      isThumbnailReady.value = true;
      source.value = widget.messageImage.url;
      gausPath.value = Uint8List(0);
      return;
    }

    gausPath.value = widget.messageImage.gausBytes ?? Uint8List(0);

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    isDownloading.value = true;
    final thumbPath = await downloadMgrV2.download(
      widget.messageImage.url,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
      onReceiveProgress: (count, total) {
        downloadPercentage.value = count / total;
      },
    );
    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      isThumbnailReady.value = true;
      gausPath.value = Uint8List(0);
      source.value = widget.messageImage.url;
    }

    isDownloading.value = false;
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  double get maxWidth => width.value;

  double get extraWidth => setWidth(isPinnedOpen, widget.message.edit_time > 0);

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
    if (widget.messageImage.caption.isNotEmpty) {
      _readType = caculateLastLineTextWidth(
        message: widget.message,
        messageText: widget.messageImage.caption,
        maxWidth: maxWidth - 26.w,
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
                    isPressed.value = false;
                    controller.chatController.onCancelFocus();
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
                        bubbleType: BubbleType.receiverBubble,
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
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  top: 0.0,
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
      final bool showPinned =
          widget.controller.chatController.pinMessageList.firstWhereOrNull(
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
              maxWidth: maxWidth,
              controller: controller,
            ),
          ),
        );
      }

      if (widget.messageImage.forward_user_id != 0 && !widget.chat.isSaveMsg) {
        topBody = Padding(
          padding: forwardTitlePadding,
          child: MessageForwardComponent(
            forwardUserId: widget.messageImage.forward_user_id,
            maxWidth: maxWidth,
            isSender: true,
          ),
        );
      }

      Widget bottomBody = const SizedBox();
      if (widget.messageImage.caption.isNotEmpty) {
        bottomBody = Container(
          padding: getTextSpanPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 文本
              if (showOriginalContent.value)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: bubbleInnerPadding,
                    vertical: 4.w,
                  ),
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
                        ),
                        if (_readType == GroupTextMessageReadType.inlineType)
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
                ),
              if (showTranslationContent.value)
                Container(
                  padding: EdgeInsets.only(
                      right: bubbleInnerPadding,
                      left: bubbleInnerPadding,
                      bottom: 4),
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
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ChatBubbleBody(
            position: position,
            isClipped: true,
            isPressed: isPressed.value,
            body: Stack(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 昵称
                    if (widget.messageImage.forward_user_id != 0 &&
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
                        onPressed: () {
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
                        child: getImage(position),
                      )
                    else
                      GestureDetector(
                        onTap: controller.chatController.popupEnabled
                            ? null
                            : () => controller.showLargePhoto(
                                  context,
                                  widget.message,
                                ),
                        child: getImage(position),
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
                    backgroundColor: widget.messageImage.caption.isEmpty
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
              if (!controller.chat!.isSystem)
                Opacity(
                  opacity: showAvatar ? 1 : 0,
                  child: buildAvatar(),
                ),

              Stack(
                children: <Widget>[
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
                            onTap: () => controller.onViewReactList(
                              context,
                              emojiUserList,
                            ),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              margin: EdgeInsets.only(
                                left: jxDimension.chatBubbleLeftMargin,
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
                  if (isPlayingSound.value || isWaitingRead.value)
                    MessageReadTextIcon(
                      isWaitingRead: isWaitingRead.value,
                      isMe: false,
                      right: 0,
                      isPause: isPauseRead.value,
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

  Widget getImage(BubblePosition position) {
    BorderRadius imageBorderRadius = BorderRadius.zero;
    if ((widget.messageImage.reply.isNotEmpty ||
            widget.messageImage.forward_user_id != 0) &&
        widget.messageImage.caption.isNotEmpty) {
      imageBorderRadius = BorderRadius.zero;
    } else if (widget.messageImage.forward_user_id != 0 ||
        widget.messageImage.reply.isNotEmpty) {
      imageBorderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(
          BubbleCorner.bottomLeftCorner(position, BubbleType.receiverBubble),
        ),
        bottomRight: Radius.circular(
          BubbleCorner.bottomRightCorner(
            position,
            BubbleType.receiverBubble,
          ),
        ),
      );
    } else if (widget.messageImage.caption.isNotEmpty) {
      imageBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(
          BubbleCorner.topLeftCorner(position, BubbleType.receiverBubble),
        ),
        topRight: Radius.circular(
          BubbleCorner.topRightCorner(position, BubbleType.receiverBubble),
        ),
      );
    } else {
      imageBorderRadius = bubbleSideRadius(position, BubbleType.receiverBubble);
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: isPressed.value ? colorTextPlaceholder : null,
            borderRadius: imageBorderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Obx(() {
            return RemoteImageV2(
              src: source.value,
              width: maxWidth,
              height: height.value,
              mini: source.value ==
                          imageMgr
                              .getBlurHashSavePath(widget.messageImage.url) ||
                      source.value == widget.messageImage.gausPath
                  ? null
                  : Config().messageMin,
              fit: BoxFit.cover,
              enableShimmer: true,
            );
          }),
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
                width: maxWidth,
                height: height.value,
                fit: BoxFit.cover,
              ),
            );
          }

          return const SizedBox();
        }),
        Obx(() {
          if (isDownloading.value) {
            return _buildProgress(context);
          }

          if (!isThumbnailReady.value && !isDownloading.value) {
            return _buildDownload(context);
          }

          return const SizedBox();
        }),
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
