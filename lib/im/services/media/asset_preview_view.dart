import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/im/custom_input/chat_translate_bar.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/im/services/media/asset_preview_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewView extends GetView<AssetPreviewController> {
  const AssetPreviewView({super.key});

  bool keyboardEnabled(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 200;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onTap: controller.captionFocus.unfocus,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Obx(
                () {
                  if (controller.coverFilePath.value is AssetEntity) {
                    return PhotoView(
                      image: AssetEntityImageProvider(
                        controller.coverFilePath.value,
                      ),
                      fit: BoxFit.contain,
                      constraints: const BoxConstraints.expand(),
                    );
                  } else if (controller.coverFilePath.value is File) {
                    return PhotoView.file(
                      controller.coverFilePath.value,
                      fit: BoxFit.contain,
                      constraints: const BoxConstraints.expand(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              buildPreview(context),
              Positioned(
                top: 0.0,
                right: 0.0,
                left: 0.0,
                child: GetBuilder(
                  init: controller,
                  id: 'selectedAsset',
                  builder: (_) {
                    return selectedBackdrop(context);
                  },
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Column(
                  children: [
                    if (!controller.isEdit.value)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOutCubic,
                        opacity: keyboardEnabled(context) ? 0.0 : 1.0,
                        child: Obx(
                          () => Row(
                            children: <Widget>[
                              const Spacer(),
                              AnimatedContainer(
                                alignment: Alignment.center,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOutCubic,
                                width: controller.selectedAssets.isNotEmpty
                                    ? 32.0
                                    : 0.0,
                                height: controller.selectedAssets.isNotEmpty
                                    ? 32.0
                                    : 0.0,
                                margin: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorBorder,
                                  border: controller.selectedAssets.isNotEmpty
                                      ? Border.all(
                                          color: colorWhite,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: controller.selectedAssets.isNotEmpty
                                    ? AnimatedFlipCounter(
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: colorWhite,
                                        ),
                                        value: controller.selectedAssets.length,
                                      )
                                    : const SizedBox(),
                              )
                            ],
                          ),
                        ),
                      ),
                    Container(
                      color: Colors.black.withOpacity(0.8),
                      padding: EdgeInsets.only(
                        top: controller.showTranslateBar.value ? 0 : 10.0,
                        bottom: MediaQuery.of(context).viewInsets.bottom > 0
                            ? max(
                                MediaQuery.of(context).viewInsets.bottom,
                                MediaQuery.of(context).viewPadding.bottom,
                              )
                            : MediaQuery.of(context).viewPadding.bottom,
                      ),
                      child: Column(
                        children: <Widget>[
                          if (controller.showCaption)
                            Obx(
                              () => Visibility(
                                visible: controller.showTranslateBar.value,
                                child: ChatTranslateBar(
                                  isTranslating: controller.isTranslating.value,
                                  translatedText:
                                      controller.translatedText.value,
                                  chat: controller.chat!,
                                  translateLocale:
                                      controller.translateLocale.value,
                                  isDetailView: true,
                                ),
                              ),
                            ),
                          ...assetInput(context)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget selectedBackdrop(BuildContext context) {
    if (controller.isEdit.value) return const SizedBox();

    final AssetEntity asset;
    final bool isSelected;
    final int index;

    asset = controller.currentAssets[controller.currentPage.value].entity;

    isSelected =
        controller.selectedAssets.indexWhere((e) => e.id == asset.id) != -1;
    index = controller.selectedAssetList.toList().indexOf(asset);

    const Duration duration = Duration(milliseconds: 200);

    final Widget innerSelector = AnimatedContainer(
      duration: duration,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 30 / 25,
        ),
        color: isSelected ? themeColor : null,
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
    );
    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top + 10.0,
        right: 12.0,
        bottom: 10.0,
      ),
      child: OpacityEffect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.selectAsset(context, asset, isSelected),
          child: Container(
            width: 32,
            height: 32,
            alignment: AlignmentDirectional.topEnd,
            child: innerSelector,
          ),
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
            if (controller.currentAssets.isNotEmpty) {
              return PhotoViewGesturePageView.builder(
                scrollDirection: Axis.horizontal,
                controller: controller.pageController,
                itemCount: controller.currentAssets.length,
                onPageChanged: (i) => controller.onPageChanged(context, i),
                itemBuilder: (BuildContext context, int index) {
                  return assetPreviewBuilder(context, index);
                },
              );
            }
            return assetPreviewBuilder(context, 0);
          });
        });
  }

  Widget onPhotoViewLoadStateChanged(PhotoViewState state) {
    if (state.extendedImageLoadState == PhotoViewLoadState.completed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.coverFilePath.value = '';
      });
    }
    return photoLoadStateChanged(
      state,
      isTransition: true,
      loadingItemBuilder: () => const SizedBox.shrink(),
    );
  }

  Widget assetPreviewBuilder(BuildContext context, int index) {
    controller.preloadImage(context, index);

    final entity = controller.currentAssets[index].entity;

    if (controller.isEdit.value) {
      if (controller.currentAsset.editedFile != null) {
        return RepaintBoundary(
          child: PhotoView.file(
            controller.currentAsset.editedFile!,
            fit: BoxFit.contain,
            mode: PhotoViewMode.gesture,
            initGestureConfigHandler: initGestureConfigHandler,
            loadStateChanged: onPhotoViewLoadStateChanged,
          ),
        );
      } else {
        final isOriginal = entity.type == AssetType.video ||
            (entity.width < 3000 && entity.height < 3000);

        ThumbnailSize? thumbnailSize;

        if (!isOriginal) {
          final ratio = entity.width / entity.height;
          if (entity.width > entity.height) {
            thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 2000);
          }
        }

        return Stack(
          children: <Widget>[
            if (entity.type == AssetType.video)
              VideoPageBuilder(
                asset: entity,
                onLoadCallback: (bool hasLoaded) {
                  imCamera.dismissPage(keepVideo: false);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    controller.videoHasLoaded.value = hasLoaded;
                  });
                },
              ),
            Obx(() {
              if (!controller.videoHasLoaded.value) {
                return Positioned.fill(
                  child: RepaintBoundary(
                    child: PhotoView(
                      image: AssetEntityImageProvider(
                        entity,
                        isOriginal: isOriginal,
                        thumbnailSize: thumbnailSize,
                      ),
                      fit: BoxFit.contain,
                      mode: PhotoViewMode.gesture,
                      initGestureConfigHandler: initGestureConfigHandler,
                      loadStateChanged: (PhotoViewState state) {
                        if (controller.isClosing) {
                          return;
                        }
                        if (state.extendedImageLoadState ==
                            PhotoViewLoadState.completed) {
                          imCamera.dismissPage(keepVideo: false);
                        }
                        return null;
                      },
                    ),
                  ),
                );
              }

              return const SizedBox();
            }),
          ],
        );
      }
    }

    if (controller.currentAssets[index].editedFile != null) {
      return RepaintBoundary(
        child: PhotoView.file(
          controller.currentAssets[index].editedFile!,
          fit: BoxFit.contain,
          mode: PhotoViewMode.gesture,
          initGestureConfigHandler: initGestureConfigHandler,
          loadStateChanged: onPhotoViewLoadStateChanged,
        ),
      );
    }

    if (entity.type == AssetType.image) {
      final isOriginal = entity.width < 3000 && entity.height < 3000;

      ThumbnailSize? thumbnailSize;
      if (!isOriginal) {
        final ratio = entity.width / entity.height;
        if (entity.width > entity.height) {
          thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
        } else {
          thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
        }
      }
      return RepaintBoundary(
        child: PhotoView(
          image: AssetEntityImageProvider(
            entity,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          fit: BoxFit.contain,
          mode: PhotoViewMode.gesture,
          initGestureConfigHandler: initGestureConfigHandler,
          loadStateChanged: onPhotoViewLoadStateChanged,
        ),
      );
    } else {
      return VideoPageBuilder(
        asset: entity,
        onLoadCallback: (hasLoaded) {
          if (!controller.videoHasLoaded.value) {
            controller.videoHasLoaded.value = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              controller.update(['editedChanged']);
            });
          }
        },
      );
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

  List<Widget> assetInput(BuildContext context) {
    return [
      if (controller.showCaption)
        GetBuilder(
          init: controller,
          id: 'captionChanged',
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        contextMenuBuilder: textMenuBar,
                        autocorrect: false,
                        enableSuggestions: false,
                        textAlignVertical: TextAlignVertical.center,
                        textAlign:
                            controller.captionController.text.isNotEmpty ||
                                    controller.captionFocus.hasFocus
                                ? TextAlign.left
                                : TextAlign.center,
                        maxLines: keyboardEnabled(context) ? 4 : 1,
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
                          color: colorWhite,
                          height: 1.25,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          hintText: localized(writeACaption),
                          hintStyle: TextStyle(
                            fontSize: 16.0,
                            color: keyboardEnabled(context)
                                ? colorWhite
                                : colorWhite.withOpacity(0.6),
                            height: 1.25,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                          isDense: true,
                          fillColor: colorWhite.withOpacity(0.2),
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
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOutCubic,
                    height: keyboardEnabled(context) ? 32.0 : 0.0,
                    width: keyboardEnabled(context) ? 32.0 : 0.0,
                    margin: EdgeInsets.only(
                        right: keyboardEnabled(context) ? 12.0 : 0.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorWhite,
                    ),
                    child: keyboardEnabled(context)
                        ? const Icon(
                            Icons.done,
                            color: Colors.black,
                            size: 22,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          },
        ),
      if (!keyboardEnabled(context))
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 10.0,
          ),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: controller.onClickBack,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorWhite,
                      width: 2.0,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/Back.svg',
                    width: 14,
                    height: 14,
                    color: colorWhite,
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => Row(
                    mainAxisAlignment: controller
                                .currentAssets[controller.currentPage.value]
                                .entity
                                .type !=
                            AssetType.image
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          child: controller
                                      .currentAssets[
                                          controller.currentPage.value]
                                      .entity
                                      .type ==
                                  AssetType.image
                              ? GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => controller.editAsset(context),
                                  child: OpacityEffect(
                                    child: Image.asset(
                                      'assets/images/pen_edit2.png',
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const SizedBox()),
                      if (controller.showResolution)
                        AnimatedAlign(
                          alignment: Alignment.center,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: !controller.shouldShowHighResolution
                                ? null
                                : () => controller.onChangeResolution(context),
                            child: GetBuilder(
                              init: controller,
                              id: 'resolutionChanged',
                              builder: (_) {
                                bool isVideo =
                                    controller.currentAsset.entity.type ==
                                        AssetType.video;

                                bool isHighResolution = isVideo
                                    ? controller.currentAsset.videoResolution ==
                                        MediaResolution.video_high
                                    : controller.currentAsset.imageResolution ==
                                        MediaResolution.image_high;

                                return OpacityEffect(
                                  isDisabled:
                                      !controller.shouldShowHighResolution,
                                  child: SvgPicture.asset(
                                    isHighResolution
                                        ? 'assets/svgs/hd_filled_rounded.svg'
                                        : 'assets/svgs/hd_outlined_rounded.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.sendAsset,
                child: OpacityEffect(
                  child: Container(
                    height: 32.0,
                    width: 32.0,
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: SvgPicture.asset(
                      'assets/svgs/send_arrow.svg',
                      width: 24.0,
                      height: 24.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
