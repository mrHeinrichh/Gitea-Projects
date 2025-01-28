import 'dart:io';

import 'package:intl/intl.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/utils/paths/app_path.dart';

class DownloadCommon {
  static final DownloadCommon _instance = DownloadCommon._internal();

  DownloadCommon._internal();

  factory DownloadCommon() {
    return _instance;
  }

  Future<(bool, String)> checkLocalFile(String path) async {
    String downloadDir =
        "${AppPath.appDocumentRootPath}/${DownloadConfig().DOWNLOAD_DIR_NAME}";
    String localPath = "$downloadDir/$path";
    return (await File(localPath).exists(), localPath);
  }

  String formattedTime(int timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss.sss')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  String formatedNowTime() {
    return formattedTime(DateTime.now().millisecondsSinceEpoch);
  }

  Future<File> createFile(String filePath) async {
    File file = File(filePath);
    Directory parentDir = file.parent;
    if (await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await file.create(recursive: true, exclusive: false);
    return file;
  }
}
