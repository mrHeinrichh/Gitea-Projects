import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/markdown_item.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIMarkdown extends MessageItemUIComponent {
  const MessageItemUIMarkdown({
    super.key,
    required super.message,
    required super.index,
    super.isPrevious,
    super.isPinOpen,
    required super.tag,
  });

  @override
  Widget buildChild(BuildContext context) {
    MessageMarkdown messageMarkdown =
        message.decodeContent(cl: MessageMarkdown.creator);
    return MarkdownItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      message: message,
      messageMarkdown: messageMarkdown,
      controller: controller,
      chat: controller.chatController.chat,
      index: index,
    );
  }
}
