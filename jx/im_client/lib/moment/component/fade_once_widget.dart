import 'package:flutter/material.dart';

class FadeOnceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeOnceWidget(
      {super.key,
      required this.child,
      this.duration = const Duration(seconds: 1)});

  @override
  _FadeOnceWidgetState createState() => _FadeOnceWidgetState();
}

class _FadeOnceWidgetState extends State<FadeOnceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward().then((_) {
      _controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (_controller.isAnimating) _controller.dispose();
    super.dispose();
  }
}
