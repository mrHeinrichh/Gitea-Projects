import 'package:flutter/cupertino.dart';

class NormalAnimation extends StatefulWidget {
  final Widget child;
  final bool reverse;
  final AnimationController controller;

  const NormalAnimation(
      {Key? key,
        required this.child,
        this.reverse = false,
        required this.controller})
      : super(key: key);

  @override
  NormalAnimationState createState() => NormalAnimationState();
}

class NormalAnimationState extends State<NormalAnimation>
    with SingleTickerProviderStateMixin {
  static final Tween<double> tweenOpacity = Tween<double>(begin: 0, end: 1);
  late Animation<double> animation;

  late Animation<double> animationOpacity;

  @override
  void initState() {
    animation =
        CurvedAnimation(parent: widget.controller, curve: Curves.decelerate);

    animationOpacity = tweenOpacity.animate(animation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, Widget? child) {
        // 将 Widget 的类型标记为可空的 Widget?
        return Opacity(
          opacity: animationOpacity.value,
          child: child ?? Container(),
        );
      },
      child: widget.child,
    );
  }
}
