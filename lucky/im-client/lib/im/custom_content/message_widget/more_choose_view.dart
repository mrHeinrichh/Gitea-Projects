import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:flutter/material.dart';

import '../../../views/component/check_tick_item.dart';

class MoreChooseView extends StatefulWidget {
  const MoreChooseView({
    Key? key,
    required this.chatController,
    required this.message,
    required this.chat,
  }) : super(key: key);
  final Message message;
  final Chat chat;
  final BaseChatController chatController;

  @override
  _MoreChooseViewState createState() => _MoreChooseViewState();
}

class _MoreChooseViewState extends State<MoreChooseView> {
  _onChooseMessage() {
    widget.chatController.onChooseMessage(context, widget.message);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return Visibility(
          visible: widget.chatController.chooseMore.value,
          child: GestureDetector(
            onTap: _onChooseMessage,
            child: Container(
                color: widget.chatController.chooseMessage.containsKey(
                        widget.message.message_id == 0
                            ? widget.message.send_time
                            : widget.message.message_id)
                    ? Colors.black.withOpacity(0.12)
                    : Colors.transparent,
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.centerLeft,
                child: CheckTickItem(
                  isCheck:  widget.chatController.chooseMessage.containsKey(
                      widget.message.message_id == 0
                          ? widget.message.send_time
                          : widget.message.message_id),
                ),
            ),
          ),
        );
      },
    );
  }
}
