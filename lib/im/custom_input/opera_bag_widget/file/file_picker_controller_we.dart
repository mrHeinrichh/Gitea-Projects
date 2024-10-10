import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/share_mgr.dart';

import 'package:jxim_client/utils/file_utils.dart';

class FilePickerController extends GetxController {
  final RxList<RecentFile> selectedList = <RecentFile>[].obs;

  final TextEditingController fileNameController = TextEditingController();

  List<Directory> storages = [];
  List<RecentFile> recentFilesList = [];
  final pageSize = 50;
  final isInit = false.obs;
  final isLoading = false.obs;
  Map<String, int> curFilePos = {};

  @override
  void onInit() {
    super.onInit();
    FileUtils.curDirPath = '';
    FileUtils.curFileList = [];
  }

  void loadAndroidFiles() async {
    if (isLoading.value || Platform.isIOS || recentFilesList.isNotEmpty) return;

    isLoading.value = true;
    isInit.value = true;

    List<RecentFile> files = await objectMgr.shareMgr.recentFilePaths;
    if (files.isNotEmpty) {
      recentFilesList.addAll(files);
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    recentFilesList.clear();
    super.onClose();
  }
}
