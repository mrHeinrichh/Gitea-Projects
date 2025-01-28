import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/group_invite_link.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/join_invitation_bottom_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/toast.dart';
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

class ChatGroupLinkMe extends StatefulWidget {
  const ChatGroupLinkMe({
    super.key,
    required this.chat,
    required this.message,
    required this.messageGroupLink,
    required this.index,
    this.isPrevious = true,
  });

  final Chat chat;
  final Message message;
  final MessageGroupLink messageGroupLink;
  final int index;
  final bool isPrevious;

  @override
  State<ChatGroupLinkMe> createState() => _ChatGroupLinkMeState();
}

class _ChatGroupLinkMeState extends MessageWidgetMixin<ChatGroupLinkMe> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  late Widget childBody;

  String get pureShortLink =>
      ShareLinkUtil.extractLinkFromText(widget.messageGroupLink.short_link)
          .first;

  TextOverflow get textOverflow {
    if (RegExp(r'\n').hasMatch(widget.messageGroupLink.short_link)) {
      return TextOverflow.visible;
    }

    Iterable<RegExpMatch> matches =
        RegExp(r' ').allMatches(widget.messageGroupLink.short_link);
    if (matches.length >= 2) {
      return TextOverflow.visible;
    }
    return TextOverflow.ellipsis;
  }

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

  void onGroupLinkTaped() async {
    late int? groupId;
    late bool? isGroupSelf;
    final dataMap = ShareLinkUtil.collectDataFromUrl(pureShortLink);
    if (dataMap.isEmpty) return;
    groupId = dataMap['gid'];
    if (groupId == null) return;
    if (widget.chat.isGroup) {
      isGroupSelf = widget.messageGroupLink.group_id == widget.chat.id;
    } else {
      isGroupSelf = false;
    }
    final user = objectMgr.userMgr.getUserById(widget.messageGroupLink.user_id);
    assert(user != null, 'JoinGroup: User cannot be null!');
    if (!isGroupSelf) {
      bool isJoined = await objectMgr.myGroupMgr
          .isGroupMember(groupId, objectMgr.userMgr.mainUser.id);
      if (!isJoined) {
        final groupInfo = await getGroupInfoByLink(pureShortLink);
        if (groupInfo == null) {
          Toast.showToast(localized(invitaitonLinkHasExpired));
          return;
        }
        bool isFriend = true;
        final group = Group();
        group.uid = groupId;
        group.name = groupInfo.groupName ?? '';
        group.icon = groupInfo.groupIcon ?? '';
        final isConfirmed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return JoinInvitationBottomSheet(
              group: group,
              userName: groupInfo.userName ?? '',
              isFriend: isFriend,
            );
          },
        );
        if (isConfirmed == true) {
          await joinGroupByLink(groupId, pureShortLink);
        } else {
          return;
        }
      }
      final chat = await objectMgr.chatMgr
          .getChatByGroupId(groupId, remote: serversUriMgr.isKiWiConnected);
      if (chat == null) {
        Toast.showToast(localized(chatRoomNotReadyTryLater));
        return;
      }
      Routes.toChat(chat: chat);
    } else {
      Get.toNamed(
        RouteName.groupChatInfo,
        arguments: {'groupId': groupId},
        id: objectMgr.loginMgr.isDesktop ? 1 : null,
      );
    }
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: GestureDetector(
          onTap: onGroupLinkTaped,
          child: Container(
            constraints: BoxConstraints(
              minWidth: objectMgr.loginMgr.isDesktop
                  ? 206
                  : MediaQuery.of(context).size.width * 0.5,
              maxWidth: objectMgr.loginMgr.isDesktop
                  ? 221
                  : MediaQuery.of(context).size.width * 0.7,
            ),
            child: buildGroupLinkCard(),
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
        verticalPadding: 4,
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

  Widget buildGroupLinkCard() {
    return Container(
      constraints: const BoxConstraints(minWidth: 245),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.messageGroupLink.short_link,
            style: TextStyle(
              overflow: textOverflow,
              fontSize: 14,
              fontWeight: MFontWeight.bold4.value,
              color: const Color(0xFF1D49A7),
            ),
          ),
          ClipRRect(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Config().appName,
                    style: jxTextStyle.textStyleBold14(color: bubblePrimary),
                  ),
                  Text(
                    widget.messageGroupLink.group_name.length > 20
                        ? subUtf8String(
                              widget.messageGroupLink.group_name,
                              20,
                            ) +
                            '...'
                        : widget.messageGroupLink.group_name,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      fontWeight: MFontWeight.bold5.value,
                      color: colorTextPrimary,
                    ),
                  ),
                  Text(
                    '${widget.messageGroupLink.nick_name} ${localized(invitationLinkInviteGroup)}',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      fontWeight: MFontWeight.bold4.value,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Divider(
                    color: colorTextPrimary.withOpacity(0.2),
                    thickness: 0.33,
                    height: 1,
                  ),
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: Text(
                        // localized(viewGroup),
                        localized(invitationLinkCheckGroup),
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
