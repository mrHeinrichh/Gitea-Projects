import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TimeItem extends StatefulWidget {
  final int createTime;
  final bool showDay;
  final ChatContentController? controller;
  final Message? message;

  const TimeItem({
    super.key,
    required this.createTime,
    required this.showDay,
    this.controller,
    this.message,
  });

  @override
  State<TimeItem> createState() => _TimeItemState();
}

class _TimeItemState extends State<TimeItem> {
  @override
  void initState() {
    super.initState();

    if (widget.message != null) {
      objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onChatMessageDelete);
    }
  }

  @override
  void dispose() {
    if (widget.message != null) {
      objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onChatMessageDelete);
    }

    super.dispose();
  }

  void _onChatMessageDelete(_, __, Object? data) {
    if (widget.message == null || data is! Map) return;
    if (data['id'] != widget.message!.chat_id) return;

    if (data['message'] != null && data['message'] is List) {
      for (final msg in data['message']) {
        int id = -1;

        if (msg is Message) {
          id = msg.id;
        } else {
          id = msg;
        }

        if (id == widget.message!.message_id) {
          widget.controller!.chatController.removeMessage(widget.message!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: jxDimension.systemMessageMargin(context),
        padding: jxDimension.systemMessagePadding(),
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          color: colorTextSupporting,
        ),
        child: Text(
          FormatTime.chartTime(
            widget.createTime,
            widget.showDay,
            dateStyle: DateStyle.YYYYMMDD,
          ),
          style: jxTextStyle.normalSmallText(color: colorBrightPrimary),
        ),
      ),
    );
  }
}
