import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_font_size.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';

import '../theme/text_styles.dart';
import 'im_border_radius.dart';

enum ButtonSize {
  large,
  middle,
  small,
  mini
}

/// figma 设计主要按钮
class PrimaryButton extends StatefulWidget {
  final String title;
  final Color? txtColor;
  final FontWeight? fontWeight;
  final double borderRadius;
  final Color? bgColor;
  final bool withBorder;
  final Color? borderColor;
  final double width;
  final Widget? child;
  final ButtonSize size;
  final bool disabled;
  final Color? disabledTxtColor;
  final Color? disabledBgColor;
  final bool block;
  final VoidCallback? onPressed;

  const PrimaryButton({
    Key? key,
    this.title = '',
    this.txtColor,
    this.fontWeight,
    this.borderRadius = 12,
    this.bgColor,
    this.withBorder = false,
    this.borderColor,
    this.width = 170,
    this.child,
    this.size = ButtonSize.large,
    this.disabled = false,
    this.disabledTxtColor,
    this.disabledBgColor,
    this.block = false,
    this.onPressed,
  }) : super(key: key);

  @override
  _PrimaryButtonState createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  double get height {
    switch (widget.size) {
      case ButtonSize.large:
        return 48;
      case ButtonSize.middle:
        return 40;
      case ButtonSize.small:
        return 32;
      case ButtonSize.mini:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget current;

    if (widget.child != null) {
      current = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[widget.child!],
      );
    } else {
      current = Align(
        alignment: Alignment.center,
        child: ImText(
          widget.title,
          color: widget.disabled
              ? widget.disabledTxtColor ?? ImColor.grey20
              : widget.txtColor ?? ImColor.white,
          fontWeight: widget.fontWeight ?? MFontWeight.bold6.value,
          fontSize: widget.size == ButtonSize.large
              ? ImFontSize.large
              : widget.size == ButtonSize.middle
              ? ImFontSize.normal
              : ImFontSize.small,
          textOverflow: TextOverflow.visible,
        ),
      );
    }

    current = widget.block || widget.child != null
        ? current
        : Padding(
      padding: EdgeInsets.symmetric(horizontal: height.w / 2),
      child: current,
    );

    current = SizedBox(
      width: widget.block ? double.infinity : widget.width.w,
      height: height.w,
      child: current,
    );

    current = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.disabled
            ? widget.disabledBgColor ?? ImColor.grey8
            : widget.bgColor ?? ImColor.purple,
        borderRadius: ImBorderRadius.all(widget.borderRadius),
        border: widget.withBorder
            ? Border.all(
          width: 1.w,
          color: widget.borderColor ?? Colors.transparent,
        )
            : null,
      ),
      child: current,
    );

    if (_isPressed) {
      current = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: ImBorderRadius.all(widget.borderRadius),
        ),
        position: DecorationPosition.foreground,
        child: current,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.disabled ? null : widget.onPressed,
      child: current,
      onTapDown: (_) {
        if (!widget.disabled) {
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (_) {
        if (!widget.disabled) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      onTapCancel: () {
        if (!widget.disabled) {
          setState(() {
            _isPressed = false;
          });
        }
      },
    );
  }
}
