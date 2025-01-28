import 'package:flutter/material.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/color.dart';

class ChatSourceView extends StatelessWidget {
  final int forward_user_id;
  final double maxWidth;
  // final Color? textColor;
  final EdgeInsetsGeometry padding;
  final bool isSender;

  const ChatSourceView({
    Key? key,
    required this.forward_user_id,
    required this.maxWidth,
    // this.textColor,
    this.padding = EdgeInsets.zero,
    required this.isSender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          '${localized(forwarded)}',
          style: jxTextStyle.forwardBubbleTitleText(color: isSender ? JXColors.chatBubbleSenderForwardLabelColor : JXColors.chatBubbleMeForwardLabelColor),
        ),
      ),
    );
  }
}
