import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';

class ConvertTextItem extends StatelessWidget {
  final String convertText;
  final bool? isConverting;
  final double minWidth;
  final EdgeInsets margin;
  final isSender;

  const ConvertTextItem({
    Key? key,
    required this.convertText,
    this.isConverting,
    required this.minWidth,
    required this.margin,
    required this.isSender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: notBlank(convertText) || isConverting == true,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        alignment: Alignment.centerLeft,
        constraints: BoxConstraints(
          maxWidth: minWidth,
          minWidth: minWidth,
        ),
        decoration: BoxDecoration(
          color: isSender
              ? JXColors.chatBubbleMeTranslateBgColor
              : JXColors.chatBubbleSenderTranslateBgColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: isConverting == true
            ? SizedBox(
                height: 20,
                width: 20,
                child: DotLoadingView(
                  size: 8,
                  dotColor: isSender
                      ? JXColors.chatBubbleMeTextColor
                      : JXColors.chatBubbleSenderTextColor,
                ),
              )
            : Text(
                convertText,
                style: jxTextStyle.textStyle16(
                  color: isSender
                      ? JXColors.chatBubbleMeTextColor
                      : JXColors.chatBubbleSenderTextColor,
                ),
              ),
      ),
    );
  }
}
