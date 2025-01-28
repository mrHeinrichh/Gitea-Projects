import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
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
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';

class ChatFriendLinkMe extends StatefulWidget {
  const ChatFriendLinkMe({
    super.key,
    required this.chat,
    required this.message,
    required this.messageFriendLink,
    required this.index,
    this.isPrevious = true,
  });
  final Chat chat;
  final Message message;
  final MessageFriendLink messageFriendLink;
  final int index;
  final bool isPrevious;

  @override
  State<ChatFriendLinkMe> createState() => _ChatFriendLinkMeState();
}

class _ChatFriendLinkMeState extends MessageWidgetMixin<ChatFriendLinkMe> {
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

  void onFriendLinkTaped() async {
    final friendId = widget.chat.friend_id;
    final isFriendSelf = widget.messageFriendLink.user_id == friendId;
    final user =
        objectMgr.userMgr.getUserById(widget.messageFriendLink.user_id);
    assert(user != null, 'User cannot be null!');
    final relationship = user?.relationship;
    if (relationship == Relationship.friend && !isFriendSelf) {
      // 已是好友，则直接进入好友聊天
      final chat = await objectMgr.chatMgr
          .getChatByFriendId(user!.uid, remote: serversUriMgr.isKiWiConnected);
      assert(chat != null, 'Chat cannot be null!');
      Routes.toChat(chat: chat!);
    } else {
      Get.toNamed(
        RouteName.chatInfo,
        arguments: {
          'uid': user?.uid,
        },
        id: objectMgr.loginMgr.isDesktop ? 1 : null,
      );
    }
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: GestureDetector(
          onTap: onFriendLinkTaped,
          child: Container(
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
                buildFriendLinkCard(),
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
        verticalPadding: chatBubbleBodyVerticalPadding,
        horizontalPadding: chatBubbleBodyHorizontalPadding,
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
                child: _buildState(widget.message),
              ),
          ],
        ),
      );
    });
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

  Widget buildFriendLinkCard() {
    return SizedBox(
      width: 239.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.messageFriendLink.short_link,
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: 17,
              fontWeight: MFontWeight.bold4.value,
              color: const Color(0xFF1D49A7),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: Container(
              padding: const EdgeInsets.only(left: 8),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Config().appName,
                    style: jxTextStyle.textStyleBold14(color: bubblePrimary),
                  ),
                  Text(
                    widget.messageFriendLink.nick_name.length > 10
                        ? subUtf8String(
                            widget.messageFriendLink.nick_name,
                            10,
                          )
                        : widget.messageFriendLink.nick_name,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      fontWeight: MFontWeight.bold5.value,
                      color: colorTextPrimary,
                    ),
                  ),
                  // Text(
                  //   widget.messageFriendLink.user_profile,
                  //   style: TextStyle(
                  //     overflow: TextOverflow.ellipsis,
                  //     fontSize: 14,
                  //     fontWeight: MFontWeight.bold4.value,
                  //     color: const Color(0xFF000000),
                  //   ),
                  // ),
                  Text(
                    localized(hurryUpAddFiend),
                    style: jxTextStyle.textStyle14(),
                  ),
                  const SizedBox(height: 4),
                  Divider(
                    color: colorTextPrimary.withOpacity(0.2),
                    thickness: 0.33,
                    height: 1,
                  ),
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        localized(viewFriends),
                        style:
                            jxTextStyle.textStyleBold14(color: bubblePrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
