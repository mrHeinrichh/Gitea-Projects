import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/normal_animation.dart';

/// toast 管理器
class ToastManager {
  ToastManager._privateConstructor();

  /// 初始化
  static TransitionBuilder init() {
    return BotToastInit();
  }

  /// 初始化
  static TransitionBuilder initWithParameters({TransitionBuilder? builder}) {
    final TransitionBuilder toastBuilder = BotToastInit();
    if (builder == null) return toastBuilder;
    return (BuildContext context, Widget? child) {
      return toastBuilder(context, builder(context, child!));
    };
  }

  ///
  static void dismissAll() {
    BotToast.cleanAll();
  }

  ///
  static void dismiss() {
    BotToast.closeAllLoading();
  }

  ///widget toast
  static CancelFunc showWidgetText(
    AlignmentGeometry align,
    int milliseconds,
    Widget widget,
  ) {
    // BotToast.removeAll(BotToast.textKey);
    return BotToast.showCustomText(
      onlyOne: true,
      duration: Duration(milliseconds: milliseconds),
      align: align,
      wrapAnimation: null,
      wrapToastAnimation: textAnimation,
      toastBuilder: (_) {
        return widget;
      },
    );
  }

  static Widget textAnimation(
    AnimationController controller,
    CancelFunc cancelFunc,
    Widget child,
  ) =>
      NormalAnimation(
        controller: controller,
        child: child,
      );
}
