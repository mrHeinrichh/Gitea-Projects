import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomTile extends StatefulWidget {
  final GestureTapCallback? onTap;
  final bool withBorder;
  final bool withEffect;
  final double dividerIndent;
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? boxBorder;
  final double? height;

  const CustomTile({
    super.key,
    this.onTap,
    this.withBorder = false,
    this.withEffect = true,
    this.dividerIndent = 60,
    this.borderRadius,
    this.boxBorder,
    required this.child,
    this.height,
  });

  @override
  State<CustomTile> createState() => _CustomTileState();
}

class _CustomTileState extends State<CustomTile> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget child = OverlayEffect(
      overlayColor: colorBackground8,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: widget.boxBorder,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.child,
            if (widget.withBorder)
              separateDivider(
                indent: widget.dividerIndent,
              ),
          ],
        ),
      ),
    );
    if (widget.onTap != null) {
      child = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {
          if (widget.withEffect) {
            setState(() {
              isPressed = true;
            });
          }
        },
        onPanUpdate: (_) {
          if (widget.withEffect) {
            setState(() {
              isPressed = false;
            });
          }
        },
        onPanCancel: () {
          if (widget.withEffect) {
            setState(() {
              isPressed = false;
            });
          }
        },
        onTapUp: (_) {
          if (widget.withEffect) {
            setState(() {
              isPressed = false;
            });
          }
        },
        child: child,
      );
    }
    return child;
  }
}
