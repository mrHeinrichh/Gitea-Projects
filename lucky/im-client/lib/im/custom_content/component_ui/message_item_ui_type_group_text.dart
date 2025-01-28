import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:im/widget/group_text_widget.dart';
import 'package:jxim_client/object/chat/message_extension.dart';
import '../message_widget/message_widget_mixin.dart';
import 'message_item_ui_component.dart';

class MessageItemUITypeGroupText extends MessageItemUIComponent {
  MessageItemUITypeGroupText(
      {super.key,
      required super.message,
      required super.index,
      required super.tag}) {}

  @override
  Widget buildChild(BuildContext context) {
    String content = message.extractVipGroupContent();
    bool isFirstMsg = firstMessageShowFunc(controller.chatController, message);
    bool isLastMsg = lastMessageShowFunc(controller.chatController, message);
    return GroupTextWidget(
        key: ValueKey('chat_${message.create_time}_${message.id}'),
        type: message.typ,
        content: content,
        messageId: message.id,
        createTime: message.create_time,
        isFirstMsg: isFirstMsg,
        isLastMsg: isLastMsg,
        onCancelFocus: controller.chatController.onCancelFocus,
        tapAbleText: message.extractTapAbleText(),
        onTapText: () {
          message.onDetailTapEvent(context);
        });
  }
}
