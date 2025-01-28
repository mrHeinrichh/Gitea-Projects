import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewController extends GetxController
    with GetTickerProviderStateMixin {
  /// ============================== VARIABLES =================================
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  late TabController selectedAssetTab;
  final RxInt currentTab = 0.obs;

  RxBool isEdit = false.obs;

  RxBool showToolOption = true.obs;

  /// The type can be [File] | [AssetEntity]
  late AssetPreviewDetail currentAsset;

  final ScrollController previewController = ScrollController();
  final RxList<AssetPreviewDetail> currentAssets = <AssetPreviewDetail>[].obs;
  final RxList<AssetPreviewDetail> selectedAssets = <AssetPreviewDetail>[].obs;

  final RxInt selectedAssetCount = 0.obs;

  late AssetPickerProvider provider;
  late AssetPickerConfig pConfig;

  // final RxInt assetCount = 0.obs;

  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocus = FocusNode();

  final RxBool originalSelect = false.obs;

  final bottomBarHeight = 48.0;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>;

    if (!arguments.containsKey('provider') ||
        !arguments.containsKey('pConfig')) {
      Get.back();
      return;
    }

    if (arguments['isEdit'] != null) {
      isEdit.value = true;
    }

    provider = arguments['provider'] as AssetPickerProvider;
    pConfig = arguments['pConfig'] as AssetPickerConfig;

    selectedAssetTab = TabController(
      length: 2,
      vsync: this,
    );

    currentTab.value = selectedAssetTab.index;

    if (arguments.containsKey('isSelectedMode') &&
        arguments['isSelectedMode']) {
      selectedAssetTab.index = 1;
      currentTab.value = 1;
    }

    for (final entity in provider.currentAssets) {
      currentAssets.add(AssetPreviewDetail(
        id: entity.id,
        index: currentAssets.length,
        entity: entity,
      ));
    }

    if (arguments.containsKey('index') && arguments['index'] >= 0) {
      currentPage.value = arguments['index'] as int;
    }

    if (arguments.containsKey('originalSelect')) {
      originalSelect.value = arguments['originalSelect'] as bool;
    }

    if (arguments.containsKey('caption')) {
      captionController.text = arguments['caption'] as String;
    }

    for (int i = 0; i < provider.selectedAssets.length; i++) {
      final element = provider.selectedAssets[i];
      selectedAssets.add(AssetPreviewDetail(
        id: element.id,
        index: i,
        entity: element,
      ));
    }

    selectedAssetCount.value = selectedAssets.length;

    if (arguments.containsKey('index') && arguments['index'] >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(currentPage.value);
        previewController.jumpTo((max(currentPage.value - 3, 0)) * 52.0);
      });
    }

    if (isEdit.value) {
      currentAsset = AssetPreviewDetail(
        id: arguments['entity'].id,
        index: 0,
        entity: arguments['entity'] as AssetEntity,
      );
      selectedAssets.add(currentAsset);
    } else {
      currentAsset = currentAssets[currentPage.value];
    }

    provider.addListener(assetProviderListener);
    selectedAssetTab.addListener(assetTabListener);
    previewController.addListener(previewScrollListener);
    captionController.addListener(inputListener);
  }

  @override
  void onClose() {
    provider.removeListener(assetProviderListener);
    selectedAssetTab.removeListener(assetTabListener);
    previewController.removeListener(previewScrollListener);
    captionController.removeListener(inputListener);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  void assetProviderListener() {
    if (provider.selectedAssets.length != selectedAssetCount.value) {
      if (provider.selectedAssets.length > selectedAssetCount.value) {
        provider.selectedAssets.forEach((asset) {
          int idx =
              currentAssets.indexWhere((element) => element.entity == asset);
          if (idx != -1 && !selectedAssetList.contains(asset)) {
            selectedAssets.add(currentAssets[idx]);
            selectedAssetCount.value++;
          }
        });
      } else {
        for (int i = 0; i < selectedAssetList.length; i++) {
          final element = selectedAssetList.elementAt(i);
          if (!provider.selectedAssets.contains(element)) {
            selectedAssets.removeAt(i);
            selectedAssetCount.value--;

            if (selectedAssets.isEmpty) {
              selectedAssetTab.index = 0;
              currentTab.value = 0;
            }
          }
        }
      }
    }
  }

  void assetTabListener() {
    /// Swap the currentPage index
    if (selectedAssetTab.index != currentTab.value) {
      if (selectedAssetTab.index == 0) {
        final idx = provider.currentAssets.indexOf(currentAsset.entity);
        currentPage.value = idx;
        pageController.jumpToPage(idx);
        previewController.jumpTo(max(idx - 5, 0) * 52.0);
      } else {
        final idx = selectedAssets.indexOf(currentAsset);
        if (idx == -1) {
          currentPage.value = 0;
          pageController.jumpToPage(0);
          return;
        }

        currentPage.value = idx;
        pageController.jumpToPage(idx);
      }
    }
  }

  void previewScrollListener() {
    if (previewController.offset + 150 >
        previewController.position.maxScrollExtent) {
      provider.loadMoreAssets();
    }
  }

  void inputListener() {
    currentAsset.caption = captionController.text;
  }

  /// =============================== METHODS ==================================

  void onPageChanged(BuildContext context, int index) {
    if (currentTab.value == 1) {
      currentAsset = selectedAssets[index];
    } else {
      final entity = provider.currentAssets[index];

      if (selectedAssetList.contains(entity)) {
        final idx = selectedAssetList.toList().indexOf(entity);
        currentAsset = selectedAssets[idx];
      } else {
        currentAsset = AssetPreviewDetail(
          id: entity.id,
          index: index,
          entity: entity,
        );
      }
    }

    update(['selectedAsset', 'captionChanged', 'bottomPanel', 'editButton']
        .toList());

    final double screenWidth = MediaQuery.of(context).size.width;
    final int itemCountInScreen = ((screenWidth - 64) ~/ 52) - 1;
    if (index > itemCountInScreen) {
      previewController.animateTo(
        previewController.offset + (currentPage.value < index ? 52 : -52),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else {
      previewController.animateTo(
        0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }

    currentPage.value = index;
  }

  //preload next two images
  int _cacheRange = 2;

  preloadImage(BuildContext context, int index) {
    List<dynamic> assets = provider.currentAssets;
    for (int i = index - _cacheRange; i < index + _cacheRange; i++) {
      if (i >= assets.length || i < 0) continue;
      final entity = assets[i];
      if (entity.type == AssetType.video) continue;
      AssetPreviewDetail detail;
      if (currentTab.value == 1) {
        detail = selectedAssets[index];
      } else if (selectedAssetList.contains(entity)) {
        final idx = selectedAssetList.toList().indexOf(entity);
        detail = selectedAssets[idx];
      } else {
        detail = AssetPreviewDetail(
          id: entity.id,
          index: index,
          entity: entity,
        );
      }

      final isOriginal = entity.width < 3000 && entity.height < 3000;
      ThumbnailSize? thumbnailSize;
      if (isEdit.value) {
        if (!isOriginal) {
          final ratio = entity.width / entity.height;
          if (entity.width > entity.height) {
            thumbnailSize = ThumbnailSize(2000, 2000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((2000 * ratio).toInt(), 2000);
          }
        }
      } else {
        if (!isOriginal) {
          final ratio = entity.width / entity.height;
          if (entity.width > entity.height) {
            thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
          }
        }
      }

      if (detail.editedFile != null) {
        precacheImage(ExtendedFileImageProvider(detail.editedFile!), context);
      } else {
        precacheImage(
          AssetEntityImageProvider(
            entity,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          context,
          onError: (Object exception, StackTrace? stackTrace) {
            pdebug("#### - Precache failed - " + detail.entity.id);
          },
        );
      }
    }
  }

  void onTabChanged(int index) {
    if (selectedAssetList.isEmpty) {
      selectedAssetTab.index = 0;
      return;
    }

    currentTab.value = index;
  }

  void onAssetTap(int index) {
    pageController.jumpToPage(index);
    currentPage.value = index;
  }

  void onSwitchToolOption() {
    showToolOption.value = !showToolOption.value;
    captionFocus.unfocus();
  }

  void selectAsset(
      BuildContext context, AssetEntity asset, bool isSelected) async {
    if (isEdit.value) return;

    if (provider.selectedAssets.contains(asset)) {
      provider.unSelectAsset(asset);
      final idx = selectedAssetList.toList().indexOf(asset);
      if (idx != -1) {
        selectedAssets.removeAt(idx);
      }

      if (currentTab.value == 1 && currentPage.value >= selectedAssets.length) {
        pageController.jumpToPage(selectedAssets.length - 1);
      }
    } else {
      if (selectedAssetCount.value >= pConfig.maxAssets) {
        showWarningToast(localized(maxImageCount, params: ["9"]));
        return;
      }
      await provider.selectAsset(asset);
    }
    update(['selectedAsset'].toList());
  }

  void editAsset(BuildContext context) async {
    showLoading();
    final AssetPreviewDetail assetDetail = currentTab.value == 1
        ? selectedAssets.toList()[currentPage.value]
        : currentAssets[currentPage.value];
    File? assetFile =
        assetDetail.editedFile ?? await assetDetail.entity.originFile;

    if (isEdit.value) {
      assetFile = currentAsset.editedFile != null
          ? currentAsset.editedFile
          : await currentAsset.entity.originFile;
    }

    if (assetFile == null) {
      Toast.showToast(localized(toastFileFailed));
      return;
    }

    try {
      final newFile = await copyImageFile(assetFile);
      dismissLoading();
      var done = await FlutterPhotoEditor().editImage(newFile.path);

      ui.Image uiImage = await createUiImage(newFile.readAsBytesSync());

      final result = EditorImageResult(
        uiImage.width.toInt(),
        uiImage.height.toInt(),
        newFile,
      );

      if (done) {
        final File file = result.newFile;

        AssetEntity entity;
        if (isEdit.value) {
          currentAsset.editedFile = file;
          currentAsset.editedWidth = result.imgWidth;
          currentAsset.editedHeight = result.imgHeight;

          update(['editedChanged', 'selectedAsset'].toList());
          // when edit completely, save to galley
          ImageGallerySaver.saveFile(newFile.path);
          return;
        }

        if (currentTab.value == 1) {
          entity = selectedAssets[currentPage.value].entity;
        } else {
          entity = provider.currentAssets[currentPage.value];
        }

        // 调整原始数据
        final int idx = currentAssets.indexWhere((a) => a.entity == entity);
        currentAssets[idx].editedFile = file;
        currentAssets[idx].editedWidth = result.imgWidth;
        currentAssets[idx].editedHeight = result.imgHeight;

        double ratio = result.imgWidth / result.imgHeight;

        currentAssets[idx].editedThumbFile = await getThumbImageWithPath(
          file,
          64,
          (64 / ratio).round(),
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'preview_thumbnail',
        );

        if (!provider.selectedAssets.contains(entity)) {
          await provider.selectAsset(entity);
        }

        // 调整已选择数据
        int selectedIdx = provider.selectedAssets.indexOf(entity);
        if (selectedIdx != -1) {
          selectedAssets[selectedIdx].editedFile = file;
          selectedAssets[selectedIdx].editedWidth = result.imgWidth;
          selectedAssets[selectedIdx].editedHeight = result.imgHeight;

          selectedAssets[selectedIdx].editedThumbFile =
              await getThumbImageWithPath(
            file,
            64,
            (64 / ratio).round(),
            savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            sub: 'preview_thumbnail',
          );
        }

        update(['editedChanged', 'selectedAsset'].toList());
        // when edit completely, save to galley
        ImageGallerySaver.saveFile(newFile.path);
      }
    } catch (_) {
      //
    }
  }

  void sendAsset() {
    Get.back(result: <String, dynamic>{
      'assets': selectedAssets.isEmpty
          ? [currentAssets[currentPage.value]]
          : selectedAssets.toList(),
      'originalSelect': originalSelect.value,
      'caption': captionController.text,
      'shouldSend': true,
    });
  }

  void onClickBack() {
    Get.back(result: <String, dynamic>{
      'originalSelect': originalSelect.value,
      'caption': captionController.text,
      'shouldSend': false,
    });
  }

  /// ================================ UTILS ===================================

  Set<AssetEntity> get selectedAssetList =>
      selectedAssets.map<AssetEntity>((p) => p.entity).toSet();
}
