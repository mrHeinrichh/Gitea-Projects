

import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_mini_app_detail_sender_item.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupMiniApp extends MessageItemUIComponent {
  const MessageItemUIGroupMiniApp(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
       MessageMiniApp messageText = message.decodeContent(cl: MessageMiniApp.creator);
    return  GroupMiniAppDetailSenderItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      controller: controller,
      message: message,
      messageText: messageText,
      index: index,
      isPrevious: isPrevious,
      isPinOpen: isPinOpen,
    );
  }
}
