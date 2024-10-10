import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';

abstract class MessageUIBase<T> extends GetView<T>  {
  final Chat chat;
  final Message message;
  final String? searchText;
  const MessageUIBase(
      {super.key, required this.chat, required this.searchText, required this.message});
      Widget createItemView(BuildContext context, int index);
      Widget buildHeadView(BuildContext context);
      Widget titleBuilder() ;
      Widget contentBuilder();
      Widget messageCellTime(Message message);
      Widget getMessageThumbnail(Message message) ;
      String getMessageText(Message message, {String? searchText = ''});
}
