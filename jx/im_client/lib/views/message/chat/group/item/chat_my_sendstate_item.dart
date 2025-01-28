import 'package:jxim_client/object/chat/message.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';

import 'package:jxim_client/utils/theme/color/color_code.dart';

class ChatMySendStateItem extends StatefulWidget {
  const ChatMySendStateItem({
    super.key,
    this.showLoading = true,
    required this.message,
    this.failMsgClick,
  });
  final bool showLoading;
  final Message message;
  final VoidCallback? failMsgClick;

  @override
  ChatMySendStateItemState createState() => ChatMySendStateItemState();
}

class ChatMySendStateItemState extends State<ChatMySendStateItem> {
  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      widget.failMsgClick?.call();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isSendOk) {
      return const SizedBox();
    }
    return EventsWidget(
      data: widget.message,
      eventTypes: const [Message.eventSendState],
      builder: (ctx) {
        if (widget.message.isSendFail) {
          return Container(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: _onRetry,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: 3.15,
                    child: const Icon(
                      Icons.info,
                      size: 24,
                      color: colorRed,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox(height: 0.0);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
