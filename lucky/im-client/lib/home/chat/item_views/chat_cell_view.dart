import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_factory.dart';
import 'package:jxim_client/object/chat/chat.dart';

class ChatCellView<T> extends GetView<T> {
  final Chat chat;
  final Animation<double>? animation;
  final int index;

  @override
  final String tag;

  const ChatCellView({
    super.key,
    required this.tag,
    required this.chat,
    required this.index,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return ChatUIFactory.createComponent(
      chat: chat,
      tag: tag,
      index: index,
      animation: animation,
    );
  }
}
