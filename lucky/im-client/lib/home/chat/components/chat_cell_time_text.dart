import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:get/get.dart';

class ChatCellTimeText extends StatefulWidget {
  final Chat chat;

  const ChatCellTimeText({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => ChatCellTimeTextState();
}

class ChatCellTimeTextState extends State<ChatCellTimeText> {
  int lastTime = 0;
  Message? lastMessage;

  ChatListController get controller => Get.find<ChatListController>();

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr
        .on(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMessageDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _onMessageEdit);
    objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _updateUnread);

    lastTime = widget.chat.create_time;
    if (!widget.chat.isDisband) {
      updateContent();
    }
  }

  updateContent() {
    lastMessage = objectMgr.chatMgr.getLatestMessage(widget.chat.id);
    if (lastMessage != null &&
        lastMessage!.chat_idx > widget.chat.hide_chat_msg_idx) {
      lastTime = lastMessage!.create_time;
    }else{
      lastTime = widget.chat.create_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      lastTime > 0
          ? FormatTime.chartTime(
              lastTime,
              true,
              todayShowTime: true,
              dateStyle: DateStyle.MMDDYYYY,
            )
          : '',
      style: jxTextStyle
          .textStyle14(
              color: controller.desktopSelectedChatID.value == widget.chat.id &&
                      objectMgr.loginMgr.isDesktop
                  ? JXColors.white
                  : JXColors.secondaryTextBlack)
          .useSystemChineseFont(),
    );
  }

  _onNewMessage(Object sender, Object type, Object? data) {
    if (data is Message &&
        data.chat_id == widget.chat.id &&
        !widget.chat.isDisband) {
      setState(() {
        updateContent();
      });
    }
  }

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message &&
        !widget.chat.isDisband &&
        data.chat_id == widget.chat.id) {
      if (widget.chat.msg_idx == data.chat_idx) {
        setState(() {
          updateContent();
        });
      }
    }
  }

  void _onLastMessageLoaded(sender, type, data) async {
    if (widget.chat.isDisband) return;

    if (objectMgr.chatMgr.lastChatMessageMap.containsKey(widget.chat.id)) {
      setState(() {
        updateContent();
      });
    }
  }

  void _onMessageDeleted(sender, type, data) async {
    if (data['id'] == widget.chat.id) {
      setState(() {
        updateContent();
      });
    }
  }

  void _onMessageEdit(sender, type, data) async {
    if (data['id'] == widget.chat.id) {
      setState(() {
        updateContent();
      });
    }
  }

  void _updateUnread(sender, type, data) async {
    if (data != null) {
      if (data['id'] == widget.chat.id) {
        Chat? chat = await objectMgr.chatMgr.getChatById(widget.chat.id);
        if (chat != null && !chat.isSaveMsg) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onMessageDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _onMessageEdit);
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _updateUnread);
  }
}
