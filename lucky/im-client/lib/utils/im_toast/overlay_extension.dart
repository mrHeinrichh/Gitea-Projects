import 'package:flutter/material.dart';
import 'package:jxim_client/utils/im_toast/toast_manager.dart';

typedef CancelFunc = void Function();


CancelFunc showWidgetToast(Widget widget,
    {int? milliseconds, Alignment? aliment}) {
  ToastManager.showWidgetText(
      aliment ?? Alignment.center, milliseconds ?? 3000, widget);
  return () => ToastManager.dismiss();
}
