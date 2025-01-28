import 'dart:convert';
import 'dart:io';

import 'package:disk_space/disk_space.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DataAndStorageController extends GetxController {
  static const String MEDIA = "MEDIA";
  static const String FILE = "FILE";
  static const String TEXT = "TEXT";
  static const String OTHER = "OTHER";

  RxDouble totalSize = 0.0.obs;
  RxDouble totalPercentage = 0.0.obs;

  double mediaSize = 0.0;
  double fileSize = 0.0;
  double textSize = 0.0;
  double otherSize = 0.0;

  RxBool isClearing = false.obs;

  RxList<DataStorageModel> dataStorageList = [
    DataStorageModel(
      key: MEDIA,
      title: localized(media),
      percentage: 0.0,
      size: 0.0,
      color: const Color(0xFF8367F7),
    ),
    DataStorageModel(
      key: FILE,
      title: localized(files),
      percentage: 0.0,
      size: 0.0,
      color: const Color(0xFFFB5692),
    ),
    DataStorageModel(
      key: TEXT,
      title: localized(textString),
      percentage: 0.0,
      size: 0.0,
      color: const Color(0xFFF9C378),
    ),
    DataStorageModel(
      key: OTHER,
      title: localized(others),
      percentage: 0.0,
      size: 0.0,
      color: const Color(0xFF8CE5E5),
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    getTotalSize();
  }

  Future<void> getTotalSize() async {
    await Future.delayed(Duration.zero); // UI to load first

    getDataStorage();

    final appDownloadPath = AppPath.appDownloadPath;

    mediaSize = await calculateMediaSize(appDownloadPath);
    fileSize = await calculateFileSize(appDownloadPath);
    textSize = await calculateTextSize();
    otherSize = await calculateOtherSize(appDownloadPath);

    totalSize.value = mediaSize + fileSize + textSize + otherSize;
    updateDataStorageList();

    saveDataStorage();
    await getPhoneStorage(totalSize.value);
  }

  Future<double> calculateMediaSize(String documentPath) async {
    int avatarSize = await getTotalUsageAsync("$documentPath/avatar/");
    int groupSize = await getTotalUsageAsync("$documentPath/group/");
    int imageSize = await getTotalUsageAsync("$documentPath/Image/");
    int videoSize = await getTotalUsageAsync("$documentPath/Video/");
    int stickerSize = await getTotalUsageAsync("$documentPath/sticker/");

    return bytesToMB(
        avatarSize + groupSize + imageSize + videoSize + stickerSize);
  }

  Future<double> calculateFileSize(String documentPath) async {
    return bytesToMB(await getTotalUsageAsync("$documentPath/Document/"));
  }

  Future<double> calculateTextSize() async {
    final databaseDir = await getDatabasesPath();
    int dbSize = await getDatabaseFileSize(
        "$databaseDir/data_v014_${objectMgr.userMgr.mainUser.uid}.db");
    return bytesToMB(dbSize);
  }

  Future<double> calculateOtherSize(String documentPath) async {
    final appCacheRootPath = AppPath.appCacheRootPath;
    int cacheSize = await getTotalUsageAsync(appCacheRootPath);

    return bytesToMB(
          (await getTotalUsageAsync("$documentPath/") + cacheSize).toInt(),
        ) -
        mediaSize.toInt() -
        fileSize.toInt();
  }

  Future<int> getTotalUsageAsync(String path) async {
    final directory = Directory(path);
    int totalSize = 0;

    try {
      if (directory.existsSync()) {
        await for (var entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      pdebug(e);
    }
    return totalSize;
  }

  void updateDataStorageList() {
    dataStorageList.map((e) {
      switch (e.key) {
        case MEDIA:
          e.size = mediaSize;
          e.percentage = (mediaSize / totalSize.value) * 100;
          break;
        case FILE:
          e.size = fileSize;
          e.percentage = (fileSize / totalSize.value) * 100;
          break;
        case TEXT:
          e.size = textSize;
          e.percentage = (textSize / totalSize.value) * 100;
          break;
        case OTHER:
          e.size = otherSize;
          e.percentage = (otherSize / totalSize.value) * 100;
          break;
      }
    }).toList();

    dataStorageList.refresh();
  }

  void getDataStorage() {
    String localeStr =
        objectMgr.localStorageMgr.read(LocalStorageMgr.DATA_AND_STORAGE) ?? "";
    if (localeStr.isNotEmpty) {
      dataStorageList.value = jsonDecode(localeStr).map<DataStorageModel>((e) {
        DataStorageModel data = DataStorageModel.fromJson(e);
        switch (data.key) {
          case MEDIA:
            data.color = const Color(0xFF8367F7);
            break;
          case FILE:
            data.color = const Color(0xFFFB5692);
            break;
          case TEXT:
            data.color = const Color(0xFFF9C378);
            break;
          case OTHER:
            data.color = const Color(0xFF8CE5E5);
            break;
        }
        return data;
      }).toList();

      String? savedTotalSize =
          objectMgr.localStorageMgr.read(LocalStorageMgr.TOTAL_SIZE);
      if (savedTotalSize != null && savedTotalSize.isNotEmpty) {
        totalSize.value = double.tryParse(savedTotalSize) ?? 0.0;
      } else {
        totalSize.value = mediaSize + fileSize + textSize + otherSize;
      }
      dataStorageList.refresh();
    }
  }

  void saveDataStorage() {
    String jsonString =
        jsonEncode(dataStorageList.map((item) => item.toJson()).toList());
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.DATA_AND_STORAGE, jsonString);
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.TOTAL_SIZE, totalSize.value.toString());
  }

  Future<void> getPhoneStorage(double size) async {
    double diskSpace = 0;
    diskSpace = await DiskSpace.getFreeDiskSpace ?? 0;
    totalPercentage.value = (size / diskSpace) * 100;
    dataStorageList.refresh();
  }

  void showPopup(BuildContext context) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(clearCachePopup),
      confirmText: localized(clearAllCacheAndLogout),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () async => clearAllCache(),
    );
  }

  Future<void> clearAllCache() async {
    if (isClearing.value) return;
    isClearing.value = true;
    await objectMgr.localDB.destroy();
    final database = await getDatabasesPath();
    String databasesPath = "$database/";

    var dbPath = path.join(
        databasesPath, 'data_v014_${objectMgr.userMgr.mainUser.uid}.db');
    await databaseFactory.deleteDatabase(dbPath);

    await AppPath.clearAllPath();

    /// clear local storage
    await objectMgr.localStorageMgr.cleanAll();

    downloadMgrV2.onClearCache();

    await Future.delayed(const Duration(seconds: 1));

    try {
      objectMgr.logout();
    } finally {
      isClearing.value = false;
    }
  }
}

class DataStorageModel {
  String key;
  String? title;
  double? percentage;
  double? size;
  Color? color;

  DataStorageModel({
    required this.key,
    this.title,
    this.percentage,
    this.size,
    this.color,
  });

  factory DataStorageModel.fromJson(Map<String, dynamic> json) {
    return DataStorageModel(
      key: json['key'] ?? '',
      title: json['title'],
      percentage: json['percentage'] ?? 0,
      size: json['size'] ?? [],
      // color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'percentage': percentage,
      'size': size,
      // 'color': color,
    };
  }
}
