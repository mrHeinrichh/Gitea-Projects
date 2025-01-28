import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';

abstract class MessageUIBase<T> extends GetView<T> {
  final Chat chat;
  final Message message;
  final String? searchText;

  const MessageUIBase({
    super.key,
    required this.chat,
    required this.message,
    required this.searchText,
  });

  Widget createItemView(BuildContext context);

  Widget buildHeadView(BuildContext context);

  Widget buildNameView(BuildContext context);

  Widget buildTimeView(BuildContext context);

  Widget buildContentView(BuildContext context);
}
