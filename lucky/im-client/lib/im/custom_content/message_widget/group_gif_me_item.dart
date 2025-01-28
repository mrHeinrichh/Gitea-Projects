import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_sticker_modal.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';

class GroupGifMeItem extends StatefulWidget {
  final MessageImage messageImage;
  final Message message;
  final Chat chat;
  final int index;
  final bool isPrevious;

  const GroupGifMeItem({
    Key? key,
    required this.messageImage,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);

  @override
  State<GroupGifMeItem> createState() => _GroupGifMeItemState();
}

class _GroupGifMeItemState extends State<GroupGifMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;
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
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

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

  @override
  void dispose() {
    super.dispose();

    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }

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
                  },
                  onTapUp: (_) {
                    controller.chatController.onCancelFocus();
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
                  },
                  child: ScaleEffect(child: child),
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
                        style: BubbleStyle.round,
                        type: BubbleType.sendBubble,
                        verticalPadding: bubbleInnerPadding,
                        horizontalPadding: 12,
                        body: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPressReply(
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
                      ),
                    isDesktop
                        ? GestureDetector(
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
                              } else {
                                DesktopGeneralDialog(
                                  context,
                                  widgetChild: DesktopStickerModal(
                                    messageImage: widget.messageImage,
                                  ),
                                );
                              }
                            },
                            child: _buildSticker(),
                          )
                        : ChatBubbleBody(
                            position: position,
                            type: BubbleType.sendBubble,
                            isClipped: true,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showForwardContent)
                                  ChatSourceView(
                                    forward_user_id:
                                        widget.messageImage.forward_user_id,
                                    maxWidth: jxDimension.groupTextMeMaxWidth(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    isSender: false,
                                  ),
                                Stack(
                                  children: [
                                    _buildSticker(),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: const ShapeDecoration(
                                          shape: StadiumBorder(),
                                          color: JXColors.black48,
                                        ),
                                        child: Text(
                                          'GIF',
                                          style: jxTextStyle.textStyle10(
                                              color: JXColors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned: controller.chatController.pinMessageList
                          .firstWhereOrNull((pinnedMsg) =>
                              pinnedMsg.id == widget.message.id) !=
                      null,
                  backgroundColor: JXColors.black48,
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
              children: [
                if (!widget.message.isSendOk)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          widget.chat.typ == chatTypeSmallSecretary ? 0.0 : 20,
                      right: 4,
                    ),
                    child: _buildState(widget.message),
                  ),
                Column(
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
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSticker() {
    return Container(
      constraints: BoxConstraints(maxWidth: 300.w),
      child: RemoteImage(
        src: widget.messageImage.url,
        width: null,
        height: null,
        fit: BoxFit.fitHeight,
        shouldAnimate: true,
      ),
    );
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(key: Key(time.toString()), message: msg);
  }
}
