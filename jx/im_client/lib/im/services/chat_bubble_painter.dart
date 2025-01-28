import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:tuple/tuple.dart';

enum BubbleType {
  /// Represents a sender's bubble displayed on the left side.
  sendBubble,

  /// Represents a receiver's bubble displayed on the right side.
  receiverBubble
}

enum BubblePosition {
  isFirstMessage,
  isMiddleMessage,
  isLastMessage,
  isFirstAndLastMessage,
}

class ChatBubblePainter extends CustomPainter {
  ///The values assigned to the clipper types [BubbleType.sendBubble] and
  ///[BubbleType.receiverBubble] are distinct.
  final BubbleType type;

  /// Check the bubble position to obtain the desire bubble radius for each cornor
  final BubblePosition position;

  /// The "nip" creates the curved shape of the chat widget
  /// and has a default nipHeight of 10.
  final double nipHeight;

  /// The "nip" creates the curved shape of the chat widget
  /// and has a default nipWidth of 15.
  final double nipWidth;

  /// The "nip" creates the curved shape of the chat widget
  /// and has a default nipRadius of 3.
  final double nipRadius;

  final bool isPressed;

  final bool isHighlight;

  final Color? bgColor;

  ChatBubblePainter(
    this.type, {
    this.position = BubblePosition.isFirstMessage,
    this.nipHeight = 16,
    this.nipWidth = 8,
    this.nipRadius = 3,
    this.isPressed = false,
    this.isHighlight = false,
    this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = bgColor != null
          ? bgColor!
          : type == BubbleType.sendBubble
              ? Color.alphaBlend(
                  isPressed ? colorTextPlaceholder : Colors.transparent,
                  bubbleSecondary,
                )
              : Color.alphaBlend(
                  isPressed ? colorTextPlaceholder : Colors.transparent,
                  colorWhite,
                )
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    double cavWidth = size.width;
    double cavHeight = size.height;
    double radiusW = nipWidth;
    double radiusH = nipHeight;
    double radius = nipRadius;

    // canvas.translate(8, 0.65);

    Path path = _drawRectBG(cavWidth, cavHeight);
    canvas.drawPath(path, paint);
    canvas.save();

    bool corner = BubbleCorner.cornerRadius(position, type).item5;
    if (corner) {
      Path path2 =
          _drawSpecialShape(cavWidth, cavHeight, radiusW, radiusH, radius);
      // paint.color = Colors.red;
      canvas.drawPath(path2, paint);
    }

    canvas.restore();
  }

  Path _drawSpecialShape(
    double cavWidth,
    double cavHeight,
    double radiusW,
    double radiusH,
    double radius,
  ) {
    Path path2 = Path();

    double rd = 16.0; //计算比例使用
    double rdd = 16.0; // 实际大小
    double offw = 4.0;

    double p1x = rdd * (4 / rd);
    double p1y = rdd * (0.0 / rd);

    double p2x = rdd * (4 / rd);
    double p2y = rdd * (8 / rd);

    double p3x = rdd * (3.0 / rd);
    double p3y = rdd * (12.0 / rd);

    double p4x = rdd * (0.0 / rd);
    double p4y = rdd * (rd / rd);

    double p5x = rdd * (15.0 / rd);
    double p5y = rdd * (15.0 / rd);

    double p6x = rdd * (16.0 / rd);
    double p6y = rdd * (0.0 / rd);

    if (type == BubbleType.sendBubble) {
      //1
      path2.moveTo(
        cavWidth - p1x + offw,
        cavHeight - rdd + p1y,
      );
      path2.lineTo(cavWidth - p2x + offw, cavHeight - rdd + p2y);

      //2
      path2.quadraticBezierTo(
        cavWidth - p3x + offw,
        cavHeight - rdd + p3y,
        cavWidth - p4x + offw,
        cavHeight - rdd + p4y,
      );

      // //3
      path2.quadraticBezierTo(
        cavWidth - p5x + offw,
        cavHeight - rdd + p5y,
        cavWidth - p6x + offw,
        cavHeight - rdd + p6y,
      );

      // path2.moveTo(cavWidth - radiusW, cavHeight - 10);
    } else {
      //1
      path2.moveTo(
        p1x - offw,
        cavHeight - rdd + p1y,
      );
      path2.lineTo(p2x - offw, cavHeight - rdd + p2y);

      //2
      path2.quadraticBezierTo(
        p3x - offw,
        cavHeight - rdd + p3y,
        p4x - offw,
        cavHeight - rdd + p4y,
      );

      // //3
      path2.quadraticBezierTo(
        p5x - offw,
        cavHeight - rdd + p5y,
        p6x - offw,
        cavHeight - rdd + p6y,
      );
    }

    path2.close();

    return path2;
  }

  Path _drawRectBG(
    double cavWidth,
    double cavHeight,
    // double radiusW,
    // double radiusH,
  ) {
    Path path = Path();

    //
    // double rTR = BubbleCorner.topRightCorner(position, type);
    // double rBR = BubbleCorner.bottomRightCorner(position, type);
    // double rBL = BubbleCorner.bottomLeftCorner(position, type);
    // double rTL = BubbleCorner.topLeftCorner(position, type);
    double rTL = BubbleCorner.cornerRadius(position, type).item1;
    double rTR = BubbleCorner.cornerRadius(position, type).item2;
    double rBL = BubbleCorner.cornerRadius(position, type).item3;
    double rBR = BubbleCorner.cornerRadius(position, type).item4;
    if (cavHeight == 38) {
      if (type == BubbleType.receiverBubble) {
        rTR = cavHeight * 0.5;
        rBR = cavHeight * 0.5;
      } else {
        rTL = cavHeight * 0.5;
        rBL = cavHeight * 0.5;
      }
    }

    //1
    path.moveTo(cavWidth - rTR, 0);
    path.lineTo(cavWidth - rTR, 0);
    path.arcToPoint(
      Offset(cavWidth, rTR),
      radius: Radius.circular(rTR),
    );

    //2
    path.lineTo(cavWidth, cavHeight - rBR);
    path.arcToPoint(
      Offset(cavWidth - rBR, cavHeight),
      radius: Radius.circular(rBR),
    );

    //3
    path.lineTo(rBL, cavHeight);
    path.arcToPoint(
      Offset(0, cavHeight - rBL),
      radius: Radius.circular(rBL),
    );

    //4
    path.lineTo(0, rTL);
    path.arcToPoint(
      Offset(rTL, 0),
      radius: Radius.circular(rTL),
    );

    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.nipHeight != nipHeight ||
      oldDelegate.nipWidth != nipWidth ||
      oldDelegate.nipRadius != nipRadius ||
      oldDelegate.position != position ||
      oldDelegate.isPressed != isPressed;
}

class BubbleCorner {
  static const double angBig = 16.0;
  static const double angSmall = 8.0;

  // tl, tr, bl , br | corner
  static Tuple5<double, double, double, double, bool> cornerRadius(
    BubblePosition position,
    BubbleType type,
  ) {
    double tl = angBig;
    double tr = angBig;
    double bl = angBig;
    double br = angBig;

    bool corner = false;

    switch (position) {
      case BubblePosition.isFirstMessage:
        if (type == BubbleType.receiverBubble) {
          bl = angSmall;
        } else {
          br = angSmall;
        }
        break;
      case BubblePosition.isMiddleMessage:
        if (type == BubbleType.receiverBubble) {
          tl = angSmall;
          bl = angSmall;
        } else {
          tr = angSmall;
          br = angSmall;
        }
        break;
      case BubblePosition.isLastMessage:
        if (type == BubbleType.receiverBubble) {
          tl = angSmall;
        } else {
          tr = angSmall;
        }
        corner = true;
        break;
      case BubblePosition.isFirstAndLastMessage:
        corner = true;
        break;
    }

    return Tuple5(tl, tr, bl, br, corner);
  }

  static double topRightCorner(BubblePosition position, BubbleType type) {
    if (type == BubbleType.sendBubble) {
      if (position == BubblePosition.isFirstAndLastMessage ||
          position == BubblePosition.isFirstMessage) {
        return 16;
      } else {
        return 7;
      }
    }

    return 15;
  }

  static double bottomRightCorner(BubblePosition position, BubbleType type) {
    if (type == BubbleType.sendBubble) {
      if (position == BubblePosition.isFirstAndLastMessage ||
          position == BubblePosition.isLastMessage) {
        return objectMgr.loginMgr.isDesktop ? 16 : 16.w;
      } else {
        return 7;
      }
    }

    return 15;
  }

  static double topLeftCorner(BubblePosition position, BubbleType type) {
    if (type == BubbleType.receiverBubble) {
      if (position == BubblePosition.isFirstAndLastMessage ||
          position == BubblePosition.isFirstMessage) {
        return 15;
      } else {
        return 7;
      }
    }

    return 15;
  }

  static double bottomLeftCorner(BubblePosition position, BubbleType type) {
    if (type == BubbleType.receiverBubble) {
      if (position == BubblePosition.isFirstAndLastMessage ||
          position == BubblePosition.isLastMessage) {
        return 15;
      } else {
        return 7;
      }
    }

    return 15;
  }
}
