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
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class ChatContactMe extends StatefulWidget {
  const ChatContactMe({
    super.key,
    required this.chat,
    required this.message,
    required this.messageJoinGroup,
    required this.index,
    this.isPrevious = true,
  });

  final Chat chat;
  final Message message;
  final MessageJoinGroup messageJoinGroup;
  final int index;
  final bool isPrevious;

  @override
  State<ChatContactMe> createState() => _ChatContactMeState();
}

class _ChatContactMeState extends MessageWidgetMixin<ChatContactMe> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

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
                      controller.chatController.onCancelFocus();
                      isPressed.value = false;
                    },
                    onTapCancel: () {
                      isPressed.value = false;
                    },
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
                    child: childBody),
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

  bool get showForwardContent =>
      widget.messageJoinGroup.forward_user_id != 0 && !widget.chat.isSaveMsg;

  void onFriendCardTaped() async {
    final friendId = widget.chat.friend_id;
    final isClickCurChatUserCard = widget.messageJoinGroup.user_id == friendId;
    final user = objectMgr.userMgr.getUserById(widget.messageJoinGroup.user_id);
    assert(user != null);
    final relationship = user?.relationship ?? 0;
    if (relationship == Relationship.friend && !isClickCurChatUserCard) {
      final chat = await objectMgr.chatMgr
          .getChatByFriendId(user!.uid, remote: serversUriMgr.isKiWiConnected);
      assert(chat != null);
      if (objectMgr.loginMgr.isDesktop) {
        Routes.toChat(chat: chat!);
      } else {
        Routes.toChat(chat: chat!, popCurrent: true);
      }
    } else {
      Get.toNamed(
        RouteName.chatInfo,
        arguments: {
          'uid': widget.messageJoinGroup.user_id,
        },
        id: objectMgr.loginMgr.isDesktop ? 1 : null,
      );
    }
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: GestureDetector(
          onTap: onFriendCardTaped,
          child: Container(
            constraints: BoxConstraints(
              minWidth: !mounted
                  ? 0
                  : objectMgr.loginMgr.isDesktop
                      ? 201
                      : MediaQuery.of(context).size.width * 0.5,
              maxWidth: !mounted
                  ? 0
                  : objectMgr.loginMgr.isDesktop
                      ? 250
                      : MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showForwardContent)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: MessageForwardComponent(
                      forwardUserId: widget.messageJoinGroup.forward_user_id,
                      maxWidth: jxDimension.groupTextMeMaxWidth(),
                      isSender: false,
                    ),
                  ),
                const SizedBox(height: 4.0),
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
        constraints: BoxConstraints(
          maxWidth: jxDimension.groupTextMeMaxWidth(),
        ),
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
                  for (var emoji in emojiUserList) {
                    final emojiCountMap = {
                      emoji.emoji: emoji.uidList.length,
                    };
                    emojiCountList.add(emojiCountMap);
                  }

                  return Visibility(
                    visible: emojiUserList.isNotEmpty,
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

                if (emojiUserList.isEmpty) const SizedBox(height: 20.0),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            body,
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
                child: _buildState(context, widget.message),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildState(BuildContext context, Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (controller.chatController.popupEnabled || !mounted) {
          return;
        }
        _showEnableFloatingWindow(context);
      },
    );
  }

  Widget buildContactCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.hardEdge,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bubblePrimary.withOpacity(0.1),
          border: Border(
            left: BorderSide(
              color: bubblePrimary,
              width: 3.0,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                const SizedBox(width: 4),
                CustomAvatar.normal(
                  widget.messageJoinGroup.user_id,
                  size: jxDimension.contactCardAvatarSize(),
                  headMin: Config().headMin,
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
                        fontSize: 14,
                        fontWeight: MFontWeight.bold5.value,
                        color: bubblePrimary,
                      ),
                    ),
                    Text(
                      localized(chatCard),
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        fontWeight: MFontWeight.bold4.value,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              color: colorTextPrimary.withOpacity(0.2),
              thickness: 0.33,
              height: 1,
            ),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  localized(viewFriends),
                  style: TextStyle(
                    color: bubblePrimary,
                    fontSize: 14,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
