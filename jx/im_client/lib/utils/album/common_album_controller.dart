import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CommonAlbumController extends GetxController {
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;
  bool isFromSelectedAlbumn = false;

  /*
  * 共用相冊配置
  * maxAssets: 最大點選數量
  * pickerType: 資源選擇類型(預設圖片)
  * */
  Future<bool> onPrepareMediaPicker({
    int maxAssets = 1,
    RequestType pickerType = RequestType.image,
  }) async {
    isFromSelectedAlbumn = false;
    ps = await requestAssetPickerPermission();
    if (ps == PermissionState.denied) return false;

    pickerConfig = AssetPickerConfig(
      requestType: pickerType,
      specialPickerType: SpecialPickerType.noPreview,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: 1,
      textDelegate: Get.locale!.languageCode.contains('en')
          ? const EnglishAssetPickerTextDelegate()
          : const AssetPickerTextDelegate(),
    );
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: pickerConfig!.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );

    current = 0;
    assetPickerProvider!.addListener(onAssetPickerChanged);

    return true;
  }

  int current = 0;
  onAssetPickerChanged() {
    if (isFromSelectedAlbumn) return;
    if (assetPickerProvider!.selectedAssets.isNotEmpty) {
      if (current >= DateTime.now().millisecondsSinceEpoch) return;
      current = DateTime.now().millisecondsSinceEpoch + 1000;
      Get.back();
    }
  }

  @override
  void onClose() {
    assetPickerProvider?.removeListener(onAssetPickerChanged);
    super.onClose();
  }

  // 资源路径多语言翻译
  String getPathName(BuildContext context, AssetPathEntity? pathEntity) {
    switch (pathEntity?.id) {
      // 最近
      case "isAll":
        return localized(recent);
      //截屏
      case "1028075469":
        return localized(screenshots);
      //电影
      case "-1730634595":
        return localized(movies);
      //文件夹
      case "-792647906":
        return localized(documents);
      //拍照
      case "-1739773001":
        return localized(camera);
      //图片
      case "-1617409521":
        return localized(picture);
      //截屏记录
      case "455968004":
        return localized(screenRecording);
      //下载
      case "540528482":
        return localized(downloads);
      default:
        return pathEntity?.name ?? '';
    }
  }
}
