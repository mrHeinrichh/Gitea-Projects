import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

void showReelToast({
  required String value,
  Color textColor = colorWhite,
  Color bgColor = colorTextSecondary,
}) {
  BotToast.showText(
    text: value,
    align: Alignment.topCenter.add(const Alignment(0, 0.2)),
    contentColor: bgColor,
    textStyle: jxTextStyle.textStyleBold17(color: textColor),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    borderRadius: BorderRadius.circular(100),
  );
}
