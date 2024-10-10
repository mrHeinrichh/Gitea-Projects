import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/utils/debounce.dart';

/// initState中添加 WidgetsBinding.instance.addObserver(KeyBoardObserver.instance);
/// dispose中添加 WidgetsBinding.instance.removeObserver(KeyBoardObserver.instance);
/// 这个是实时变化的键盘高度
typedef FunctionType = void Function(bool isKeyboardShow);

class KeyBoardObserver extends WidgetsBindingObserver {
  double keyboardHeightNow = 0;
  double keyboardHeightOpen = 0;
  bool? isUp;
  double preBottom = -1;
  double lastBottom = -1;

  ///计算回调次数
  int times = 0;

  KeyBoardObserver._();

  static final KeyBoardObserver _instance = KeyBoardObserver._();

  static KeyBoardObserver get instance => _instance;

  FunctionType? listener;

  void addListener(FunctionType listener) {
    this.listener = listener;
  }

  @override
  void didChangeMetrics() {
    EasyDebounce.debounce(
        'record_keyboard_height', const Duration(milliseconds: 200), () {
      times++;
      // debugPrint("didChangeMetrics times $times");

      MediaQueryData mediaQueryData = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.single,
      );
      final bottom = mediaQueryData.viewInsets.bottom;
      // 键盘存在中间态，回调是键盘冒出来的高度
      // debugPrint(
      //     'didChangeMetrics 数值------->  bottom $bottom keyboardHeightNow $keyboardHeightNow keyboardHeightOpen $keyboardHeightOpen pre ${preBottom}  last $lastBottom');

      double diff = keyboardHeightNow - bottom;

      if (diff < 0) {
        isUp = true;
        keyboardHeightNow = max(keyboardHeightNow, bottom);
        keyboardHeightOpen = keyboardHeightNow;
      } else if (diff > 0) {
        isUp = false;
        keyboardHeightNow = min(keyboardHeightNow, bottom);
        // keyboardHeightOpen = keyboardHeightNow;
      } else {
        if (isUp != null) {
          if (isUp!) {
            keyboardHeightNow = max(keyboardHeightNow, bottom);
            keyboardHeightOpen = keyboardHeightNow;
          } else {
            keyboardHeightNow = min(keyboardHeightNow, bottom);
            if (keyboardHeightNow < keyboardHeightOpen) {
              keyboardHeightNow = keyboardHeightOpen;
            }
          }
        } else {
          keyboardHeightNow = keyboardHeightOpen;
        }
      }

      isUp = null;
      if (keyboardHeightNow < 200) {
        keyboardHeight.value = keyboardHeightOpen;
      } else {
        keyboardHeight.value = keyboardHeightNow;
      }
      if (keyboardHeight.value > 200) {
        keyboardHeightOpen = keyboardHeight.value;
      }
      // debugPrint('keyboardHeight-----> $keyboardHeight.value');

      preBottom = bottom;
    });
  }
}
