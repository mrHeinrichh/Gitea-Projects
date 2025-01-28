import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:path_provider/path_provider.dart';

class LangMgr extends EventDispatcher {
  static const String langKey = "default_lang";
  static const String eventUpdateLang = 'update_lang';
  Locale currLocale = const Locale("zh", "CN");
  final String? savePath;
  LangMgr({this.savePath = 'download/lang'});

  /// 本地缓存文件根目录
  late String _appDocumentLangRootPath;
  String get appDocumentRootPath => _appDocumentLangRootPath;
  Future<void> init() async {
    _appDocumentLangRootPath =
        "${(await getApplicationDocumentsDirectory()).path}/$savePath";
    _getUserDefaultLang();
  }

  onLangLoaded() {
    event(this, eventUpdateLang);
  }

  Locale getSystemLang() {
    Locale locale = currLocale;
    final String defaultLocaleStr = Platform.localeName;
    List<String> localeParts = defaultLocaleStr.split("_");
    Locale sysLocale = Locale(localeParts.first, localeParts.last);
    if (localeParts.first.toLowerCase() == "zh" && localeParts.last.toLowerCase() == "us"){
      sysLocale = Locale(localeParts.first, "CN");
    }
    if (AppLocalizations.delegate.isSupported(sysLocale)) {
      locale = sysLocale;
    }
    return locale;
  }

  String getLangKey() {
    String langCode = "";
    String localeStr = objectMgr.localStorageMgr.read(langKey) ?? "";
    List<String> localeStrParts = localeStr.split("_");
    if (localeStrParts.length == 2) {
      langCode = localeStrParts[0];
    }
    return langCode;
  }

  // 获取用户语言，如用户没有设置过则使用系统默认语言，如不支持系统语言则默认使用英文
  _getUserDefaultLang() {
    String localeStr = objectMgr.localStorageMgr.read(langKey) ?? "";
    List<String> localeStrParts = localeStr.split("_");
    if (localeStrParts.length == 2) {
      currLocale = Locale(localeStrParts[0], localeStrParts[1]);
    } else {
      currLocale = getSystemLang();
    }
    agoraLangMgr.currLocale = currLocale;
  }

  // 获取本地语言的json内容
  Future<String?> _readJson(String? localPath) async {
    if (localPath == null || localPath.isEmpty) {
      return null;
    }
    final file = await File(localPath);
    bool exist = await file.exists();
    if (exist == false) {
      return null;
    }
    final contents = await file.readAsString();
    return contents;
  }

  Future<String> _getLanguageFile(String langCode) async {
    String fileUrl = "";
    final res =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.TRANSLATION);
    if (res != null) {
      final data = jsonDecode(res);
      if (data != null) {
        if (langCode == "en") {
          fileUrl = data['en_uk']['path'];
        } else if (langCode == "zh") {
          fileUrl = data['cn_s']['path'];
        }
      }
    }
    return fileUrl;
  }

  // 加载本地语言包
  Future<String> getLocalLangJson(String langCode) async {
    String localLangJsonStr =
        await rootBundle.loadString('assets/lang/$langCode.json');
    final localData = jsonDecode(localLangJsonStr);

    String fileUrl = await _getLanguageFile(langCode);
    String? savePath = _getSavePath(fileUrl);
    if (savePath == null) {
      return localLangJsonStr;
    }

    bool exist = await File(savePath).exists();
    if (exist == false) {
      return localLangJsonStr;
    }

    String? localPath = await _downloadLangFile(fileUrl);
    String? langJsonStr = await _readJson(localPath);

    if (langJsonStr != null) {
      final remoteData = jsonDecode(langJsonStr);
      if (localData['ver'] < remoteData['ver']) {
        return langJsonStr;
      } else {
        return localLangJsonStr;
      }
    } else {
      return localLangJsonStr;
    }
  }

  // 连上网了下载语言包路径
  Future<void> getRemoteTranslation() async {
    // 拿到远程语言包地址
    final res = await getTranslation();
    if (res.length > 0) {
      res.map((value) {
        value['savePath'] = _getSavePath(value['path']);
      });
      final map = Map<String, dynamic>.fromIterable(
        res,
        key: (item) => item["language"],
        value: (item) => item,
      );
      // 缓存远程语言包路径
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.TRANSLATION, jsonEncode(map));

      for (var key in map.keys) {
        var value = map[key];
        await _downloadLangFile(
          value['path'],
        );
      }
    }
  }

  String _getRelativePath(String downloadUrl) {
    if (downloadUrl == null || downloadUrl.isEmpty) {
      return '';
    }
    Uri uri = Uri.parse(downloadUrl);
    String uriPath = uri.path;
    uriPath = uriPath.replaceAll('$_appDocumentLangRootPath/', '');
    uriPath = uriPath.replaceAll('$_appDocumentLangRootPath', '');
    return uriPath;
  }

  _getSavePath(downloadUrl) {
    return "${_appDocumentLangRootPath}/${_getRelativePath(downloadUrl)}";
  }

  Future<String?> _downloadLangFile(
    String downloadUrl, {
    int timeoutSeconds = 60,
    int priority = 1, // 任务优先级
  }) {
    String? savePath = _getSavePath(downloadUrl);
    return downloadMgr.downloadFile(downloadUrl,
        savePath: savePath, timeoutSeconds: timeoutSeconds, priority: priority);
  }

  // 切换语言包
  updateUserDefaultLang(Locale locale,
      {bool isSaveLocal = true, bool fromSetLanguage = false}) {
    currLocale = locale;
    setUserDefaultLang(currLocale, isSaveLocal: isSaveLocal);
    agoraLangMgr.currLocale = currLocale;
    MyAppState? state = Routes.navigatorKey.currentState?.context
        .findAncestorStateOfType<MyAppState>();
    state?.changeLanguage(currLocale, fromSetLanguage: fromSetLanguage);
  }

  setUserDefaultLang(Locale locale, {bool isSaveLocal = true}) async {
    if (isSaveLocal) {
      await objectMgr.localStorageMgr
          .write(langKey, "${locale.languageCode}_${locale.countryCode}");
    } else {
      await objectMgr.localStorageMgr.write(langKey, "");
    }
  }
}
