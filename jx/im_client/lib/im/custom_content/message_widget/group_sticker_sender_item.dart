import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_reply_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupStickerSenderItem extends StatefulWidget {
  final MessageImage messageImage;
  final Chat chat;
  final Message message;
  final int index;
  final bool isPrevious;

  const GroupStickerSenderItem({
    super.key,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  });

  @override
  GroupStickerSenderItemState createState() => GroupStickerSenderItemState();
}

class GroupStickerSenderItemState
    extends MessageWidgetMixin<GroupStickerSenderItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
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

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    super.dispose();
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

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

  bool get showReplyContent => widget.messageImage.reply.isNotEmpty;

  bool get showForwardContent =>
      widget.messageImage.forward_user_id != 0 && !widget.chat.isSaveMsg;

  Widget messageBody(BuildContext context) {
    return Obx(
      () {
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
        Widget body = Container(
          padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(bubbleBorderRadius),
          ),
          margin: showForwardContent
              ? null
              : const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            children: <Widget>[
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showReplyContent &&
                        widget.messageImage.reply.contains('id'))
                      ChatBubbleBody(
                        position: position,
                        verticalPadding: chatBubbleBodyVerticalPadding,
                        horizontalPadding: chatBubbleBodyHorizontalPadding,
                        constraints: BoxConstraints(
                          maxWidth: jxDimension.groupTextSenderMaxWidth(
                                  hasAvatar: true) -
                              jxDimension.chatRoomAvatarSize(),
                        ),
                        isPressed: isPressed.value,
                        body: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPressReply(
                            controller.chatController,
                            widget.message,
                          ),
                          child: MessageReplyComponent(
                            replyModel: ReplyModel.fromJson(
                              json.decode(widget.messageImage.reply),
                            ),
                            message: widget.message,
                            chat: widget.chat,
                            maxWidth: jxDimension.groupTextSenderMaxWidth(
                                hasAvatar: true),
                            controller: controller,
                          ),
                        ),
                      ),
                    isDesktop
                        ? _buildSticker()
                        : showForwardContent
                            ? ChatBubbleBody(
                                position: position,
                                horizontalPadding:
                                    chatBubbleBodyHorizontalPadding,
                                body: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 3,
                                    bottom: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MessageForwardComponent(
                                        forwardUserId:
                                            widget.messageImage.forward_user_id,
                                        maxWidth:
                                            jxDimension.groupTextSenderMaxWidth(
                                                hasAvatar: true),
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        isSender: true,
                                      ),
                                      _buildSticker(),
                                    ],
                                  ),
                                ),
                              )
                            : _buildSticker(),
                  ],
                ),
              ),
              Positioned(
                right: showForwardContent ? 12 : 0,
                bottom: showForwardContent ? 6 : 0,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned:
                      controller.chatController.pinMessageList.firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id,
                          ) !=
                          null,
                  backgroundColor: showForwardContent
                      ? Colors.transparent
                      : colorTextSecondary,
                  sender: true,
                ),
              ),
            ],
          ),
        );

        return Container(
          margin: EdgeInsets.only(
            top: jxDimension.chatBubbleTopMargin(position),
            right: jxDimension.chatRoomSideMarginMaxGap,
            left: controller.chatController.chooseMore.value
                ? 40
                : (widget.chat.typ == chatTypeSingle
                    ? jxDimension.chatRoomSideMarginSingle
                    : jxDimension.chatRoomSideMargin),
            bottom: jxDimension.chatBubbleBottomMargin(position),
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
                            margin: EdgeInsets.only(
                              left: jxDimension.chatBubbleLeftMargin,
                              bottom: 4,
                            ),
                            child: EmojiListItem(
                              specialBgColor: true,
                              emojiModelList: emojiUserList,
                              message: widget.message,
                              controller: controller,
                              maxWidth: jxDimension.groupTextSenderMaxWidth(
                                      hasAvatar: true) -
                                  jxDimension.chatRoomAvatarSize(),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildSticker() {
    return RemoteImage(
      src: widget.messageImage.url,
      width: 120,
      height: 120,
      fit: BoxFit.fitHeight,
      shouldAnimate: true,
    );
  }
}
