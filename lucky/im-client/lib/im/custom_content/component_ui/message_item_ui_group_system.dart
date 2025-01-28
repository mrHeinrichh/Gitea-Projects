import 'package:flutter/src/widgets/framework.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_system_item.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageItemUIGroupSystem extends MessageItemUIComponent {
  MessageItemUIGroupSystem(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen, required super.tag});
  @override
  Widget buildChild(BuildContext context) {
    return GroupSystemItem(
      key: ValueKey('chat_${message.create_time}_${message.id}'),
      message: message,
      messageSystem: message.decodeContent(cl: MessageSystem.creator),
      chat: controller.chatController.chat,
      index: index,
      isPrevious: isPrevious,
    );
  }
}
