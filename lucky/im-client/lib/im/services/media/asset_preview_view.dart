import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/services/media/asset_preview_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewView extends GetView<AssetPreviewController> {
  const AssetPreviewView({super.key});

  bool keyboardEnabled(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 200;

  @override
  Widget build(BuildContext context) {
    double appBarHeight =
        kToolbarHeight + MediaQuery.of(context).viewPadding.top;

    return GestureDetector(
      onTap: controller.captionFocus.unfocus,
      child: Scaffold(
        backgroundColor: JXColors.black,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: <Widget>[
            buildPreview(context),
            Obx(
              () => AnimatedPositioned(
                top: 0.0 +
                    (controller.showToolOption.value ? 0.0 : -appBarHeight),
                left: 0.0,
                right: 0.0,
                duration: const Duration(milliseconds: 170),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).viewPadding.top,
                  ),
                  height: appBarHeight,
                  color: JXColors.mediaBarBg,
                  child: NavigationToolbar(
                    leading: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: controller.onClickBack,
                      child: OpacityEffect(
                        child: SizedBox(
                          width: 90,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  localized(buttonBack),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.25,
                                    fontFamily: appFontfamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    centerMiddle: true,
                    middle: assetSelectedTab(context),
                    trailing: GetBuilder(
                      init: controller,
                      id: 'selectedAsset',
                      builder: (_) {
                        return selectedBackdrop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Obx(
              () => AnimatedPositioned(
                bottom: 0.0 + (controller.showToolOption.value ? 0.0 : -300.0),
                left: 0.0,
                right: 0.0,
                duration: const Duration(milliseconds: 170),
                child: Container(
                  padding: EdgeInsets.only(
                    top: controller.showToolOption.value ? 6.0 : 0.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? max(
                            MediaQuery.of(context).viewInsets.bottom,
                            MediaQuery.of(context).viewPadding.bottom,
                          )
                        : MediaQuery.of(context).viewPadding.bottom,
                  ),
                  color: JXColors.mediaBarBg,
                  child: Column(children: <Widget>[...assetInput(context)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget assetSelectedTab(BuildContext context) {
    return Obx(() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: controller.isEdit.value || controller.selectedAssets.isEmpty
            ? const SizedBox()
            : Container(
                height: 30,
                child: TabBar(
                  controller: controller.selectedAssetTab,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  onTap: controller.onTabChanged,
                  tabs: <Tab>[
                    Tab(
                      child: Text(
                        localized(all),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        '${controller.selectedAssets.length} ${localized(selectedAssetText)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  indicator: BoxDecoration(
                    color: JXColors.bgSecondaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  indicatorPadding: const EdgeInsets.all(2),
                  indicatorColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                  ),
                  labelColor: JXColors.white,
                  unselectedLabelColor: JXColors.white.withOpacity(0.48),
                ),
              ),
      );
    });
  }

  Widget selectedBackdrop(BuildContext context) {
    final AssetEntity asset;
    final bool isSelected;
    final int index;

    if (controller.isEdit.value) {
      asset = controller.currentAsset.entity;
      isSelected = true;
      index = 0;
    } else {
      if (controller.currentTab.value == 1) {
        asset = controller.selectedAssets[controller.currentPage.value].entity;
      } else {
        asset = controller.provider.currentAssets[controller.currentPage.value];
      }
      isSelected = controller.selectedAssetList.contains(asset);
      index = controller.selectedAssetList.toList().indexOf(asset);
    }

    const Duration duration = Duration(milliseconds: 200);

    final Widget innerSelector = !controller.isEdit.value
        ? AnimatedContainer(
            duration: duration,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 30 / 25,
              ),
              color: isSelected ? accentColor : null,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: duration,
              reverseDuration: duration,
              child: isSelected
                  ? Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontSize: 16,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          )
        : const SizedBox();
    return OpacityEffect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.selectAsset(context, asset, isSelected),
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 35,
          height: 35,
          alignment: AlignmentDirectional.topEnd,
          child: innerSelector,
        ),
      ),
    );
  }

  Widget buildPreview(BuildContext context) {
    return GetBuilder(
        init: controller,
        id: 'editedChanged',
        builder: (_) {
          return Obx(() {
            return PhotoViewGallery.builder(
              pageController: controller.pageController,
              itemCount: controller.isEdit.value
                  ? 1
                  : controller.currentTab.value == 1
                      ? controller.selectedAssets.length
                      : controller.currentAssets.length,
              onPageChanged: (i) => controller.onPageChanged(context, i),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions.customChild(
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4.1,
                  gestureDetectorBehavior: HitTestBehavior.deferToChild,
                  onTapDown: (_, __, ___) {
                    controller.onSwitchToolOption();
                  },
                  child: assetPreviewBuilder(context, index),
                );
              },
            );
          });
        });
  }

  Widget assetPreviewBuilder(BuildContext context, int index) {
    final entity = controller.currentAsset.entity;
    // precacheImage(ExtendedFileImageProvider(file), context)
    controller.preloadImage(context, index);

    Widget? loadStateChanged(ExtendedImageState state) {
      Widget buildFail(ExtendedImageState state) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              const Text(
                '加载失败',
                style: TextStyle(color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () {
                  state.reLoadImage();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }

      switch (state.extendedImageLoadState) {
        case LoadState.loading:
          return const Center(child: CircularProgressIndicator());
        case LoadState.completed:
          return null; // 默认显示图片
        case LoadState.failed:
          return buildFail(state);
        default:
          return null;
      }
    }

    Widget buildAnimatedExtendedImage(File file) {
      return TweenAnimationBuilder(
        key: ValueKey(file.path),
        duration: const Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1),
        builder: (BuildContext context, num value, Widget? child) {
          return Opacity(
            opacity: value.toDouble(),
            child: RepaintBoundary(
              child: ExtendedImage.file(
                file,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.none,
                loadStateChanged: loadStateChanged,
              ),
            ),
          );
        },
      );
    }

    if (controller.isEdit.value) {
      if (controller.currentAsset.editedFile != null) {
        return buildAnimatedExtendedImage(controller.currentAsset.editedFile!);
      } else {
        if (entity.type == AssetType.video) {
          return VideoPageBuilder(asset: entity);
        }

        final isOriginal = entity.width < 3000 && entity.height < 3000;

        ThumbnailSize? thumbnailSize;
        BoxFit boxFit =
            entity.width > entity.height ? BoxFit.fitWidth : BoxFit.fitHeight;
        if (!isOriginal) {
          final ratio = entity.width / entity.height;
          if (entity.width > entity.height) {
            thumbnailSize = ThumbnailSize(2000, 2000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((2000 * ratio).toInt(), 2000);
          }
        }

        return RepaintBoundary(
          child: ExtendedImage(
            image: AssetEntityImageProvider(
              entity,
              isOriginal: isOriginal,
              thumbnailSize: thumbnailSize,
            ),
            fit: BoxFit.contain,
            mode: ExtendedImageMode.none,
          ),
        );
      }
    }

    final AssetEntity asset;
    if (controller.currentTab.value == 1) {
      asset = controller.selectedAssets[index].entity;

      if (controller.selectedAssets[index].editedFile != null) {
        return buildAnimatedExtendedImage(
            controller.selectedAssets[index].editedFile!);
      }
    } else {
      asset = controller.provider.currentAssets[index];
      final int idx = controller.currentAssets
          .indexWhere((element) => element.entity == asset);

      if (idx != -1 && controller.currentAssets[idx].editedFile != null) {
        return buildAnimatedExtendedImage(
          controller.currentAssets[idx].editedFile!,
        );
      }
    }

    if (asset.type == AssetType.image) {
      final isOriginal = asset.width < 3000 && asset.height < 3000;

      ThumbnailSize? thumbnailSize;
      if (!isOriginal) {
        final ratio = asset.width / asset.height;
        if (asset.width > asset.height) {
          thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
        } else {
          thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
        }
      }

      return RepaintBoundary(
        child: ExtendedImage(
          image: AssetEntityImageProvider(
            asset,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          fit: BoxFit.contain,
          mode: ExtendedImageMode.none,
        ),
      );
    } else {
      return VideoPageBuilder(asset: asset);
    }
  }

  Widget failedItemBuilder(BuildContext context) {
    return Center(
      child: Text(
        localized(loadFailed),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  bool get isSelected =>
      (controller.currentTab.value == 0 &&
          controller.selectedAssetList.contains(controller
              .provider.currentAssets[controller.currentPage.value])) ||
      (controller.currentTab.value == 1 &&
          controller.selectedAssetList.contains(
              controller.selectedAssets[controller.currentPage.value].entity));

  bool get cAssetGreaterThanCPage =>
      controller.provider.currentAssets.length > controller.currentPage.value;

  bool get isImage =>
      (controller.currentTab.value == 0 &&
          cAssetGreaterThanCPage &&
          controller
                  .provider.currentAssets[controller.currentPage.value].type !=
              AssetType.image) ||
      (controller.currentTab.value == 1 &&
          controller.selectedAssets[controller.currentPage.value].entity.type !=
              AssetType.image);

  bool get isEditImage =>
      controller.isEdit.value &&
      controller.currentAsset.entity.type != AssetType.image;

  List<Widget> assetInput(BuildContext context) {
    return [
      // Show Asset List
      if (!controller.isEdit.value)
        SizedBox(
          height: 60.0,
          child: GetBuilder(
            init: controller,
            id: 'editedChanged',
            builder: (_) {
              return Obx(
                () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16.0),
                  controller: controller.previewController,
                  itemCount: controller.currentTab.value == 1
                      ? controller.selectedAssets.length
                      : controller.currentAssets.length,
                  itemBuilder: (BuildContext context, int index) {
                    return buildThumbnailPreview(context, index);
                  },
                ),
              );
            },
          ),
        ),

      // Show caption
      GetBuilder(
        init: controller,
        id: 'captionChanged',
        builder: (_) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: TextField(
                contextMenuBuilder: textMenuBar,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                textAlign: controller.captionController.text.isNotEmpty ||
                        controller.captionFocus.hasFocus
                    ? TextAlign.left
                    : TextAlign.center,
                maxLines: 4,
                minLines: 1,
                focusNode: controller.captionFocus,
                controller: controller.captionController,
                keyboardType: TextInputType.multiline,
                scrollPhysics: const ClampingScrollPhysics(),
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: Colors.white,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 16.0,
                  color: JXColors.white,
                  height: 1.25,
                  textBaseline: TextBaseline.alphabetic,
                ),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: localized(writeACaption),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: keyboardEnabled(context)
                        ? JXColors.white
                        : JXColors.white.withOpacity(0.6),
                    height: 1.25,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  isDense: true,
                  fillColor: JXColors.white.withOpacity(0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isCollapsed: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                onTapOutside: (event) {
                  controller.captionFocus.unfocus();
                },
              ),
            ),
          );
        },
      ),
      Stack(
        children: [
          GetBuilder(
            init: controller,
            id: 'bottomPanel',
            builder: (_) {
              return Positioned(
                child: Obx(
                  () => Container(
                    height: controller.bottomBarHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IntrinsicWidth(
                          child: OpacityEffect(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => controller.originalSelect.value =
                                  !controller.originalSelect.value,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: CheckTickItem(
                                      isCheck: controller.originalSelect.value,
                                      borderColor: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    localized(original),
                                    style: jxTextStyle.textStyleBold16(
                                        color: JXColors.white,
                                        fontWeight: MFontWeight.bold6.value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: controller.bottomBarHeight,
            padding: const EdgeInsets.only(
                left: 0, right: 16, top: 4.0, bottom: 4.0),
            margin: const EdgeInsets.only(bottom: 6.0),
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GetBuilder(
                  init: controller,
                  id: 'editButton',
                  builder: (_) {
                    return controller.currentAsset.entity.type !=
                            AssetType.video
                        ? Obx(() {
                            return Offstage(
                              offstage: (!controller.isEdit.value && isImage) ||
                                  isEditImage,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => controller.editAsset(context),
                                child: OpacityEffect(
                                  child: Container(
                                    width: 60,
                                    padding: EdgeInsets.only(left: 16),
                                    alignment: Alignment.centerLeft,
                                    child: Image.asset(
                                      'assets/images/pen_edit2.png',
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                        : SizedBox();
                  },
                ),
                // GestureDetector(
                //   onTap: () {
                //     ///TODO::handel重拍行為
                //   },
                //   child: Padding(
                //       padding: const EdgeInsets.all(10.0),
                //       child: Text(
                //         localized(retake),
                //         style: jxTextStyle.textStyle16(color: Colors.white),
                //         ),
                //   ),
                // ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.sendAsset,
                  child: OpacityEffect(
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(
                        left: 10.0,
                        right: 0.0,
                      ),
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: SvgPicture.asset(
                        'assets/svgs/send_arrow.svg',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget buildThumbnailPreview(BuildContext context, int index) {
    AssetPreviewDetail? assetPreviewDetail;
    final bool hasEditedFile;
    final AssetEntity asset;
    if (controller.currentTab.value == 1) {
      asset = controller.selectedAssets[index].entity;
      assetPreviewDetail = controller.selectedAssets[index];
      hasEditedFile = controller.selectedAssets[index].editedFile != null;
    } else {
      asset = controller.provider.currentAssets[index];
      final int assetIdx = controller.currentAssets
          .indexWhere((element) => element.entity == asset);
      if (assetIdx != -1) {
        assetPreviewDetail = controller.currentAssets[assetIdx];
        hasEditedFile = controller.currentAssets[assetIdx].editedFile != null;
      } else {
        hasEditedFile = false;
      }
    }

    return Obx(
      () {
        final List<String> ids =
            controller.selectedAssets.map<String>((e) => e.entity.id).toList();
        bool isSelected = ids.contains(asset.id);

        return GestureDetector(
          onTap: () => controller.onAssetTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            margin: EdgeInsets.only(
              right: 4.0,
              bottom: controller.currentPage.value == index ? 0.0 : 4.0,
              top: controller.currentPage.value == index ? 0.0 : 4.0,
            ),
            child: ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                child: Stack(
                  children: <Widget>[
                    if (hasEditedFile && assetPreviewDetail != null)
                      RepaintBoundary(
                        child: ExtendedImage.file(
                          assetPreviewDetail.editedFile!,
                          width: controller.currentPage.value == index
                              ? 60.0
                              : 48.0,
                          height: controller.currentPage.value == index
                              ? 60.0
                              : 48.0,
                          fit: BoxFit.cover,
                          clipBehavior: Clip.antiAlias,
                          mode: ExtendedImageMode.none,
                        ),
                      )
                    else
                      RepaintBoundary(
                        child: ExtendedImage(
                          width: controller.currentPage.value == index
                              ? 60.0
                              : 48.0,
                          height: controller.currentPage.value == index
                              ? 60.0
                              : 48.0,
                          image: AssetEntityImageProvider(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize(64, 64),
                          ),
                          fit: BoxFit.cover,
                          clipBehavior: Clip.antiAlias,
                          mode: ExtendedImageMode.none,
                        ),
                      ),
                    if (isSelected)
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          color: isSelected
                              ? Colors.black.withOpacity(0.4)
                              : Colors.transparent,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
