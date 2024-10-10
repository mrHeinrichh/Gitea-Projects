import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

double getMessageLinkMaxWidth(String message, double maxWidth) {
  double measureFirstLineWidth(String text, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16.0),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final TextPosition endOfFirstLine =
        textPainter.getPositionForOffset(Offset(maxWidth, 0));
    final int endOfFirstLineOffset =
        textPainter.getOffsetBefore(endOfFirstLine.offset) ?? 0;

    final TextPainter firstLinePainter = TextPainter(
      text: TextSpan(
        text: text.substring(0, endOfFirstLineOffset),
        style: const TextStyle(fontSize: 16.0),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return firstLinePainter.size.width + 20.w;
  }

  return message.isURL ? measureFirstLineWidth(message, maxWidth) : maxWidth;
}
