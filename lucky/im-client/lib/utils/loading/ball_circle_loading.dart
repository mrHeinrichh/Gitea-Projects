import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BallCircleLoading extends StatefulWidget {
  const BallCircleLoading(
      {Key? key,
      this.radius = 24,
      required this.ballStyle,
      this.count = 11,
      this.duration = const Duration(milliseconds: 1000),
      this.curve = Curves.linear})
      : super(key: key);
  final double radius;
  final BallStyle ballStyle;
  final Duration duration;
  final Curve curve;
  final int count;

  @override
  _BallCircleLoadingState createState() => _BallCircleLoadingState();
}

class _BallCircleLoadingState extends State<BallCircleLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = _controller.drive(CurveTween(curve: widget.curve));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: _CircleFlow(widget.radius),
      children: List.generate(widget.count, (index) {
        return Center(
          child: ScaleTransition(
            scale: DelayTween(begin: 0.0, end: 1.0, delay: index * .1)
                .animate(_animation),
            child: Ball(
                style: kDefaultBallStyle.copyWith(
                    size: widget.ballStyle.size,
                    color: widget.ballStyle.color,
                    ballType: widget.ballStyle.ballType,
                    borderWidth: widget.ballStyle.borderWidth,
                    borderColor: widget.ballStyle.borderColor)),
          ),
        );
      }),
    );
  }
}

///
/// desc:
///
class DelayTween extends Tween<double> {
  final double delay;

  DelayTween({required double begin, required double end, required this.delay})
      : super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}

class _CircleFlow extends FlowDelegate {
  final double radius;

  _CircleFlow(this.radius);

  @override
  void paintChildren(FlowPaintingContext context) {
    double x = 0; //开始(0,0)在父组件的中心
    double y = 0;
    for (int i = 0; i < context.childCount; i++) {
      x = radius *
          math.cos(i * 2 * math.pi / (context.childCount - 1)); //根据数学得出坐标
      y = radius *
          math.sin(i * 2 * math.pi / (context.childCount - 1)); //根据数学得出坐标
      context.paintChild(i, transform: Matrix4.translationValues(x, y, 0));
    }
  }

  @override
  bool shouldRepaint(FlowDelegate oldDelegate) => true;
}
