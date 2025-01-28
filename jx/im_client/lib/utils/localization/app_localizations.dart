import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';


String interpolate(String string, List<String> params) {
  String result = string;
  for (int i = 1; i < params.length + 1; i++) {
    result = result.replaceAll('%$i', params[i - 1]);
  }

  return result;
}

String localized(String jsonPath, {List<String> params = const []}) {
  if (navigatorKey.currentState != null) {
    final text = AppLocalizations.of(navigatorKey.currentState!.context)
            ?.str(jsonPath) ??
        "";
    if (params.isNotEmpty) {
      return interpolate(text, params);
    }
    return text;
  }
  return '';
}

class AppLocalizations {
  late Locale locale;
  int currVer = 1;
  static Map<String, dynamic> _localizedStrings = {};

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static List<Locale> appSupportedLocales = const [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
    Locale('km', 'KH'),
    Locale('ja', 'JP'),
  ];

  AppLocalizations(this.locale);

  Future<bool> load() async {
    // 现加载本地的
    final jsonString = await objectMgr.langMgr.getLocalLangJson(locale.languageCode);
    _setLangStr(jsonString);
    return true;
  }

  _setLangStr(String langJsonStr) {
    if(objectMgr.langMgr.currLocale.languageCode == locale.languageCode){
      final langJson = json.decode(langJsonStr);
      if (langJson.containsKey("ver")) {
        currVer = langJson["ver"];
        _localizedStrings = langJson["data"];
      } else {
        _localizedStrings = langJson;
      }
      commonLangMgr.syncLocalized(_localizedStrings);
      objectMgr.langMgr.onLangLoaded();
    }
  }

  isEnglish() {
    return locale.languageCode.contains("en");
  }

  isMandarin() {
    return locale.languageCode.contains("zh");
  }

  String str(String key) {
    var tmpMap = _localizedStrings;
    String value = '';

    if (tmpMap[key].runtimeType == Null) {
      value = key;
    } else {
      if (tmpMap[key].runtimeType != String) {
        tmpMap = tmpMap[key];
      } else {
        value = tmpMap[key];
      }
    }
    return value;
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en', 'km', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return SynchronousFuture<AppLocalizations>(localizations);
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => true;
}
