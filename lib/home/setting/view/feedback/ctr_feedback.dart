import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/api/account.dart' as api;
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/utils/lang_util.dart';

class CtrFeedback extends GetxController {
  final List<SelectionOptionModel> photoOption = [
    SelectionOptionModel(
      title: localized(takeAPhoto),
    ),
    SelectionOptionModel(
      title: localized(chooseFromGalley),
    ),
  ];

  final List<SelectionOptionModel> category = [
    SelectionOptionModel(
      title: localized(homeChat),
    ),
    SelectionOptionModel(
      title: localized(homeContact),
    ),
    SelectionOptionModel(
      title: localized(homeSetting),
    ),
    SelectionOptionModel(
      title: localized(others),
    ),
  ];

  Rx<int> selectedIndex = Rx(-1);
  final value = ''.obs;

  DefaultAssetPickerProvider? assetPickerProvider;
  PermissionState? ps;

  final selectedAssetList = <AssetEntity>[].obs;
  final descriptionController = TextEditingController();
  final descriptionWordCount = 1000.obs;
  final resultPath = <String>[].obs;
  final isLoading = false.obs;

  bool get isEnable =>
      selectedIndex.value != -1 &&
      descriptionWordCount.value < 1000 &&
      notBlank(descriptionController.text.trim());

  @override
  void onInit() {
    super.onInit();
    assetPickerProvider = DefaultAssetPickerProvider();
    const AssetPickerDelegate().permissionCheck().then((value) => ps = value);
  }

  void getAssetPath() async {
    for (final entity in selectedAssetList) {
      final file = await entity.file;
      resultPath.add(file!.path);
    }
  }

  void getDescriptionWordCount() {
    int count = 0;
    if (descriptionController.text.isNotEmpty) {
      for (int i = 0; i < descriptionController.text.characters.length; i++) {
        count += 1;
      }
    }
    descriptionWordCount.value = 1000 - count;
  }

  Future<List<String>> uploadImage() async {
    List<String> imagePath = [];
    for (int i = 0; i < resultPath.length; i++) {
      CancelToken cancelToken = CancelToken();

      final String? imageUrl = await imageMgr.upload(
        resultPath[i],
        0,
        0,
        cancelToken: cancelToken,
      );

      if (notBlank(imageUrl)) {
        imagePath.add(imageUrl!);
      }
    }
    return imagePath;
  }

  void submitFeedback() async {
    isLoading(true);
    FocusManager.instance.primaryFocus?.unfocus();

    List<String> attachments = [];
    if (resultPath.isNotEmpty) {
      attachments = await uploadImage();
    }
    try {
      final result = await api.feedback(
          getCategory(), descriptionController.text, attachments);
      if (result) {
        Get.back();
        Get.toNamed(RouteName.completedFeedback);
      }
    } catch (e) {
      pdebug('Error when Feedback');
      isLoading(false);
    }
  }

  String getCategory() {
    switch (selectedIndex.value) {
      case 0:
        return 'chat';
      case 1:
        return 'contact';
      case 2:
        return 'settings';
      case 3:
        return 'others';
      default:
        return 'others';
    }
  }
}
