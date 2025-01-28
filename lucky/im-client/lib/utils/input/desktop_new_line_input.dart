import 'dart:io';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';

class DesktopNewLineInput extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    if (newValue.text.contains('\n') && objectMgr.loginMgr.isDesktop) {
      if (!isShiftKeyPressed() && isEnterPressed()) {
        return oldValue;
      }
    }
    return newValue;
  }
}

bool isEnterPressed() {
  final Set<LogicalKeyboardKey> keyStates = RawKeyboard.instance.keysPressed;
  return keyStates
      .any((LogicalKeyboardKey key) => key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter);
}

bool isShiftKeyPressed() {
  final Set<LogicalKeyboardKey> keyStates = RawKeyboard.instance.keysPressed;
  return keyStates.any((LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight);
}

bool getCombinationKey() {
  final Set<LogicalKeyboardKey> keyStates = RawKeyboard.instance.keysPressed;
  if (Platform.isMacOS) {
    return keyStates.any((LogicalKeyboardKey key) =>
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight);
  } else if (Platform.isWindows) {
    return keyStates.any((LogicalKeyboardKey key) =>
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight);
  }
  return false;
}
