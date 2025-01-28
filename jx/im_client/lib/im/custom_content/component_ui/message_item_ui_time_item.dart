import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/time_item.dart';

class MessageItemUITimeItem extends MessageItemUIComponent {
  const MessageItemUITimeItem(
      {super.key,
      required super.message,
      required super.index,
      super.isPrevious,
      super.isPinOpen,
      required super.tag});

  @override
  Widget buildChild(BuildContext context) {
    return TimeItem(
      createTime: message.create_time,
      showDay: true,
      controller: controller,
      message: message,
    );
  }
}
