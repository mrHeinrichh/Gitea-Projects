import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MomentCreateView extends GetView<MomentCreateController> {
  const MomentCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: PrimaryAppBar(
          isBackButton: false,
          bgColor: colorWhite,
          leading: GestureDetector(
            onTap: Get.back,
            child: OpacityEffect(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 10.0,
                  bottom: 10.0,
                ),
                child: Text(
                  localized(buttonCancel),
                  style: jxTextStyle.textStyle17(),
                ),
              ),
            ),
          ),
          trailing: <Widget>[
            GestureDetector(
              onTap: () => controller.onPublishMoment(context),
              child: OpacityEffect(
                child: Container(
                    margin: const EdgeInsets.only(
                      right: 16.0,
                      top: 9.0,
                      bottom: 6.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 12.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      color: themeColor,
                    ),
                    child: Text(localized(momentBtnStatusPublish),
                      style: jxTextStyle.textStyleBold14(color: colorWhite),
                    ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32.0,
                      right: 32.0,
                      top: 16.0,
                    ),
                    child: TextField(
                      contextMenuBuilder: textMenuBar,
                      controller: controller.momentDescTextController,
                      focusNode: controller.momentDescFocus,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      cursorColor: themeColor,
                      decoration: InputDecoration(
                        hintText: localized(momentCreateHint),
                        hintStyle:
                            jxTextStyle.textStyle17(color: colorTextSupporting),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32.0,
                      right: 32.0,
                      top: 16.0,
                      bottom: 100.0,
                    ),
                    child: Obx(() {
                      // 视频需要根据视频宽高展示对应的组件宽高
                      if (controller.assetList.isNotEmpty &&
                          controller.assetList.first.entity.type ==
                              AssetType.video) {
                        final width =
                            controller.assetList.first.entity.orientatedWidth;
                        final height =
                            controller.assetList.first.entity.orientatedHeight;

                        // 宽高需要设置
                        return KeyedSubtree(
                          key: ValueKey(controller.assetList.first.hashCode),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              controller.onTapImage(0);
                            },
                            child: OpacityEffect(
                              child: Draggable(
                                onDragStarted: () => controller.onReorderStart(context, 0),
                                onDragUpdate: (details) => controller.onItemPointerMove(details),
                                onDragEnd: controller.onItemPointerUp,
                                feedback: _buildVideoAssetItem(
                                  context,
                                  width,
                                  height,
                                  0,
                                ),
                                child: Obx(
                                      () => controller.isDragging.value
                                      ? SizedBox(
                                    width: width > height
                                        ? MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.5
                                        : MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.4,
                                    height: height > width
                                        ? MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.65
                                        : null,
                                  )
                                      : _buildVideoAssetItem(
                                    context,
                                    width,
                                    height,
                                    0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ReorderableGridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemDragEnable: (int index) {
                          return index < controller.assetList.length;
                        },
                        itemCount: min(controller.assetList.length + 1, 9),
                        itemBuilder: (BuildContext context, int index) {
                          if (controller.assetList.isEmpty ||
                              index == controller.assetList.length) {
                            return buildAddEntity(context);
                          }

                          final AssetPreviewDetail assetDetailData =
                              controller.assetList.toList()[index];

                          return KeyedSubtree(
                            key: ValueKey(assetDetailData.hashCode),
                            child: OpacityEffect(
                                child: GestureDetector(
                                  onTap: () {
                                    controller.onTapImage(index);
                                  },
                                  child: Listener(
                                    key: ValueKey(assetDetailData.hashCode),
                                    onPointerMove: controller.onItemPointerMove,
                                    onPointerUp: controller.onItemPointerUp,
                                    behavior: HitTestBehavior.deferToChild,
                                    child:
                                    Obx(() {
                                      return Transform.scale(
                                        scale:
                                        controller.draggedIndex.value == index
                                            ? 1.0
                                            : 1.0,
                                        child: buildImageAssetEntity(
                                          context,
                                          assetDetailData,
                                        ),
                                      );
                                    },
                                    ),
                                  ),
                                ),
                            ),
                          );
                        },
                        onReorder: controller.onAssetReorder,
                        onReorderStart: (i) => controller.onReorderStart(
                          context,
                          i,
                        ),
                      );
                    }),
                  ),
                  const Divider(
                    color: colorTextPlaceholder,
                    height: 1.0,
                  ),
                  _buildMentionTile(context),
                  // const Divider(
                  //   color: colorTextPlaceholder,
                  //   height: 1.0,
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(
                  //     left: 32.0,
                  //     right: 24.0,
                  //     top: 8.0,
                  //     bottom: 8.0,
                  //   ),
                  //   child: Row(
                  //     children: <Widget>[
                  //       SvgPicture.asset(
                  //         'assets/svgs/friend.svg',
                  //         height: 28.0,
                  //         width: 28.0,
                  //       ),
                  //       Expanded(
                  //         child: Padding(
                  //           padding: const EdgeInsets.only(left: 16.0),
                  //           child: Text(
                  //             localized(momentCreateVisible),
                  //             style: jxTextStyle.textStyle16(
                  //                 color: colorTextPrimary),
                  //           ),
                  //         ),
                  //       ),
                  //       Text(
                  //         controller.viewPermission.title,
                  //         style: jxTextStyle.textStyle16(
                  //             color: colorTextSecondary),
                  //       ),
                  //       SvgPicture.asset('assets/svgs/arrow_right.svg',
                  //           height: 28.0,
                  //           width: 28.0,
                  //           colorFilter: const ColorFilter.mode(
                  //             colorTextPlaceholder,
                  //             BlendMode.srcIn,
                  //           )),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).viewPadding.bottom,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: _buildDeleteAssetWidget(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddEntity(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('add_widget'),
      onTap: () => controller.onSelectAssets(context),
      child: OpacityEffect(
        child: Container(
          color: colorBorder,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svgs/add.svg',
            height: 28.0,
            width: 28.0,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAssetItem(
    BuildContext context,
    int width,
    int height,
    int index,
  ) {
    return Transform.scale(
      scale: controller.draggedIndex.value == index ? 1.1 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ExtendedImage(
            image: AssetEntityImageProvider(
              controller.assetList.first.entity,
              isOriginal: true,
            ),
            alignment: Alignment.topLeft,
            width: width > height
                ? MediaQuery.of(context).size.width * 0.5
                : MediaQuery.of(context).size.width * 0.4,
            height: height > width
                ? MediaQuery.of(context).size.width * 0.65
                : null,
            fit: BoxFit.cover,
            mode: ExtendedImageMode.none,
          ),
          SvgPicture.asset(
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget buildImageAssetEntity(BuildContext context, AssetPreviewDetail asset) {
    if (asset.editedFile != null) {
      return RepaintBoundary(
        child: ExtendedImage.file(
          asset.editedFile!,
          gaplessPlayback: true,
          fit: BoxFit.cover,
          cacheRawData: true,
          mode: ExtendedImageMode.none,
        ),
      );
    }

    return ExtendedImage(
      image: AssetEntityImageProvider(
        asset.entity,
        isOriginal: false,
        thumbnailSize: ThumbnailSize.square(Config().messageMin.toInt()),
      ),
      fit: BoxFit.cover,
      mode: ExtendedImageMode.none,
    );
  }

  Widget _buildMentionTile(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.onMentionedFriends();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 32.0,
          right: 24.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Obx(
          () => Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/svgs/at.svg',
                colorFilter: ColorFilter.mode(
                  controller.mentionedFriends.isEmpty
                      ? colorTextPrimary
                      : momentThemeColor,
                  BlendMode.srcIn,
                ),
                height: 28.0,
                width: 28.0,
              ),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: controller.mentionedFriends.isEmpty ? 0 : 1,
                          child: Text(
                            controller.mentionedFriends.isEmpty
                                ? localized(momentMentioned)
                                : localized(momentNotifyViewer),
                            style: jxTextStyle.textStyle16(
                              color: controller.mentionedFriends.isEmpty
                                  ? colorTextPrimary
                                  : momentThemeColor,
                            ),
                          ),
                        ),
                        if (controller.mentionedFriends.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (BuildContext context, int index) {
                                return RichText(
                                  text: TextSpan(
                                    children: <InlineSpan>[
                                      TextSpan(
                                        text: controller
                                            .mentionedFriends[index].nickname,
                                        style: jxTextStyle.textStyle14(
                                          color: colorTextSecondarySolid,
                                        ),
                                      ),
                                      if (index !=
                                          (controller.mentionedFriends.length -
                                              1))
                                        TextSpan(
                                          text: ', ',
                                          style: jxTextStyle.textStyle14(
                                            color: colorTextSecondarySolid,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                              itemCount: controller.mentionedFriends.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/svgs/arrow_right.svg',
                height: 28.0,
                width: 28.0,
                colorFilter: const ColorFilter.mode(
                  colorTextPlaceholder,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAssetWidget(BuildContext context) {
    return Obx(
      () => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.bottomCenter,
        child: controller.isDragging.value
            ? Container(
                color: colorRed.withOpacity(0.95),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(
                  top: 24.0,
                  bottom: 24.0,
                ),
                margin: EdgeInsets.only(
                  bottom: Platform.isAndroid
                      ? MediaQuery.of(context).viewPadding.bottom
                      : 0.0,
                ),
                child: Column(
                  children: <Widget>[
                    SvgPicture.asset(
                      controller.isInDeleteArea.value
                          ? 'assets/svgs/moment_delete_opened_icon.svg'
                          : 'assets/svgs/moment_delete_icon.svg',
                      width: 24.0,
                      height: 24.0,
                      colorFilter: const ColorFilter.mode(
                        colorWhite,
                        BlendMode.srcIn,
                      ),
                    ),
                    Text(
                      localized(
                        controller.isInDeleteArea.value
                            ? momentReleaseToDelete
                            : buttonDelete,
                      ),
                      style: jxTextStyle.textStyle12(
                        color: colorWhite,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
