import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_factory.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemCell extends GetView<ChatContentController> {
  final Message message;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;
  @override
  final String tag;

  const MessageItemCell({
    super.key,
    required this.tag,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return MessageItemFactory.createComponent(
      message: message,
      index: index,
      isPrevious: isPrevious,
      isPinOpen: isPinOpen,
      tag: tag,
    );
  }
}
