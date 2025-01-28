import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path_provider/path_provider.dart';

class AppPath {
  static String? _appDocumentLangRootPath;

  static String get appDocumentLangRootPath => _appDocumentLangRootPath ?? '';

  static String? _appDownloadPath;

  static String get appDownloadPath => _appDownloadPath ?? '';

  static String? _appDocumentRootPath;

  static String get appDocumentRootPath => _appDocumentRootPath ?? '';

  static String? _appCacheRootPath;

  static String get appCacheRootPath => _appCacheRootPath ?? '';

  static String? _applicationSupportPath;

  static String get applicationSupportPath => _applicationSupportPath ?? '';

  static Future<bool> init() async {
    var isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
    final String prefix = isDesktop ? "/${Config().appName}" : '';
    const String savePath = "download";
    try {
      final applicationDocumentsDirectory =
          await getApplicationDocumentsDirectory();
      _appDocumentRootPath = "${applicationDocumentsDirectory.path}$prefix";
      _appDownloadPath = "$_appDocumentRootPath/$savePath";
      _appDocumentLangRootPath = "$_appDownloadPath";

      if (!Directory(_appDocumentLangRootPath!).existsSync()) {
        Directory(_appDocumentLangRootPath!).createSync(recursive: true);
      }
    } catch (e) {
      pdebug(
        "=============getApplicationDocumentsDirectory 初始化失败",
      );
    }
    try {
      // ==============
      final applicationSupportDirectory =
          await getApplicationSupportDirectory();
      _applicationSupportPath = applicationSupportDirectory.path;
    } catch (e) {
      pdebug("===========getApplicationSupportDirectory 初始化失败");
    }

    try {
      // ==============
      final temporaryDirectory = await getTemporaryDirectory();
      _appCacheRootPath = temporaryDirectory.path;
    } catch (e) {
      pdebug("============getTemporaryDirectory 初始化失败");
    }
    return true;
  }

  static clearAllPath() {
    clearDirectory(Directory(_appDocumentRootPath!));
    clearDirectory(Directory(_appDocumentLangRootPath!));
    clearDirectory(Directory(_appCacheRootPath!));
    clearDirectory(Directory(_applicationSupportPath!));
  }
}
