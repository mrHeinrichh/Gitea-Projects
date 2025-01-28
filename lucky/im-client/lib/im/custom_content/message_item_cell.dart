
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_factory.dart';
import 'package:jxim_client/object/chat/message.dart';

import 'chat_content_controller.dart';


class MessageItemCell extends GetView<ChatContentController> {
  final Message message;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;
  final String tag;

  const MessageItemCell({
    Key? key,
    required this.tag,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MessageItemFactory.createComponent(message: message, index: index,isPrevious:isPrevious,isPinOpen: isPinOpen,tag:tag);
  }

}
