import 'package:flutter/material.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/lang_util.dart';

class MessageForwardComponent extends StatelessWidget {
  final int forwardUserId;
  final double maxWidth;

  // final Color? textColor;
  final EdgeInsetsGeometry padding;
  final bool isSender;

  const MessageForwardComponent({
    super.key,
    required this.forwardUserId,
    required this.maxWidth,
    // this.textColor,
    this.padding = EdgeInsets.zero,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          localized(forwarded),
          style: jxTextStyle.forwardBubbleTitleText(
            color: isSender ? themeColor : bubblePrimary,
          ),
        ),
      ),
    );
  }
}
