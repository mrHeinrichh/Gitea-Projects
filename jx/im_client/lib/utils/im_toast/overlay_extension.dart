import 'package:flutter/material.dart';
import 'package:jxim_client/utils/im_toast/toast_manager.dart';

typedef CancelFunc = void Function();

CancelFunc showWidgetToast(
  Widget widget, {
  int? milliseconds,
  Alignment? alignment,
}) {
  ToastManager.showWidgetText(
    alignment ?? Alignment.bottomCenter,
    milliseconds ?? 3000,
    widget,
  );
  return () => ToastManager.dismiss();
}

CancelFunc showLoadingPopup({String? msg, Widget? icon}) {
  ToastManager.showLoading(message: msg, icon: icon);
  return () => ToastManager.dismiss();
}

void dismissAllToast() {
  ToastManager.dismiss();
}
