import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/language_translate_model.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/utility.dart';

class LangMgr extends BaseMgr {
  static const String langKey = "default_lang";
  static const String eventUpdateLang = 'update_lang';
  Locale currLocale = const Locale("zh", "CN");
  final String? savePath;
  List<LanguageTranslateModel> languageList = [];

  LangMgr({this.savePath = 'download'});

  /// 本地缓存文件根目录
  String get appDocumentLangRootPath => AppPath.appDocumentLangRootPath;

  @override
  Future<void> initialize() async {
    _getUserDefaultLang();
    getRemoteTranslation();
  }

  @override
  Future<void> cleanup() async {
    _getUserDefaultLang();
    onLangLoaded();
  }

  onLangLoaded() {
    event(this, eventUpdateLang);
  }

  Locale getSystemLang() {
    final String defaultLocaleStr = Platform.localeName;
    List<String> localeParts = defaultLocaleStr.split("_");
    Locale sysLocale = Locale(localeParts.first, localeParts.last);
    if (localeParts.first.toLowerCase() == "zh" &&
        localeParts.last.toLowerCase() == "us") {
      sysLocale = Locale(localeParts.first, "CN");
    }
    return sysLocale;
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
    commonLangMgr.syncCurrLocale(currLocale);
  }

  // 获取本地语言的json内容
  Future<String?> _readJson(String? localPath) async {
    if (localPath == null || localPath.isEmpty) {
      return null;
    }
    final file = File(localPath);
    bool exist = await file.exists();
    if (exist == false) {
      return null;
    }
    final contents = await file.readAsString();
    return contents;
  }

  Future<String> _getLanguageFile(String langCode) async {
    String fileUrl = "";
    if (languageList.isNotEmpty) {
      for (var item in languageList) {
        if (langCode == getAppLanguageCode(item.language)) {
          fileUrl = item.path;
        }
      }
    }
    return fileUrl;
  }

  // 加载本地语言包
  Future<String> getLocalLangJson(String langCode) async {
    String localLangJsonStr =
        await rootBundle.loadString('assets/lang/$langCode.json');
    // 调试模式优先用本地语言包
    if (kDebugMode || Config().isDebug) return localLangJsonStr;
    final localData = jsonDecode(localLangJsonStr);
    // 本地强制版本号1
    localData['ver'] = 1;

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
    try {
      languageList = await getLanguageTranslation(
        getServerLanguageCode(currLocale.languageCode),
      );

      if (languageList.isNotEmpty) {
        List<Future<String?>> futures = [];
        for (final item in languageList) {
          futures.add(
            _downloadLangFile(
              item.path.startsWith("/") ? item.path.substring(1) : item.path,
            ),
          );
        }

        /// 获取新语言包后,更新语言
        await Future.wait(futures);
        AppLocalizations(currLocale).load();
      }
    } catch (e) {
      pdebug("======================>获取语言包失败");
    }
  }

  String _getRelativePath(String downloadUrl) {
    if (downloadUrl.isEmpty) {
      return '';
    }
    Uri uri = Uri.parse(downloadUrl);
    String uriPath = uri.path;
    uriPath = uriPath.replaceAll('$appDocumentLangRootPath/', '');
    uriPath = uriPath.replaceAll(appDocumentLangRootPath, '');
    if (uriPath.startsWith('/')) uriPath = uriPath.substring(1);
    return uriPath;
  }

  _getSavePath(downloadUrl) {
    return "$appDocumentLangRootPath/${_getRelativePath(downloadUrl)}";
  }

  Future<String?> _downloadLangFile(
    String downloadUrl, {
    Duration timeout = const Duration(seconds: 60),
    // int priority = 1, // 任务优先级
  }) {

    return downloadMgrV2.download(downloadUrl, timeout: timeout).then((value) => value.localPath);
    // return downloadMgr.downloadFile(
    //   downloadUrl,
    //   timeout: timeout,
    //   priority: priority,
    // );
  }

  // 切换语言包
  updateUserDefaultLang(
    Locale locale, {
    bool isSaveLocal = true,
    bool fromSetLanguage = false,
  }) {
    currLocale = locale;
    setUserDefaultLang(currLocale, isSaveLocal: isSaveLocal);
    commonLangMgr.syncCurrLocale(currLocale);
    MyAppState? state = navigatorKey.currentState?.context
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

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
