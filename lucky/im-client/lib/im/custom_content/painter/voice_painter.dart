import 'package:flutter/material.dart';
import '../../../utils/color.dart';

class VoicePainter extends CustomPainter {
  final List<double> decibels;
  final Color? lineColor;
  final double? playedProgress;
  final Color? playColor;

  VoicePainter({
    required this.decibels,
    this.lineColor,
    this.playedProgress,
    this.playColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenWidth = size.width;
    final decibelWidth = 4.0;
    final numberOfDecibels = screenWidth ~/ decibelWidth;
    final decibelDiff = decibels.length > numberOfDecibels
        ? decibels.length - numberOfDecibels
        : 0;

    final playedDecibel;
    if (playedProgress != null) {
      playedDecibel = (numberOfDecibels * playedProgress!).toInt();
    } else {
      playedDecibel = 0;
    }

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = decibelWidth
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    canvas.save();

    canvas.translate(screenWidth, 0);

    double getDecibelHeight(double x, double y) {
      final ratio = 0.1825;
      return (x * ratio) + y;
    }

    for (int i = decibels.length - 1; i >= decibelDiff; i--) {
      final decibel = decibels[i];

      double height = getDecibelHeight(decibel, 3);

      if (height > size.height) {
        height = size.height;
      }

      if (i < playedDecibel) {
        paint.color = playColor ?? accentColor;
      } else {
        paint.color = lineColor ?? JXColors.iconPrimaryColor;
      }

      if (i == decibelDiff - 1) {
        final padding = (size.height - height) / 2;
        canvas.drawLine(Offset(0, padding), Offset(0, height + padding), paint);
        canvas.translate(-4, 0);
        continue;
      }

      if (i == 0) {
        final padding = (size.height - height) / 1; // 2
        canvas.drawLine(Offset(0, padding), Offset(0, height + padding), paint);
        canvas.translate(-4, 0);
        continue;
      }

      final prevDecibel = decibels[i - 1];
      double prevHeight = getDecibelHeight(prevDecibel, 3);

      final heightDiff = prevHeight - height;

      if (heightDiff < -20) {
        height -= height / 4;
      } else if (heightDiff > 20) {
        height += height / 4;
      }

      final padding = (size.height - height) / 1; // 2
      canvas.drawLine(Offset(0, padding), Offset(0, height + padding), paint);
      canvas.translate(-4, 0);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
