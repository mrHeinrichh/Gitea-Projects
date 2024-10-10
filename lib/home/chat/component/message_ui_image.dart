// 文本消息模型

import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class MessageUIImage extends MessageUIComponent {
  MessageUIImage(
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
        child: RemoteImage(
          src: message.decodeContent(cl: MessageImage.creator()).url,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  @override
  String getMessageText(Message message, {String? searchText = ''}) {
    return message.decodeContent(cl: MessageImage.creator).caption;
  }
}
