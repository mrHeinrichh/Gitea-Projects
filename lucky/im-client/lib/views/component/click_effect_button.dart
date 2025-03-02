import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';

class OverlayEffect extends StatefulWidget {
  final Widget child;
  final Color? overlayColor;
  final bool? withEffect;
  final BorderRadius? radius;

  const OverlayEffect({
    super.key,
    required this.child,
    this.overlayColor = JXColors.outlineColor,
    this.withEffect = true,
    this.radius = BorderRadius.zero,
  });

  @override
  State<OverlayEffect> createState() => _OverlayEffectState();
}

class _OverlayEffectState extends State<OverlayEffect> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() {
        isPressed = true;
      }),
      onPointerUp: (_) => setState(() {
        isPressed = false;
      }),
      onPointerCancel: (_) => setState(() {
        isPressed = false;
      }),
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: (isPressed && widget.withEffect == true)
              ? (widget.overlayColor ?? JXColors.outlineColor)
              : Colors.transparent,
          borderRadius: widget.radius ?? BorderRadius.zero,
        ),
        child: widget.child,
      ),
    );
  }
}

class OpacityEffect extends StatefulWidget {
  final Widget child;
  final bool isDisabled;

  const OpacityEffect({
    super.key,
    required this.child,
    this.isDisabled = false,
  });

  @override
  State<OpacityEffect> createState() => _OpacityEffectState();
}

class _OpacityEffectState extends State<OpacityEffect> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.isDisabled
          ? null
          : (_) => setState(() {
                isPressed = true;
              }),
      onPointerUp: widget.isDisabled
          ? null
          : (_) => setState(() {
                isPressed = false;
              }),
      behavior: HitTestBehavior.translucent,
      child: Opacity(
        opacity: isPressed || widget.isDisabled ? 0.2 : 1,
        child: widget.child,
      ),
    );
  }
}

class ScaleEffect extends StatefulWidget {
  final Widget child;

  const ScaleEffect({super.key, required this.child});

  @override
  State<ScaleEffect> createState() => _ScaleEffectState();
}

class _ScaleEffectState extends State<ScaleEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> animationValue;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 333),
      vsync: this,
    );

    animationValue = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _controller.forward();
      },
      onPointerUp: (_) {
        _controller.reverse();
      },
      behavior: HitTestBehavior.translucent,
      child: Transform.scale(
        scale: animationValue.value,
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

class ForegroundOverlayEffect extends StatefulWidget {
  final Widget child;
  final Color? overlayColor;
  final bool? withEffect;
  final BorderRadius? radius;

  const ForegroundOverlayEffect({
    super.key,
    required this.child,
    this.overlayColor = JXColors.outlineColor,
    this.withEffect = true,
    this.radius = BorderRadius.zero,
  });

  @override
  State<ForegroundOverlayEffect> createState() =>
      _ForegroundOverlayEffectState();
}

class _ForegroundOverlayEffectState extends State<ForegroundOverlayEffect> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() {
        isPressed = true;
      }),
      onPointerUp: (_) => setState(() {
        isPressed = false;
      }),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: <Widget>[
          widget.child,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: (isPressed && widget.withEffect == true)
                    ? (widget.overlayColor ?? JXColors.outlineColor)
                    : Colors.transparent,
                borderRadius: widget.radius ?? BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
