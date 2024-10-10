import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';

class EmojiAnimation extends StatefulWidget {
  final String imagePath;
  final Duration duration;
  final bool animate; // 新增一个布尔值来控制动画的启动

  const EmojiAnimation({
    super.key,
    required this.imagePath,
    this.duration = const Duration(milliseconds: 800),
    this.animate = true, // 先全部默認啟動動畫
  });

  @override
  EmojiAnimationState createState() => EmojiAnimationState();
}

class EmojiAnimationState extends State<EmojiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double minSize = 0.1; // 最小尺寸
  double maxSize = 1; // 最大尺寸
  double endSize = 0.8; // 結束時尺寸

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      // 根据传入的布尔值来决定是否启动动画
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );

      _animation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: minSize, end: maxSize)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 0.6,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: maxSize, end: endSize)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1.4,
        ),
      ]).animate(_controller);

      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      // 如果启动了动画，则在 dispose 中进行清理
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      // 如果不启动动画，直接返回图片小部件
      return SizedBox(
        height: 26,
        width: 26,
        child: FittedBox(
          child: Text(
            textAlign: TextAlign.center,
            widget.imagePath,
            style: TextStyle(
              fontSize: 17,
              // fontFamily: 'emoji',
              height: ImLineHeight.getLineHeight(fontSize: 17, lineHeight: 25),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 26,
      height: 26,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: SizedBox(
              height: 26,
              width: 26,
              child: FittedBox(
                child: Text(
                  textAlign: TextAlign.center,
                  widget.imagePath,
                  style: TextStyle(
                    fontSize: 22,
                    // fontFamily: 'emoji',
                    height: ImLineHeight.getLineHeight(
                        fontSize: 22, lineHeight: 25),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
