import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/new_album_util.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/new_album_grid.dart';

class NewAlbumSenderItem extends StatefulWidget {
  const NewAlbumSenderItem({
    Key? key,
    required this.messageMedia,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final NewMessageMedia messageMedia;
  final Chat chat;
  final Message message;
  final int index;
  final isPrevious;

  @override
  State<NewAlbumSenderItem> createState() => _NewAlbumSenderItemState();
}

class _NewAlbumSenderItemState extends State<NewAlbumSenderItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  double get maxWidthRatio => widget.chat.isGroup ? 0.7 : 0.8;
  int sendID = 0;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageMedia.forward_user_id;
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

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

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

  Widget messageBody() {
    return Obx(() {
      /// 消息内容
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

      Widget body = AnimatedContainer(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        duration: const Duration(milliseconds: 100),
        constraints: BoxConstraints(
          maxWidth: isDesktop
              ? ((ObjectMgr.screenMQ!.size.width - 320) * maxWidthRatio)
              : ObjectMgr.screenMQ!.size.width * maxWidthRatio,
        ),
        child: ChatBubbleBody(
          position: position,
          isClipped: true,
          isPressed: isPressed.value,
          body: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.messageMedia.forward_user_id != 0 &&
                      !widget.chat.isSaveMsg)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10.0,
                        top: bubbleInnerPadding,
                        bottom: bubbleInnerPadding,
                      ),
                      child: ChatSourceView(
                          forward_user_id: widget.messageMedia.forward_user_id,
                          maxWidth: jxDimension.groupTextMeMaxWidth(),
                          isSender: true),
                    ),
                  if (widget.messageMedia.forward_user_id != 0 &&
                      !widget.chat.isSaveMsg)
                    const SizedBox(height: 5),
                  Stack(
                    children: <Widget>[
                      NewAlbumGridView(
                        assetMessage: widget.message,
                        messageMedia: widget.messageMedia,
                        onShowAlbum: (int index) {
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
                            controller.showLargePhoto(
                              context,
                              widget.message,
                              albumIdx: index,
                            );
                          }
                        },
                        isSender: true,
                        isForwardMessage:
                            widget.messageMedia.forward_user_id != 0 &&
                                !widget.chat.isSaveMsg,
                        isBorderRadius: true,
                      ),
                      if (isPressed.value)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: bubbleSideRadius(
                                position,
                                BubbleType.sendBubble,
                              ),
                              color: JXColors.outlineColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.messageMedia.caption.isNotEmpty)
                    Container(
                      width: isDesktop
                          ? NewAlbumUtil.getMaxWidth(
                              widget.messageMedia.albumList?.length ?? 0, 1)
                          : ObjectMgr.screenMQ!.size.width * maxWidthRatio,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(bubbleInnerPadding,
                            bubbleInnerPadding, bubbleInnerPadding, 15),
                        child: Material(
                          color: Colors.transparent,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                ...BuildTextUtil.buildSpanList(
                                  widget.message,
                                  '${widget.messageMedia.caption}             \u202F',
                                  launchLink:
                                      controller.chatController.popupEnabled
                                          ? null
                                          : onLinkOpen,
                                  onMentionTap:
                                      controller.chatController.popupEnabled
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
                                  textColor: JXColors.primaryTextBlack,
                                  isSender: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                bottom: objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned: controller.chatController.pinMessageList
                          .firstWhereOrNull((pinnedMsg) =>
                              pinnedMsg.id == widget.message.id) !=
                      null,
                  backgroundColor: widget.messageMedia.caption.isEmpty
                      ? JXColors.black48
                      : Colors.transparent,
                  sender: true,
                ),
              ),
            ],
          ),
        ),
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
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
          constraints: BoxConstraints(
            maxWidth: isDesktop
                ? ((ObjectMgr.screenMQ!.size.width - 320) * maxWidthRatio)
                : ObjectMgr.screenMQ!.size.width * maxWidthRatio + 48,
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          onTap: () => controller.onViewReactList(
                              context, emojiUserList),
                          child: Container(
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
                    })
                  ],
                ),
              ],
            ),
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
                Get.toNamed(RouteName.chatInfo,
                    arguments: {
                      "uid": sendID,
                    },
                    id: objectMgr.loginMgr.isDesktop ? 1 : null);
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
}
