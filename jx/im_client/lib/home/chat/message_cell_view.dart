import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/message_factory.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageCellView<T> extends GetView<T> {
  final int chatId;
  final Message message;
  final String? searchText;
  final bool? isListMode;
  final Function() onClick;

  const MessageCellView({
    super.key,
    required this.chatId,
    required this.message,
    this.searchText,
    this.isListMode,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onClick(),
      child: MessageFactory.createComponent(
        message: message,
        searchText: searchText,
        chatId: chatId,
        isListMode: isListMode,
      ),
    );
  }
}
