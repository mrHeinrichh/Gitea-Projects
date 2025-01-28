import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class ChatContactMe extends StatefulWidget {
  const ChatContactMe({
    Key? key,
    required this.chat,
    required this.message,
    required this.messageJoinGroup,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final Chat chat;
  final Message message;
  final MessageJoinGroup messageJoinGroup;
  final int index;
  final isPrevious;

  @override
  State<ChatContactMe> createState() => _ChatContactMeState();
}

class _ChatContactMeState extends State<ChatContactMe> with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

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
                    },
                    child: child),
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

  bool get showForwardContent =>
      widget.messageJoinGroup.forward_user_id != 0 && !widget.chat.isSaveMsg;

  Widget messageBody(BuildContext context) {
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: GestureDetector(
          onTap: () async => Get.toNamed(RouteName.chatInfo,
              arguments: {
                'uid': widget.messageJoinGroup.user_id,
              },
              id: objectMgr.loginMgr.isDesktop ? 1 : null),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(bubbleBorderRadius),
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width *
                  (objectMgr.loginMgr.isDesktop ? 0.3 : 0.5),
              maxWidth: MediaQuery.of(context).size.width *
                  (objectMgr.loginMgr.isDesktop ? 0.3 : 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showForwardContent)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ChatSourceView(
                      forward_user_id: widget.messageJoinGroup.forward_user_id,
                      maxWidth: jxDimension.groupTextMeMaxWidth(),
                      isSender: false,
                    ),
                  ),
                buildContactCard(),
              ],
            ),
          ),
        ),
      );

      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      body = ChatBubbleBody(
        position: position,
        verticalPadding: 8,
        horizontalPadding: 12,
        type: BubbleType.sendBubble,
        isPressed: isPressed.value,
        body: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                      child: EmojiListItem(
                        emojiModelList: emojiUserList,
                        message: widget.message,
                        controller: controller,
                        eMargin: EmojiMargin.sender,
                        isSender: true,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20.0),
              ],
            ),
            Positioned(
              right: 0.0,
              bottom: 0.0,
              child: ChatReadNumView(
                message: widget.message,
                chat: widget.chat,
                showPinned: controller.chatController.pinMessageList
                        .firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
                    null,
                sender: false,
              ),
            ),
          ],
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.message.isSendOk) _buildState(widget.message),
            body,
          ],
        ),
      );
    });
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(key: Key(time.toString()), message: msg);
  }

  Widget buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: JXColors.chatBubbleContactSenderBg,
      ),
      child: Row(
        children: <Widget>[
          CustomAvatar(
            uid: widget.messageJoinGroup.user_id,
            size: jxDimension.contactCardAvatarSize(),
            isGroup: false,
            onTap: () async => Get.toNamed(
              RouteName.chatInfo,
              arguments: {
                "uid": widget.messageJoinGroup.user_id,
              },
              id: objectMgr.loginMgr.isDesktop ? 1 : null,
            ),
          ),
          const SizedBox(width: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.messageJoinGroup.nick_name.length > 10
                    ? subUtf8String(
                        widget.messageJoinGroup.nick_name,
                        10,
                      )
                    : widget.messageJoinGroup.nick_name,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: 17,
                  fontWeight: MFontWeight.bold4.value,
                  color: JXColors.chatBubbleMeTextColor,
                ),
              ),
              Text(
                localized(chatCard),
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: 12,
                  fontWeight: MFontWeight.bold4.value,
                  color: JXColors.chatBubbleMeTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
