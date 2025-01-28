import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/message_factory.dart';

import '../../object/chat/message.dart';
import 'controllers/chat_list_controller.dart';

class MessageCellView extends GetView<ChatListController> {
  const MessageCellView({
    Key? key,
    required this.chatId,
    required this.message,
    this.searchText,
  }) : super(key: key);
  final int chatId;
  final Message message;
  final String? searchText;

  @override
  Widget build(BuildContext context) {
    return MessageFactory.createComponent(
        message: message, searchText: searchText, chatId: chatId);
  }
}
