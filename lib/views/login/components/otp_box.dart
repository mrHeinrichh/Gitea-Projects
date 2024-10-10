import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class OTPBox extends StatelessWidget {
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
    this.autoDismissKeyboard = true,
    this.keyboardType,
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
  Widget build(BuildContext context) {
    return PinCodeTextField(
      focusNode: focusNode,
      cursorColor: Colors.black,
      appContext: context,
      enabled: enabled,
      enableActiveFill: true,
      length: length,
      readOnly: readOnly,
      obscureText: obscureText,
      controller: controller,
      autoFocus: autoFocus,
      animationType: AnimationType.fade,
      autoDisposeControllers: autoDisposeControllers,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        borderWidth: borderWidth ?? 1,
        fieldHeight: boxHeight ?? 58.w,
        fieldWidth: objectMgr.loginMgr.isDesktop ? 48 : boxWidth ?? 68.w,
        activeColor: error ? Colors.red : colorTextPlaceholder,
        selectedColor: error ? Colors.red : themeColor,
        inactiveColor: error ? Colors.red : colorTextPlaceholder,
        activeFillColor: error ? Colors.red.withOpacity(0.2) : colorBackground,
        selectedFillColor:
            error ? Colors.red.withOpacity(0.2) : colorBackground,
        inactiveFillColor:
            error ? Colors.red.withOpacity(0.2) : colorBackground,
      ),
      cursorHeight: 0,
      animationDuration: const Duration(milliseconds: 100),
      onChanged: onChanged,
      onCompleted: onCompleted,
      textStyle: jxTextStyle.textStyleBold20(),
      keyboardType: keyboardType ?? const TextInputType.numberWithOptions(),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      autoDismissKeyboard: autoDismissKeyboard,
    );
  }
}
