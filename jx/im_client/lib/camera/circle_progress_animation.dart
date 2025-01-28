import 'package:flutter/material.dart';

class CircleProgressAnimation extends StatefulWidget {
  final Duration duration;
  final CircleProgressAnimationController controller;

  const CircleProgressAnimation({
    super.key,
    required this.duration,
    required this.controller,
  });

  @override
  CircleProgressAnimationState createState() => CircleProgressAnimationState();
}

class CircleProgressAnimationState extends State<CircleProgressAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    widget.controller._controller =
        _controller; // Assign controller to external controller

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: CircularProgressIndicator(
        value: _animation.value,
        strokeWidth: 5,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
}

class CircleProgressAnimationController {
  late AnimationController _controller;

  void start() {
    _controller.forward(from: 0.0);
  }

  void reset() {
    _controller.reset();
  }
}
