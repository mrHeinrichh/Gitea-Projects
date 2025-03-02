import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../controllers/chat_list_controller.dart';
import 'package:get/get.dart';

class ChatCellUnreadText extends StatefulWidget {
  final Chat chat;

  const ChatCellUnreadText({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => ChatCellUnreadTextState();
}

class ChatCellUnreadTextState extends State<ChatCellUnreadText> {
  int unreadCount = 0;
  bool isNewChat = false;

  Message? lastMessage;

  ChatListController get controller => Get.find<ChatListController>();

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventRejoined, _rejoined);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _updateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventUpdateUnread, _refresh);
    objectMgr.chatMgr.on(ChatMgr.eventChatDisband, _updateUnread);

    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _updateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _updateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _updateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _refresh);
    if (!widget.chat.isDisband) {
      unreadCount = widget.chat.unread_count;
      checkIsNewChat();
    }
  }

  checkIsNewChat({int? startIdx}) {
    if (widget.chat.isSaveMsg || widget.chat.typ == chatTypeSmallSecretary) {
      isNewChat = false;
    } else {
      isNewChat = isWithin24Hours(widget.chat.create_time * 1000) &&
          widget.chat.read_chat_msg_idx <= (startIdx ?? widget.chat.start_idx);
    }
  }

  bool isWithin24Hours(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo =
        now - (24 * 60 * 60 * 1000); // 24 hours in milliseconds

    return timestamp >= twentyFourHoursAgo;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chat.typ == chatTypePostNotify ||
        (widget.chat.isDisband && widget.chat.isGroup) ||
        unreadCount <= 0 && !isNewChat) {
      return widget.chat.sort == 0
          ? const SizedBox()
          : Container(
              margin: EdgeInsets.only(left: 8.w),
              constraints: const BoxConstraints(minWidth: 20, maxHeight: 24),
              child: SvgPicture.asset(
                'assets/svgs/chat_cell_pin_icon.svg',
                width: 20,
                height: 20,
                color:
                    controller.desktopSelectedChatID.value == widget.chat.id &&
                            objectMgr.loginMgr.isDesktop
                        ? JXColors.white
                        : JXColors.iconPrimaryColor,
                fit: BoxFit.fill,
              ),
            );
    }

    List<Widget> children = [];

    if (isNewChat) {
      children.add(Text(
        localized(homeNew),
        style: jxTextStyle.textStyleBold14(color: const Color(0xFFEB6A61)),
        textAlign: TextAlign.center,
      ));
    }

    if (objectMgr.chatMgr.mentionMessageMap[widget.chat.chat_id] != null &&
        objectMgr.chatMgr.mentionMessageMap[widget.chat.chat_id]!.length > 0) {
      children.add(
        Container(
          margin: EdgeInsets.only(left: objectMgr.loginMgr.isDesktop ? 10 : 8),
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: controller.desktopSelectedChatID.value == widget.chat.id &&
                    objectMgr.loginMgr.isDesktop
                ? JXColors.white
                : objectMgr.loginMgr.isDesktop
                    ? JXColors.desktopChatBlue
                    : accentColor,
            shape: const CircleBorder(),
          ),
          child: Text(
            "@",
            style: jxTextStyle.textStyle14(
              color: controller.desktopSelectedChatID.value == widget.chat.id &&
                      objectMgr.loginMgr.isDesktop
                  ? accentColor
                  : JXColors.cIconPrimaryColor,
            ),
          ),
        ),
      );
    }

    if (unreadCount != 0) {
      children.add(
        Container(
          height: 20,
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 20),
          decoration: BoxDecoration(
            color: controller.desktopSelectedChatID.value == widget.chat.id &&
                    objectMgr.loginMgr.isDesktop
                ? JXColors.white
                : widget.chat.isMute
                    ? JXColors.supportingTextBlack
                    : objectMgr.loginMgr.isDesktop
                        ? JXColors.desktopChatBlue
                        : accentColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: unreadCount < 999
                ? AnimatedFlipCounter(
                    value: unreadCount,
                    textStyle: jxTextStyle.textStyle13(
                        color: controller.desktopSelectedChatID.value ==
                                    widget.chat.id &&
                                objectMgr.loginMgr.isDesktop
                            ? accentColor
                            : JXColors.primaryTextWhite))
                : Text(
                    '999+',
                    style: jxTextStyle.textStyle14(
                        color: controller.desktopSelectedChatID.value ==
                                    widget.chat.id &&
                                objectMgr.loginMgr.isDesktop
                            ? accentColor
                            : JXColors.primaryTextWhite),
                  ),
          ),
        ),
      );
    }

    return Row(
      children: children,
    );
  }

  void _updateUnread(sender, type, data) async {
    if (data != null) {
      int chatId = -1;
      if (data is Message) {
        chatId = data.chat_id;
      } else if (data is Chat) {
        chatId = data.chat_id;
      } else {
        chatId = data['id'];
      }

      if (chatId == widget.chat.id && !widget.chat.isSaveMsg) {
        _updateUnreadCount();
      }
    }
  }

  void _refresh(sender, type, data) {
    if (data is Chat) {
      if (data.chat_id == widget.chat.chat_id) {
        Chat? chat = objectMgr.chatMgr.getChatById(data.chat_id);
        if (chat != null) {
          setState(() {
            unreadCount = chat.unread_count;
            if (isNewChat) checkIsNewChat();
          });
        }
      }
    }
  }

  void _rejoined(sender, type, data) {
    if (data is Chat) {
      if (data.chat_id == widget.chat.chat_id) {
        setState(() {
          checkIsNewChat(startIdx: data.start_idx);
        });
      }
    }
  }

  void _updateUnreadCount() {
    setState(() {
      if (isNewChat) {
        checkIsNewChat();
      }
      unreadCount = widget.chat.unread_count;
    });
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _updateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _updateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _updateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventChatDisband, _updateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _updateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventUpdateUnread, _refresh);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _refresh);
    objectMgr.chatMgr.off(ChatMgr.eventRejoined, _rejoined);
  }
}
