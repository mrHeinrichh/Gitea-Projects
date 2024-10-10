/*
 * 判断语音视频控件是否占用
 */

import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/managers/call_mgr.dart';

bool rtcIsCalling({
  bool showToast = true,
}) {
  var isUsing = false;
  if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
    if (showToast) {
      Toast.showToast(localized(toastEndCallFirst));
    }
    isUsing = true;
  }

  return isUsing;
}

bool notBlank(dynamic o) {
  return GetUtils.isNullOrBlank(o) == false;
}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}

String getAutoLocale({Chat? chat, bool isMe = true, bool fullName = false}) {
  String langSymbol = '';
  if (chat != null) {
    if (isMe) {
      if (chat.currentLocaleOutgoing != LanguageOption.auto.value) {
        langSymbol = chat.currentLocaleOutgoing;
      }
    } else {
      if (chat.currentLocaleIncoming != LanguageOption.auto.value) {
        langSymbol = chat.currentLocaleIncoming;
      }
    }

    if (langSymbol != '') {
      return langSymbol;
    }
  }
  String? langKeyFromLs = objectMgr.localStorageMgr.read(LangMgr.langKey);
  if (langKeyFromLs != null && langKeyFromLs.isNotEmpty) {
    List<String> localeParts = langKeyFromLs.split("_");
    langKeyFromLs = localeParts.first;
  } else {
    langKeyFromLs = objectMgr.langMgr.getSystemLang().languageCode;
  }
  if (notBlank(langKeyFromLs)) {
    if (langKeyFromLs == 'zh') langKeyFromLs = 'cn';
    if (langKeyFromLs == 'ja') langKeyFromLs = 'jp';
    langSymbol = langKeyFromLs.toUpperCase();
  } else {
    langSymbol = objectMgr.langMgr.getSystemLang().languageCode.toUpperCase();
  }

  if (fullName) {
    return getLangFullName(langSymbol);
  } else {
    return langSymbol;
  }
}

String getLangFullName(String code) {
  switch (code.toLowerCase()) {
    case "jp":
      return localized(langJp);
    case "cn":
      return localized(langZh);
    case "en":
      return localized(langEn);
    case "km":
      return localized(langKm);
    default:
      return "";
  }
}
