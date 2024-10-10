import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';


class CircularLoadingBarRotate extends StatefulWidget {
  const CircularLoadingBarRotate({
    super.key,
    required this.value,
  });

  final double value;

  @override
  State<CircularLoadingBarRotate> createState() =>
      _CircularLoadingBarRotateState();
}

class _CircularLoadingBarRotateState extends State<CircularLoadingBarRotate>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(animationController),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: widget.value),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, _) {
          if (value < 0.05) {
            value = 0.05;
          }

          return CircularProgressIndicator(
            key: widget.key,
            value: value,
            color: Colors.white,
            strokeWidth: 2,
          );
        },
      ),
    );
  }
}

class CircularLoadingBar extends StatefulWidget {
  const CircularLoadingBar({
    super.key,
    required this.value,
    this.color = colorWhite,
  });

  final double value;
  final Color color;

  @override
  State<CircularLoadingBar> createState() => _CircularLoadingBarState();
}

class _CircularLoadingBarState extends State<CircularLoadingBar> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: widget.value),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, _) {
        return CircularProgressIndicator(
          key: widget.key,
          value: value,
          color: widget.color,
          strokeWidth: 2,
        );
      },
    );
  }
}
