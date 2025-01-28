/*
 * 判断语音视频控件是否占用
 */

import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import '../utils/toast.dart';
import 'call_mgr.dart';

bool rtcIsCalling({
  bool showToast = true,
}) {
  var _isUsing = false;
  if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
    if (showToast) {
      Toast.showToast(localized(toastEndCallFirst));
    }
    _isUsing = true;
  }

  return _isUsing;
}

bool notBlank(dynamic o) {
  return GetUtils.isNullOrBlank(o) == false;
}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}
