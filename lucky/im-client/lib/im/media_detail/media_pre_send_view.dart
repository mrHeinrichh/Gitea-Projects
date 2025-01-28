import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MediaPreSendView extends GetView<MediaPreSendViewController> {
  const MediaPreSendView({super.key});

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
                      onTap: Get.back,
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
                  ),
                ),
              ),
            ),
            Obx(
              () => AnimatedPositioned(
                bottom: 0.0 + (controller.showToolOption.value ? 0.0 : -250.0),
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

  Widget buildPreview(BuildContext context) {
    return GetBuilder(
      init: controller,
      id: 'editedChanged',
      builder: (_) {
        return PhotoViewGallery.builder(
          itemCount: 1,
          // onPageChanged: (i) => controller.onPageChanged(context, i),
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
      },
    );
  }

  Widget assetPreviewBuilder(BuildContext context, int index) {
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
        key: ValueKey(controller.filePath.value),
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

    return buildAnimatedExtendedImage(File(controller.filePath.value!));
  }

  List<Widget> assetInput(BuildContext context) {
    return [
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
          }),
      Container(
        width: MediaQuery.of(context).size.width,
        height: controller.bottomBarHeight,
        padding:
            const EdgeInsets.only(left: 16.0, right: 16, top: 4.0, bottom: 4.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => controller.editAsset(),
              child: OpacityEffect(
                child: Image.asset(
                  'assets/images/pen_edit2.png',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ),
            OpacityEffect(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.sendAsset,
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        color: accentColor,
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(6.0),
                        child: SvgPicture.asset(
                          'assets/svgs/send_arrow.svg',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
