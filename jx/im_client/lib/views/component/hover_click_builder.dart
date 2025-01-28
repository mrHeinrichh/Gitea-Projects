import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class HoverClickBuilder extends StatefulWidget {
  const HoverClickBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(bool isHovered, bool isPressed) builder;

  @override
  State<HoverClickBuilder> createState() => _HoverClickBuilderState();
}

class _HoverClickBuilderState extends State<HoverClickBuilder> {
  bool _isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => _onHoverChanged(enabled: true),
      onExit: (PointerExitEvent event) => _onHoverChanged(enabled: false),
      child: Listener(
          onPointerDown: (_) => _onClick(click: true),
          onPointerUp: (_) => _onClick(click: false),
          onPointerCancel: (_) => _onClick(click: false),
          child: widget.builder(_isHovered, isPressed)),
    );
  }

  void _onHoverChanged({required bool enabled}) {
    setState(() {
      _isHovered = enabled;
    });
  }

  void _onClick({required bool click}) {
    if (mounted) {
      setState(() {
        isPressed = click;
      });
    }
  }
}
