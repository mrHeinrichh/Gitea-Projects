import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';

class ChatBlackItem extends StatefulWidget {
  const ChatBlackItem({
    super.key,
    required this.msg,
    required this.index,
  });
  final int index;
  final String msg;

  @override
  ChatBlackItemState createState() => ChatBlackItemState();
}

class ChatBlackItemState extends State<ChatBlackItem> with MessageWidgetMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: jxDimension.chatBlackPadding(),
      alignment: Alignment.center,
      child: Text(
        widget.msg,
        style: jxTextStyle.chatBlackTextStyle(),
      ),
    );
  }
}
