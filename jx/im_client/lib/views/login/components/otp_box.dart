import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:pin_code_fields_im/pin_code_fields.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class OTPBox extends StatefulWidget {
  const OTPBox({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.length = 4,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.error = false,
    this.correct = false,
    this.focusNode,
    this.autoFocus = true,
    this.autoDisposeControllers = false,
    this.readOnly = false,
    this.boxWidth,
    this.boxHeight,
    this.borderWidth,
    this.borderRadius,
    this.pinBoxColor,
    this.autoDismissKeyboard = false,
    this.keyboardType,
    this.autoUnfocus = false,
  });
  final void Function(String value) onChanged;
  final void Function(String value) onCompleted;
  final int length;
  final bool obscureText;
  final TextEditingController? controller;
  final bool enabled;
  final bool error;
  final bool correct;
  final FocusNode? focusNode;
  final bool autoFocus;
  final bool autoUnfocus;
  final bool autoDisposeControllers;
  final bool readOnly;
  final double? boxWidth;
  final double? boxHeight;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final Color? pinBoxColor;
  final bool autoDismissKeyboard;
  final TextInputType? keyboardType;

  @override
  State<OTPBox> createState() => _OTPBoxState();
}

class _OTPBoxState extends State<OTPBox> with SingleTickerProviderStateMixin {
  late StreamController<ErrorAnimationType> errorController;

  late Animation<double> correctAnimation;
  late AnimationController correctAnimationController;

  @override
  void initState() {
    super.initState();

    correctAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));

    correctAnimation =
    TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeIn)), weight: 50.0),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)), weight: 50.0),
      ]
    ).animate(correctAnimationController)
      ..addListener(() {
        setState(() {});
      });

    errorController = StreamController<ErrorAnimationType>();
  }

  @override
  void dispose() {
    correctAnimationController.dispose();
    errorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.error) errorController.add(ErrorAnimationType.shake);
    if(widget.correct) correctAnimationController.forward();
    return ScaleTransition(
      scale: correctAnimation,
      child: PinCodeTextField(
        focusNode: widget.focusNode,
        cursorColor: Colors.black,
        appContext: context,
        enabled: widget.enabled,
        enableActiveFill: true,
        length: widget.length,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        controller: widget.controller,
        autoFocus: widget.autoFocus,
        animationType: AnimationType.slide,
        autoDisposeControllers: widget.autoDisposeControllers,
        autoUnfocus: widget.autoUnfocus,
        errorAnimationController: errorController,
        errorAnimationDuration: 300,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          borderWidth: widget.borderWidth ?? 1,
          fieldHeight: widget.boxHeight ?? 58.w,
          fieldWidth: objectMgr.loginMgr.isDesktop ? 48 : widget.boxWidth ?? 68.w,
          activeColor: widget.correct? colorGreen : widget.error
              ? colorRed : colorTextPlaceholder,
          selectedColor: themeColor,
          inactiveColor: colorTextPlaceholder,
          activeFillColor: colorBackground,
          selectedFillColor: colorBackground,
          inactiveFillColor: colorBackground,
        ),
        cursorHeight: 0,
        animationDuration: const Duration(milliseconds: 100),
        onChanged: widget.onChanged,
        onCompleted: (value){
          widget.onCompleted(value);
        },
        textStyle: jxTextStyle.textStyleBold20(),
        keyboardType: widget.keyboardType ?? const TextInputType.numberWithOptions(),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        autoDismissKeyboard: widget.autoDismissKeyboard,
      ),
    );
  }
}
