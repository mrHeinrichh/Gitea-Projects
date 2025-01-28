import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';

class MoreChooseView extends StatefulWidget {
  const MoreChooseView({
    super.key,
    required this.chatController,
    required this.message,
    required this.chat,
  });

  final Message message;
  final Chat chat;
  final BaseChatController chatController;

  @override
  MoreChooseViewState createState() => MoreChooseViewState();
}

class MoreChooseViewState extends State<MoreChooseView> {
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
                  ? Colors.black
                      .withOpacity(objectMgr.loginMgr.isDesktop ? 0.06 : 0.12)
                  : Colors.transparent,
              padding: const EdgeInsets.only(left: 8),
              alignment: Alignment.centerLeft,
              child: CheckTickItem(
                isCheck: widget.chatController.chooseMessage.containsKey(
                    widget.message.message_id == 0
                        ? widget.message.send_time
                        : widget.message.message_id),
                circlePaddingValue: objectMgr.loginMgr.isDesktop ? 2 : 4,
                borderColor: widget.message.isDisableMultiSelect
                    ? colorWhite.withOpacity(0.2)
                    : colorWhite,
                circleSize: objectMgr.loginMgr.isDesktop ? 16.0 : 20.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
