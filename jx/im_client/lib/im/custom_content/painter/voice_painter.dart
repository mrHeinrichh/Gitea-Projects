import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

enum VoicePainterStyle {
  none,
  display,
  radio,
}

class VoicePainter extends CustomPainter {
  final List<double> decibels;
  final Color? lineColor;
  final double? playedProgress;
  final Color? playColor;
  final double animate;
  final VoicePainterStyle style;

  VoicePainter({
    required this.decibels,
    this.lineColor,
    this.playedProgress,
    this.playColor,
    this.animate = 1.0,
    this.style = VoicePainterStyle.display,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenWidth = size.width;
    const decibelWidth = 4.0;
    const decibelStroke = 2.0;
    final numberOfDecibels = screenWidth ~/ decibelWidth;
    final decibelDiff = decibels.length > numberOfDecibels
        ? decibels.length - numberOfDecibels
        : 0;

    final int playedDecibel;
    if (playedProgress != null) {
      playedDecibel = (numberOfDecibels * playedProgress!).toInt();
    } else {
      playedDecibel = 0;
    }

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = decibelStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.save();

    canvas.translate(screenWidth, 0);

    double getDecibelHeight(double x, double y) {

      if(style == VoicePainterStyle.display){
        // Scale decibel value to a range between 2 and 16
        const minHeight = 2.0;
        const maxHeight = 28.0;
        final minDecibel = decibels.reduce((a, b) => a < b ? a : b);
        final maxDecibel = decibels.reduce((a, b) => a > b ? a : b);
        final ratio = (maxHeight - minHeight) / (maxDecibel - minDecibel);
        return (x - minDecibel) * min(0.3650, ratio) + minHeight;
      }

      // const ratio = 0.1825;
      const ratio = 0.3650;
      return (x * ratio) + y;
    }

    for (int i = decibels.length - 1; i >= decibelDiff; i--) {
      final decibel = decibels[i];

      double height = getDecibelHeight(decibel, 3);

      if (height > size.height) {
        height = size.height;
      }

      if(animate != 1.0){
        double cal = (animate - (i / decibels.length));
        height *= cal >= 0.985 ? 1.0 : cal <= 0.0? 0.1:cal;
      }

      if (i < playedDecibel) {
        paint.color = playColor ?? themeColor;
      } else if(i == playedDecibel && playedDecibel != 0) {
        paint.color = (playColor ?? themeColor).withOpacity(0.75);
      } else {
        paint.color = lineColor ?? colorTextSupporting;
      }

      if (i == decibelDiff - 1) {
        final padding = (size.height - height) / 2;
        canvas.drawPath(Path()..moveTo(0, padding)..lineTo(0, height + padding), paint);
        canvas.translate(-decibelWidth, 0);
        continue;
      }

      if (i == 0) {
        final padding = (size.height - height) / 2; //2 = center 1 = bottom
        canvas.drawLine(Offset(0, padding), Offset(0, height + padding), paint);
        canvas.translate(-decibelWidth, 0);
        continue;
      }

      final prevDecibel = decibels[i - 1];
      double prevHeight = getDecibelHeight(prevDecibel, 3);

      final heightDiff = prevHeight - height;

      if (heightDiff < -20) {
        height -= height / prevHeight;
      } else if (heightDiff > 20) {
        height += height / prevHeight;
      }

      final padding = (size.height - height) / 2; //2 = center 1 = bottom
      canvas.drawLine(Offset(0, padding), Offset(0, height + padding), paint);
      canvas.translate(-decibelWidth, 0);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
