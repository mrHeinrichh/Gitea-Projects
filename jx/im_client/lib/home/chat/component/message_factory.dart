import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/home/chat/component/message_ui_list_mode.dart';
import 'package:jxim_client/home/chat/component/message_ui_saved.dart';
import 'package:jxim_client/home/chat/component/message_ui_small_secretary.dart';
import 'package:jxim_client/home/chat/component/message_ui_system.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageFactory {
  static Widget createComponent({
    required Message message,
    String? searchText,
    required int chatId,
    bool? isListMode,
  }) {
    Chat? chat = objectMgr.chatMgr.getChatById(chatId);
    if (chat == null) {
      return const SizedBox();
    }

    if (isListMode == true) {
      return MessageUIListMode(
        message: message,
        searchText: searchText,
        chat: chat,
      );
    }

    switch (chat.typ) {
      case chatTypeSystem:
        return MessageUISystem(
          message: message,
          searchText: searchText,
          chat: chat,
        );
      case chatTypeSmallSecretary:
        return MessageUISmallSecretary(
          message: message,
          searchText: searchText,
          chat: chat,
        );
      case chatTypeSaved:
        return MessageUISaved(
          message: message,
          searchText: searchText,
          chat: chat,
        );
      default:
        return MessageUIComponent(
          chat: chat,
          searchText: searchText,
          message: message,
        );
    }
  }
}
