import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/desktop_chat_ui_component.dart';
import 'package:jxim_client/home/chat/component/desktop_chat_ui_special_component.dart';
import 'package:jxim_client/home/chat/component_v2/chat_item.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';

class ChatUIFactory {
  static Widget createComponent({
    required Chat chat,
    required String tag,
    required int index,
    Animation<double>? animation,
    required ChatListController controller,
  }) {
    if (objectMgr.loginMgr.isDesktop) {
      switch (chat.typ) {
        case chatTypeSystem:
        case chatTypeSmallSecretary:
        case chatTypeSaved:
          return DesktopChatUISpecialComponent(chat: chat, index: index);

        default:
          return DesktopChatUIComponent(chat: chat, index: index);
      }
    }

    return Obx(
      () => ChatItem(
        chat: chat,
        isSearching: controller.isSearching.value,
        isSelected: controller.selectedChatIDForEdit.contains(chat.id),
        isEditing: controller.isEditing.value,
      ),
    );
  }
}
