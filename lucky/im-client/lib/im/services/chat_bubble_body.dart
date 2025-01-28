import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'chat_bubble_painter.dart';

enum BubbleStyle {
  round,
  tail,
}

class ChatBubbleBody extends StatelessWidget {
  final BubbleType type;
  final BubbleStyle style;
  final BubblePosition position;
  final double verticalPadding;
  final double horizontalPadding;
  final bool isClipped;
  final Widget body;
  final bool isPressed;
  final bool isHighlight;
  final BoxConstraints? constraints;

  const ChatBubbleBody({
    super.key,
    this.type = BubbleType.receiverBubble,
    this.style = BubbleStyle.tail,
    required this.position,
    this.verticalPadding = 1,
    this.horizontalPadding = 1,
    this.isClipped = false,
    required this.body,
    this.isPressed = false,
    this.isHighlight = false,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding = EdgeInsets.symmetric(
      vertical: verticalPadding,
      horizontal: horizontalPadding,
    );

    Widget content;
    if (style == BubbleStyle.tail) {
      content = RepaintBoundary(
        child: CustomPaint(
          painter: ChatBubblePainter(
            type,
            position: position,
            isPressed: isPressed,
            isHighlight: isHighlight,
          ),
          child: Padding(
            padding: padding,
            child: ClipRRect(
              clipBehavior: isClipped ? Clip.hardEdge : Clip.none,
              borderRadius: bubbleSideRadius(position, type),
              child: body,
            ),
          ),
        ),
      );
    } else {
      content = roundBubbleDecoration(
        position: position,
        type: type,
        padding: padding,
        isClipped: isClipped,
        child: body,
        isPressed: isPressed,
        isHighlight: isHighlight,
      );
    }

    return Container(
      margin: EdgeInsets.only(
        top: jxDimension.chatBubbleTopMargin(position),
        bottom: jxDimension.chatBubbleBottomMargin(position),
      ),
      constraints: constraints,
      child: content,
    );
  }
}
