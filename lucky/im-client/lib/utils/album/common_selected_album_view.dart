import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../utils/lang_util.dart';

class CommonSelectedAlbumView extends StatefulWidget {
  const CommonSelectedAlbumView({
    Key? key,
  }) : super(key: key);

  @override
  State<CommonSelectedAlbumView> createState() => _CommonSelectedAlbumViewState();
}

class _CommonSelectedAlbumViewState extends State<CommonSelectedAlbumView> {
  late final CommonAlbumController controller;
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;

  late final String tag;

  Future<void> onPrepareMediaPicker() async {
    pickerConfig = AssetPickerConfig(
      requestType: RequestType.image,
      specialPickerType: SpecialPickerType.noPreview,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      maxAssets: 1,
    );
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: controller.assetPickerProvider?.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );

    final argument = Get.arguments as Map<String, dynamic>;
    if (argument['pathEntity'] != null) {
      assetPickerProvider?.switchPath(argument['pathEntity']).then((_) {
        if (mounted) setState(() {});
      });
    }

    //偵測選取的檔案
    assetPickerProvider!.addListener(() {
      if (controller.selectedAction != null && assetPickerProvider!.selectedAssets.isNotEmpty) {
        controller.selectedAction!(assetPickerProvider!.selectedAssets.first);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    tag = Get.arguments['tag'];
    controller = Get.find<CommonAlbumController>(tag: tag);
    onPrepareMediaPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: GestureDetector(
          onTap: Get.back,
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            alignment: Alignment.center,
            child: Text(
              localized(buttonCancel),
              style: TextStyle(color: accentColor),
            ),
          ),
        ),
        title: Text(
            controller.getPathName(context, assetPickerProvider!.currentPath)),
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
              provider: assetPickerProvider!,
              initialPermission: controller.ps!,
              gridCount: pickerConfig!.gridCount,
              pickerTheme: pickerConfig!.pickerTheme,
              gridThumbnailSize: pickerConfig!.gridThumbnailSize,
              previewThumbnailSize: pickerConfig!.previewThumbnailSize,
              specialPickerType: pickerConfig!.specialPickerType,
              specialItemPosition: pickerConfig!.specialItemPosition,
              specialItemBuilder: pickerConfig!.specialItemBuilder,
              loadingIndicatorBuilder: pickerConfig!.loadingIndicatorBuilder,
              selectPredicate: pickerConfig!.selectPredicate,
              shouldRevertGrid: pickerConfig!.shouldRevertGrid,
              limitedPermissionOverlayPredicate:
              pickerConfig!.limitedPermissionOverlayPredicate,
              pathNameBuilder: pickerConfig!.pathNameBuilder,
              textDelegate: pickerConfig!.textDelegate,
              themeColor: accentColor,
              locale: Localizations.maybeLocaleOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
