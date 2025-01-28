import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/normal_animation.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

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

  static CancelFunc showLoading({String? message, Widget? icon}) {
    return BotToast.showCustomLoading(
      toastBuilder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: colorOverlay82,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: icon != null,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: icon,
                  ),
                ),
              ),
              Text(
                message ?? localized(isLoadingText),
                style: jxTextStyle.normalText(color: colorWhite),
              ),
            ],
          ),
        );
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
