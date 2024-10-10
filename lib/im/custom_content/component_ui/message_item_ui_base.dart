import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/message.dart';

abstract class MessageItemUIBase<T> extends GetView<T> {
  final Message message;
  final int index;
  final bool isPrevious;
  final bool isPinOpen;
  @override
  final String tag;
  const MessageItemUIBase(
      {super.key,
      required this.message,
      required this.index,
      required this.isPrevious,
      required this.isPinOpen,
      required this.tag});
  Widget buildChild(BuildContext context);
}
