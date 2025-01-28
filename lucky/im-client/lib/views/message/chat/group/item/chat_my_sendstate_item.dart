import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';

import 'package:jxim_client/utils/color.dart';

class ChatMySendStateItem extends StatefulWidget {
  const ChatMySendStateItem({
    Key? key,
    this.showLoading = true,
    required this.message,
  }) : super(key: key);
  final bool showLoading;
  final Message message;

  @override
  _ChatMySendStateItemState createState() => _ChatMySendStateItemState();
}

class _ChatMySendStateItemState extends State<ChatMySendStateItem> {
  _onRetry() {
    if (widget.message.message_id == 0 &&
        widget.message.sendState == MESSAGE_SEND_FAIL) {
      Get.find<ChatContentController>(tag: widget.message.chat_id.toString())
          .chatController
          .removeMessage(widget.message);
      objectMgr.chatMgr.mySendMgr.onResend(widget.message);
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
          return Center(
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
                    child: Icon(
                      Icons.info,
                      size: 24,
                      color: errorColor,
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
