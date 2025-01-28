import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupStickerMeItem extends StatefulWidget {
  final MessageImage messageImage;
  final Message message;
  final Chat chat;
  final int index;
  final bool isPrevious;

  const GroupStickerMeItem({
    super.key,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  });

  @override
  State<GroupStickerMeItem> createState() => _GroupStickerMeItemState();
}

class _GroupStickerMeItemState extends MessageWidgetMixin<GroupStickerMeItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  late Widget childBody;

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

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    childBody = messageBody(context);

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
                      _showEnableFloatingWindow(context);
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
                              widget.message, widget.chat,
                              extr: false),
                        ),
                      );
                    }
                  },
                  child: childBody,
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

  void _showEnableFloatingWindow(BuildContext context) {
    enableFloatingWindow(
      context,
      widget.chat.id,
      widget.message,
      childBody,
      targetWidgetKey,
      tapPosition,
      ChatPopMenuSheet(
        message: widget.message,
        chat: widget.chat,
        sendID: widget.message.send_id,
      ),
      bubbleType: BubbleType.sendBubble,
      menuHeight: ChatPopMenuUtil.getMenuHeight(widget.message, widget.chat),
      topWidget: EmojiSelector(
        chat: widget.chat,
        message: widget.message,
        emojiMapList: emojiUserList,
      ),
    );
  }

  bool get showAvatar =>
      isLastMessage || controller.chatController.popupEnabled;

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

        Widget body = Container(
          margin: showForwardContent
              ? null
              : const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(bubbleBorderRadius),
          ),
          child: Stack(
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (showReplyContent)
                      ChatBubbleBody(
                        position: position,
                        type: BubbleType.sendBubble,
                        verticalPadding: chatBubbleBodyVerticalPadding,
                        horizontalPadding: chatBubbleBodyHorizontalPadding,
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
                            maxWidth: jxDimension.groupTextMeMaxWidth(),
                            controller: controller,
                          ),
                        ),
                      ),
                    isDesktop
                        ? _buildSticker()
                        : showForwardContent
                            ? ChatBubbleBody(
                                position: position,
                                type: BubbleType.sendBubble,
                                horizontalPadding: 12,
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
                                            jxDimension.groupTextMeMaxWidth(),
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        isSender: false,
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
                  showPinned: controller.chatController.pinMessageList
                          .firstWhereOrNull((pinnedMsg) =>
                              pinnedMsg.id == widget.message.id) !=
                      null,
                  backgroundColor: showForwardContent
                      ? Colors.transparent
                      : colorTextSecondary,
                  sender: false,
                ),
              ),
            ],
          ),
        );

        return Container(
          margin: EdgeInsets.only(
            top: jxDimension.chatBubbleTopMargin(position),
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: jxDimension.chatBubbleBottomMargin(position),
          ),
          alignment: Alignment.centerRight,
          child: AbsorbPointer(
            absorbing: controller.chatController.popupEnabled,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                              context, emojiUserList),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4.w),
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
                if (!widget.message.isSendOk)
                  Padding(
                    padding: EdgeInsets.only(
                      left: objectMgr.loginMgr.isDesktop
                          ? 5
                          : !message.isSendFail
                              ? 0
                              : 5.w,
                      bottom: 1,
                    ),
                    child: _buildState(widget.message),
                  ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (controller.chatController.popupEnabled) {
          return;
        }
        _showEnableFloatingWindow(context);
      },
    );
  }
}
