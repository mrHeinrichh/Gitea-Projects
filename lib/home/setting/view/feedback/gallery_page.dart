import 'package:flutter/material.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/home/setting/view/feedback/ctr_feedback.dart';
import 'package:get/get.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  CtrFeedback controller = Get.find<CtrFeedback>();

  Future<void> onPrepareMediaPicker() async {
    initializePickerConfig();
    initializeAssetPickerProvider();
    final argument = Get.arguments as Map<String, dynamic>;
    if (argument['pathEntity'] != null) {
      await switchAssetPickerPath(argument['pathEntity']);
    }
    addAssetPickerListener();
  }

  void initializePickerConfig() {
    pickerConfig = AssetPickerConfig(
        requestType: RequestType.image,
        limitedPermissionOverlayPredicate: (_) => false,
        shouldRevertGrid: false,
        maxAssets: calculateMaxAssets(),
        selectPredicate: (context, entity, isSelect) async {
          if (!isSelect) {
            final file = await entity.file;
            int? fileSize = file?.lengthSync();

            if (fileSize != null && fileSize <= 5 * 1024 * 1024) {
              return true;
            } else {
              imBottomToast(navigatorKey.currentContext!,
                  title: localized(maxImageSize),
                  icon: ImBottomNotifType.INFORMATION);
              return false;
            }
          }
          return true;
        });
  }

  void initializeAssetPickerProvider() {
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      // selectedAssets: controller.assetPickerProvider?.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );
  }

  int calculateMaxAssets() {
    int count = controller.resultPath.length;
    return 5 - count;
  }

  Future<void> switchAssetPickerPath(AssetPathEntity? pathEntity) async {
    if (pathEntity != null) {
      await assetPickerProvider?.switchPath(pathEntity);
      if (mounted) setState(() {});
    }
  }

  void addAssetPickerListener() {
    assetPickerProvider!.addListener(() {
      updateSelectedAssets();
    });
  }

  Future<void> updateSelectedAssets() async {
    if (controller.selectedAssetList.length !=
        assetPickerProvider!.selectedAssets.length) {
      controller.assetPickerProvider?.selectedAssets =
          assetPickerProvider!.selectedAssets;
      controller.selectedAssetList.value = assetPickerProvider!.selectedAssets;
    }
  }

  @override
  void initState() {
    super.initState();

    onPrepareMediaPicker();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        Get.back();
        controller.selectedAssetList.clear();
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Colors.white,
        body: _buildBody(),
      ),
    );
  }

  PrimaryAppBar _buildAppBar(BuildContext context) {
    return PrimaryAppBar(
      title: localized(album),
      bgColor: Colors.white,
      onPressedBackBtn: () {
        controller.selectedAssetList.clear();
        Get.back();
      },
      trailing: [
        OpacityEffect(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Get.back();
              controller.getAssetPath();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  localized(buttonDone),
                  style: jxTextStyle.textStyle17(
                    color: themeColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return AssetPicker<AssetEntity, AssetPathEntity>(
      key: UniqueKey(),
      builder: _buildAssetPickerBuilderDelegate(),
    );
  }

  DefaultAssetPickerBuilderDelegate _buildAssetPickerBuilderDelegate() {
    return DefaultAssetPickerBuilderDelegate(
      provider: assetPickerProvider!,
      initialPermission: controller.ps!,
      gridCount: pickerConfig!.gridCount,
      pickerTheme: pickerConfig!.pickerTheme,
      gridThumbnailSize: pickerConfig!.gridThumbnailSize,
      previewThumbnailSize: pickerConfig!.previewThumbnailSize,
      loadingIndicatorBuilder: pickerConfig!.loadingIndicatorBuilder,
      selectPredicate: pickerConfig!.selectPredicate,
      shouldRevertGrid: pickerConfig!.shouldRevertGrid,
      limitedPermissionOverlayPredicate:
          pickerConfig!.limitedPermissionOverlayPredicate,
      pathNameBuilder: pickerConfig!.pathNameBuilder,
      textDelegate: pickerConfig!.textDelegate,
      themeColor: themeColor,
      locale: Localizations.maybeLocaleOf(context),
    );
  }

  String getPathName(AssetPathEntity? pathEntity) {
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
