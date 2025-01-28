import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../main.dart';
import '../../../utils/color.dart';

class OTPBox extends StatelessWidget {
  const OTPBox({
    Key? key,
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
    this.boxWidth = 0.5,
    this.pinBoxColor,
    this.autoDismissKeyboard = true,
  }) : super(key: key);
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
  final double boxWidth;
  final Color? pinBoxColor;
  final bool autoDismissKeyboard;

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
          borderRadius: BorderRadius.circular(10),
          borderWidth: 1,
          fieldHeight: 48,
          fieldWidth:objectMgr.loginMgr.isDesktop ? 48 : (MediaQuery.of(context).size.width * boxWidth - (12)) / 4,
          activeColor:
              error ? Colors.red : (correct ? Colors.green : backgroundColor),
          selectedColor: accentColor,
          inactiveColor:
              error ? Colors.red : (correct ? Colors.green : JXColors.outlineColor),
          activeFillColor: (pinBoxColor != null) ? pinBoxColor : colorFCFCFC,
          selectedFillColor: (pinBoxColor != null) ? pinBoxColor : colorFCFCFC,
          inactiveFillColor: (pinBoxColor != null) ? pinBoxColor : colorFCFCFC),
      cursorHeight: 0,
      animationDuration: const Duration(milliseconds: 100),
      onChanged: onChanged,
      onCompleted: onCompleted,
      textStyle: jxTextStyle.textStyleBold20(),
      keyboardType: const TextInputType.numberWithOptions(),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      autoDismissKeyboard: autoDismissKeyboard,
    );
  }
}
