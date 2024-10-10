import 'package:flutter/material.dart';
import 'dart:io';

import 'package:jxim_client/utils/theme/color/color_code.dart';

ChatWallPaper chatWallPaper = const ChatWallPaper();

bool isIphoneX = false;

bool isIPhoneX(BuildContext context) {
  if (Platform.isIOS) {
    return MediaQuery.of(context).padding.bottom > 0;
  }
  return false;
}

class ChatWallPaper extends StatefulWidget {
  const ChatWallPaper({super.key});

  @override
  ChatWallPaperState createState() => ChatWallPaperState();
}

class ChatWallPaperState extends State<ChatWallPaper>
    with TickerProviderStateMixin {
  final double _angle = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isIphoneX = isIPhoneX(context);

    if (screenW == 0) {
      final size = MediaQuery.of(context).size;
      screenW = size.width;
      screenH = size.height;
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          top: -(paperSize / 2 - screenH / 2),
          left: -(paperSize / 2 - screenW / 2),
          width: paperSize,
          height: paperSize,
          child: RotationTransition(
            turns: AlwaysStoppedAnimation(_angle / 360),
            child: const BlurredCircles(),
          ),
        ),
        Positioned(
          bottom: 0,
          width: screenW,
          height: screenH,
          child: Image(
            image: const AssetImage('assets/images/bg1.png'),
            fit: BoxFit.fill,
            width: screenW,
          ),
        ),
      ],
    );
  }
}

double screenW = 0;
double screenH = 0;
double paperSize = 1000;

class BlurredCircles extends StatelessWidget {
  const BlurredCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(paperSize, paperSize),
      painter: BlurredCirclesPainter(),
    );
  }
}

class BlurredCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    final rect =
        Rect.fromPoints(const Offset(0, 0), Offset(size.width, size.height));
    // 创建线性渐变
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [chatBgTopLeft, chatBgPrimary, chatBgBottomRight],
    );
    // 使用线性渐变填充
    paint.shader = gradient.createShader(rect);
    // 绘制矩形
    canvas.drawRect(rect, paint);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    double blurRadius = isIphoneX ? 50 : 100;

    // 颜色列表
    final colors = [
      chatBgTopLeft,
      chatBgBottomLeft,
      chatBgTopRight.withOpacity(Platform.isIOS ? 1.0 : 0.8),
      chatBgBottomRight,
    ];

    List<Offset> offsetList = [
      Offset(centerX + 200, centerY + 350),
      Offset(centerX - 100, centerY - 300),
      Offset(centerX + 200, centerY - 400),
      Offset(centerX - 300, centerY + 400),
    ];
    if (isIphoneX) {
      offsetList = [
        Offset(centerX + 200, centerY + 350),
        Offset(centerX - 100, centerY - 300),
        Offset(centerX + 200, centerY - 400),
        Offset(centerX - 250, centerY + 350),
      ];
    }

    final List<double> radiusList = [400, 300, 210, 250];

    drawForIndex(int index) {
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
      canvas.drawCircle(offsetList[index], radiusList[index], paint);
    }

    // drawForIndex(0);
    drawForIndex(3);
    // drawForIndex(1);
    drawForIndex(2);

    /* final radius = 5.0; // 设置点的半径
    paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 2; // 设置点的直径
    // 绘制红色点
    canvas.drawPoints(PointMode.points, [Offset(centerX, centerY)], paint);*/
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}