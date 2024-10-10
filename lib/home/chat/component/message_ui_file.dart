// 文本消息模型

import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/utility.dart';

class MessageUIFile extends MessageUIComponent {
  MessageUIFile(
      {super.key,
      required super.chat,
      required super.searchText,
      required super.message});

  @override
  Widget getMessageThumbnail(Message message) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        height: 15,
        width: 15,
        child: Image.asset(
          fileIconNameWithSuffix(
            message
                .decodeContent(cl: MessageImage.creator())
                .suffix
                .split('.')
                .join(),
          ),
        ),
      ),
    );
  }

   @override
  String getMessageText(Message message, {String? searchText = ''}) {
    return message.decodeContent(cl: MessageFile.creator).caption;
  }
}
