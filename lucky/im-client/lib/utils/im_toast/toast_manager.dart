import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/loading_lottie.dart';
import 'package:jxim_client/utils/normal_animation.dart';

import '../theme/text_styles.dart';

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

  /// loading 对话框
  static CancelFunc showLoading(
      {String? status, bool? isAllowBack, bool isGame = false}) {
    return BotToast.showCustomLoading(
        backButtonBehavior: isAllowBack != null
            ? (isAllowBack ? BackButtonBehavior.close : BackButtonBehavior.none)
            : BackButtonBehavior.none,
        backgroundColor: Colors.black.withOpacity(0.2),
        toastBuilder: (_) {
          return /*isGame
              ? LoadingV2(text: status ?? "loading")
              :*/
            LoadingLottie(
              text: status ?? "loading",
            );
        });
  }

  ///
  static CancelFunc showText(String message, {int? milliseconds}) {
    return showNormalText(message, Alignment.center, milliseconds ?? 1500);
  }

  ///
  static CancelFunc showBottomNormalText(String message, {int? milliseconds}) {
    return showNormalText(
        message, Alignment.bottomCenter, milliseconds ?? 1500);
  }

  static CancelFunc showNormalText(
      String message, AlignmentGeometry align, int milliseconds,
      {EdgeInsets? location}) {
    BotToast.removeAll(BotToast.textKey);
    return BotToast.showCustomText(
      onlyOne: true,
      duration: Duration(milliseconds: milliseconds),
      align: align,
      wrapAnimation: opacityAnimation,
      animationDuration: const Duration(milliseconds: 300),
      animationReverseDuration: const Duration(milliseconds: 300),
      wrapToastAnimation: null,
      toastBuilder: (_) {
        return Container(
          margin: location ??
              const EdgeInsets.only(
                top: 100,
                left: 16.5,
                right: 16.5,
                bottom: 50,
              ),
          decoration: const ShapeDecoration(
            shape: StadiumBorder(),
            color: Color(0XFF9B9B9D),//   0x99121212
          ),
          constraints: const BoxConstraints(
            minWidth: 96,
            minHeight: 40,
          ),
          padding: const EdgeInsets.fromLTRB(24, 7, 24, 9),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight:MFontWeight.bold4.value,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            softWrap: true,
          ),
        );
      },
    );
  }

  /// 单行显示  超过三个点
  static CancelFunc showTopText(String message) {
    return BotToast.showCustomNotification(
        onlyOne: true,
        duration: const Duration(seconds: 2),
        toastBuilder: (cancel) {
          return Container(
            width: 330,
            height: 45,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: Platform.isIOS ? Colors.transparent : Colors.black,
              shape: const StadiumBorder(),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          );
        },
        enableSlideOff: true,
        crossPage: true);
  }

  /// 单行显示, +图标
  static CancelFunc showTopWidgetText(String message, IconType icon) {
    return BotToast.showCustomNotification(
        onlyOne: true,
        duration: const Duration(seconds: 2),
        toastBuilder: (cancel) {
          return Container(
            margin: const EdgeInsets.only(top: 97,left: 10,right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: const ShapeDecoration(// 0XFF16181F
              color: Color(
                  0XFF9B9B9D), //Platform.isIOS ? Colors.transparent : Colors.black,
              shape: StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  getIcon(icon),
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
                const SizedBox(
                  width: 8,
                ),
                Container(
                  constraints:
                  const BoxConstraints(minWidth: 10, maxWidth: 280),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.left,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          );
        },
        enableSlideOff: true,
        crossPage: true);
  }

  static CancelFunc showBottomWidgetText(String message, IconType icon) {
    return BotToast.showCustomNotification(
        onlyOne: true,
        duration: const Duration(seconds: 2),
        align: const Alignment(0, 0.99),
        toastBuilder: (cancel) {
          return Container(
            width: 330,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  getIcon(icon),
                  width: 12,
                  height: 12,
                  fit: BoxFit.cover,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ),
          );
        });
  }

  static CancelFunc showBottomWarningToast(String message) {
    return showBottomWidgetText(message, IconType.commonIconWarning);
  }

  static CancelFunc showSuccessToast(String message) {
    return showTopWidgetText(message, IconType.commonIconSuccess);
  }

  static CancelFunc showWarningToast(String message) {
    return showTopWidgetText(message, IconType.commonIconWarning);
  }

  static CancelFunc showErrorToast(String message) {
    return showTopWidgetText(message, IconType.commonIconError);
  }

  ///
  static CancelFunc showSuccess({String? message}) {
    const Alignment align = Alignment.center;
    return BotToast.showAnimationWidget(
      wrapToastAnimation:
          (AnimationController controller, Function cancel, Widget child) {
        child = Align(alignment: align, child: child);
        return SafeArea(child: child);
      },
      animationDuration: const Duration(milliseconds: 300),
      groupKey: BotToast.loadKey,
      onlyOne: true,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 2),
      toastBuilder: (_) {
        return Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.done,
                color: Colors.white,
                size: 40,
              ),
              Column(
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    message ?? "success",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight:MFontWeight.bold4.value,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  ///
  static CancelFunc showError({String? message}) {
    const Alignment align = Alignment.center;
    return BotToast.showAnimationWidget(
        wrapToastAnimation:
            (AnimationController controller, Function cancel, Widget child) {
          child = Align(alignment: align, child: child);
          return SafeArea(child: child);
        },
        animationDuration: const Duration(milliseconds: 300),
        groupKey: BotToast.loadKey,
        onlyOne: true,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
        toastBuilder: (_) {
          return Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border:
              Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.clear,
                  color: Colors.white,
                  size: 40,
                ),
                Column(
                  children: <Widget>[
                    const SizedBox(height: 8),
                    Text(
                      message ?? "record_failed",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight:MFontWeight.bold4.value,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  ///widget toast
  static CancelFunc showWidgetText(
      AlignmentGeometry align, int milliseconds, Widget widget) {
     BotToast.removeAll(BotToast.textKey);
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

  static String getIcon(IconType type) {
    switch (type) {
      case IconType.commonIconError:
        return "packages/im_common/assets/img/icon_toast_fail.png";
      case IconType.commonIconSuccess:
        return "packages/im_common/assets/img/icon_toast_success.png";
      case IconType.commonIconWarning:
        return "packages/im_common/assets/img/common_icon_warning.png";
    }
  }
}

Widget opacityAnimation(
    AnimationController controller, CancelFunc cancelFunc, Widget child) =>
    NormalAnimation(reverse: true, controller: controller, child: child);

/// 二次封装
class ToastObserver extends BotToastNavigatorObserver {}

Widget textAnimation(
    AnimationController controller, CancelFunc cancelFunc, Widget child) =>
    NormalAnimation(
      controller: controller,
      child: child,
    );

enum IconType {
  commonIconWarning,
  commonIconSuccess,
  commonIconError,
}
