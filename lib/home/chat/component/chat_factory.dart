import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/chat_ui_saved.dart';
import 'package:jxim_client/home/chat/component/chat_ui_single.dart';
import 'package:jxim_client/home/chat/component/chat_ui_small_secretary.dart';
import 'package:jxim_client/home/chat/component/chat_ui_system.dart';
import 'package:jxim_client/home/chat/component/chat_ui_component.dart';
import 'package:jxim_client/home/chat/component/desktop_chat_ui_component.dart';
import 'package:jxim_client/home/chat/component/desktop_chat_ui_special_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';

import 'package:jxim_client/object/chat/chat.dart';

class ChatUIFactory {
  static Widget createComponent({
    required Chat chat,
    required String tag,
    required int index,
    Animation<double>? animation,
  }) {
    if (objectMgr.loginMgr.isDesktop) {
      switch(chat.typ){
        case chatTypeSystem:
        case chatTypeSmallSecretary:
        case chatTypeSaved:
          return DesktopChatUISpecialComponent(
            chat: chat,
            index: index,
            animation: animation,
          );

        default:
          return DesktopChatUIComponent(
            chat: chat,
            index: index,
            animation: animation,
          );
      }
    }

    switch (chat.typ) {
      case chatTypeSystem:
        return ChatUISystem(
          chat: chat,
          index: index,
          animation: animation,
          tag: tag,
        );
      case chatTypeSmallSecretary:
        return ChatUISmallSecretary(
          chat: chat,
          index: index,
          animation: animation,
          tag: tag,
        );
      case chatTypeSaved:
        return ChatUISaved(
          chat: chat,
          index: index,
          animation: animation,
          tag: tag,
        );
      case chatTypeSingle:
        return ChatUiSingle(
          chat: chat,
          index: index,
          animation: animation,
          tag: tag,
        );
      default:
        return ChatUIComponent(
          chat: chat,
          index: index,
          animation: animation,
          tag: tag,
        );
    }
  }
}
