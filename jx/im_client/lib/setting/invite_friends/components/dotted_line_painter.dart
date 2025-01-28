import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class DottedLineWithSemicirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = colorSurface
      ..style = PaintingStyle.fill;

    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(backgroundRect, backgroundPaint);

    final paint = Paint()
      ..color = colorBackground
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 分割线
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    double startX = 15;
    while (startX < size.width - 15) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    final semicirclePaint = Paint()
      ..color = colorBackground
      ..style = PaintingStyle.fill;

    // 左右两边的圆圈
    final leftCircleCenter = Offset(0, size.height / 2);
    canvas.drawCircle(leftCircleCenter, 14, semicirclePaint);

    final rightCircleCenter = Offset(size.width, size.height / 2);
    canvas.drawCircle(rightCircleCenter, 14, semicirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
