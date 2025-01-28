import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';

abstract class ChatUIBase<T> extends GetView<T> {
  // 消息对象
  final Chat chat;
  final int index;
  final Animation<double>? animation;

  @override
  final String tag;

  const ChatUIBase({
    required this.chat,
    required this.index,
    required this.animation,
    required this.tag,
    super.key,
  });

  ActionPane createStartActionPane(BuildContext context);

  List<Widget> createEndActionChildren(BuildContext context);

  ActionPane createEndActionPane(BuildContext context);

  Widget createItemView(BuildContext context, int index);

  Widget buildHeadView(BuildContext context);

  Widget buildNameView(BuildContext context);

  Widget buildTimeView(BuildContext context);

  Widget buildContentView(BuildContext context);

  Widget buildUnreadView(BuildContext context);
}
