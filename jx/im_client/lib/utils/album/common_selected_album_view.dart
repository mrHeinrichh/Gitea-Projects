import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/utils/lang_util.dart';

class CommonSelectedAlbumView extends StatefulWidget {
  const CommonSelectedAlbumView({super.key});

  @override
  State<CommonSelectedAlbumView> createState() =>
      _CommonSelectedAlbumViewState();
}

class _CommonSelectedAlbumViewState extends State<CommonSelectedAlbumView> {
  late final CommonAlbumController controller;
  late final String tag;

  @override
  void dispose() {
    controller.assetPickerProvider!.removeListener(onAssetPickerChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    var tag = Get.arguments['tag'];
    var pathEntity = Get.arguments['pathEntity'];
    if (tag != null) {
      controller = Get.find<CommonAlbumController>(tag: Get.arguments['tag']);
      if (pathEntity != null) {
        controller.assetPickerProvider!.switchPath(Get.arguments['pathEntity']);
      }
      controller.assetPickerProvider!.addListener(onAssetPickerChanged);
    }
    current = 0;
  }

  int current = 0;
  onAssetPickerChanged() {
    if (controller.assetPickerProvider!.selectedAssets.isNotEmpty) {
      if (current >= DateTime.now().millisecondsSinceEpoch) return;
      current = DateTime.now().millisecondsSinceEpoch + 1000;
      AssetEntity entity = controller.assetPickerProvider!.selectedAssets.first;
      controller.assetPickerProvider!.selectAsset(entity);
      Get.back(result: entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        leading: GestureDetector(
          onTap: Get.back,
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            alignment: Alignment.center,
            child: Text(
              localized(buttonCancel),
              style: TextStyle(color: themeColor),
            ),
          ),
        ),
        title: Text(
          controller.getPathName(
              context, controller.assetPickerProvider!.currentPath?.path),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AssetPicker<AssetEntity, AssetPathEntity>(
            key: UniqueKey(),
            builder: DefaultAssetPickerBuilderDelegate(
              provider: controller.assetPickerProvider!,
              initialPermission: controller.ps!,
              gridCount: controller.pickerConfig!.gridCount,
              pickerTheme: controller.pickerConfig!.pickerTheme,
              gridThumbnailSize: controller.pickerConfig!.gridThumbnailSize,
              previewThumbnailSize:
                  controller.pickerConfig!.previewThumbnailSize,
              specialPickerType: controller.pickerConfig!.specialPickerType,
              specialItemPosition: controller.pickerConfig!.specialItemPosition,
              specialItemBuilder: controller.pickerConfig!.specialItemBuilder,
              loadingIndicatorBuilder:
                  controller.pickerConfig!.loadingIndicatorBuilder,
              selectPredicate: controller.pickerConfig!.selectPredicate,
              shouldRevertGrid: controller.pickerConfig!.shouldRevertGrid,
              limitedPermissionOverlayPredicate:
                  controller.pickerConfig!.limitedPermissionOverlayPredicate,
              pathNameBuilder: controller.pickerConfig!.pathNameBuilder,
              textDelegate: controller.pickerConfig!.textDelegate,
              themeColor: themeColor,
              locale: Localizations.maybeLocaleOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
