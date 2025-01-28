import 'dart:io';

import 'package:disk_space/disk_space.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../utils/color.dart';
import '../../../utils/utility.dart';
import '../../../views/component/custom_confirmation_popup.dart';

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

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> getTotalSize() async {
    ///media size
    final document = await getApplicationDocumentsDirectory();
    int avatarSize =
        getTotalUsage("${document.path.toString()}/download/avatar/");
    int groupSize =
        getTotalUsage("${document.path.toString()}/download/group/");
    int imageSize =
        getTotalUsage("${document.path.toString()}/download/Image/");
    int videoSize =
        getTotalUsage("${document.path.toString()}/download/Video/");
    int stickerSize =
        getTotalUsage("${document.path.toString()}/download/sticker/");
    mediaSize =
        bytesToMB(avatarSize + groupSize + imageSize + videoSize + stickerSize);

    /// file size
    fileSize = bytesToMB(
        getTotalUsage("${document.path.toString()}/download/Document/"));

    /// text == database
    final databaseDir = await getDatabasesPath();
    int dbSize = await getDatabaseFileSize(
        "$databaseDir/data_v014_${objectMgr.userMgr.mainUser.uid}.db");
    textSize = bytesToMB(dbSize);

    /// other + cache
    final cache = await getTemporaryDirectory();
    int cacheSize = getTotalUsage("${cache.path.toString()}/");
    otherSize = bytesToMB(
        ((getTotalUsage("${document.path.toString()}/download/") -
                    mediaSize -
                    fileSize) +
                cacheSize)
            .toInt());

    /// total size
    totalSize.value = mediaSize + fileSize + textSize + otherSize;

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

    getPhoneStorage(totalSize.value);
  }

  Future<void> getPhoneStorage(double size) async {
    double diskSpace = 0;
    diskSpace = await DiskSpace.getFreeDiskSpace ?? 0;
    totalPercentage.value = (size / diskSpace) * 100;
  }

  void showPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          subTitle: localized(clearCachePopup),
          confirmButtonText: localized(clearAllCacheAndLogout),
          cancelButtonText: localized(buttonCancel),
          confirmButtonColor: errorColor,
          cancelButtonColor: accentColor,
          confirmCallback: () async => clearAllCache(),
          cancelCallback: () => Get.back(),
        );
      },
    );
  }

  Future<void> clearAllCache() async {
    isClearing.value = true;
    final database = await getDatabasesPath();
    String databasesPath = "$database/";

    var dbPath = path.join(
        databasesPath, 'data_v014_${objectMgr.userMgr.mainUser.uid}.db');
    await databaseFactory.deleteDatabase(dbPath);

    Directory documentDir = await getApplicationDocumentsDirectory();
    Directory cacheDir = await getTemporaryDirectory();

    clearDirectory(documentDir);
    clearDirectory(cacheDir);

    Future.delayed(const Duration(seconds: 2),(){
      objectMgr.logout();
    });
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
}
