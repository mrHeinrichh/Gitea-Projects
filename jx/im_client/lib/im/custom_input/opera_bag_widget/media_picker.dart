import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_tab_bar.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MediaPicker extends StatefulWidget {
  final DefaultAssetPickerProvider assetPickerProvider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final String tag;
  final TabController controller;
  final List<AssetEntity> selectedAssets;

  final void Function(Map<String, dynamic>? onDoneSelect) onSendTap;

  const MediaPicker({
    super.key,
    required this.assetPickerProvider,
    required this.pickerConfig,
    required this.ps,
    required this.tag,
    required this.controller,
    required this.selectedAssets,
    required this.onSendTap,
  });

  @override
  State<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker>
    with AutomaticKeepAliveClientMixin {
  late final CustomInputController controller;
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomInputController>(tag: widget.tag);
  }

  void onAssetTap(BuildContext context, int index) {
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'provider': widget.assetPickerProvider,
        'pConfig': widget.pickerConfig,
        'ps': widget.ps,
        'caption': controller.mediaPickerInputController.text,
        'index': index,
        'chat': controller.chat,
      },
    )?.then((result) {
      if (notBlank(result)) {
        widget.onSendTap(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: <Widget>[
        /// 本体
        Positioned.fill(
          top: 61.5,
          child: PageStorage(
            bucket: bucket,
            child: TabBarView(
              controller: widget.controller,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                AssetPicker<AssetEntity, AssetPathEntity>(
                  key: Singleton.pickerKey,
                  builder: DefaultAssetPickerBuilderDelegate(
                    provider: widget.assetPickerProvider,
                    initialPermission: widget.ps,
                    gridCount: widget.pickerConfig.gridCount,
                    pickerTheme: widget.pickerConfig.pickerTheme,
                    gridThumbnailSize: widget.pickerConfig.gridThumbnailSize,
                    previewThumbnailSize:
                        widget.pickerConfig.previewThumbnailSize,
                    specialPickerType: widget.pickerConfig.specialPickerType,
                    specialItemPosition:
                        widget.pickerConfig.specialItemPosition,
                    specialItemBuilder: widget.pickerConfig.specialItemBuilder,
                    loadingIndicatorBuilder:
                        widget.pickerConfig.loadingIndicatorBuilder,
                    selectPredicate: widget.pickerConfig.selectPredicate,
                    shouldRevertGrid: widget.pickerConfig.shouldRevertGrid,
                    limitedPermissionOverlayPredicate:
                        widget.pickerConfig.limitedPermissionOverlayPredicate,
                    pathNameBuilder: widget.pickerConfig.pathNameBuilder,
                    textDelegate: widget.pickerConfig.textDelegate,
                    themeColor: themeColor,
                    locale: Localizations.maybeLocaleOf(context),
                    onAssetTap: (int index, AssetEntity asset) =>
                        onAssetTap(context, index),
                  ),
                ),
                SelectedAssetView(
                  selectedAssets: widget.selectedAssets,
                  provider: widget.assetPickerProvider,
                  pickerConfig: widget.pickerConfig,
                  onSendTap: widget.onSendTap,
                  controller: controller,
                ),
              ],
            ),
          ),
        ),
        // appBar
        Positioned(
          left: 0.0,
          right: 0.0,
          top: 1.5,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              color: colorBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 24,
                        ),
                        child: Text(
                          localized(cancel),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ),
                widget.selectedAssets.isNotEmpty
                    ? assetSelectedTab()
                    : Text(
                        localized(picture),
                        key: UniqueKey(),
                        textAlign: TextAlign.center,
                        style: jxTextStyle.appTitleStyle(
                          color: colorTextPrimary,
                        ),
                      ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(
                      RouteName.albumView,
                      preventDuplicates: false,
                      arguments: {
                        'provider': widget.assetPickerProvider,
                        'pConfig': widget.pickerConfig,
                        'ps': widget.ps,
                        'tag': widget.tag,
                        'caption': controller.mediaPickerInputController.text,
                        'chat': controller.chat,
                      },
                    )?.then((result) {
                      final PathWrapper<AssetPathEntity> pathEntity =
                          widget.assetPickerProvider.paths.first;
                      widget.assetPickerProvider.switchPath(pathEntity);

                      if (notBlank(result)) {
                        if (result!.containsKey('caption')) {
                          controller.mediaPickerInputController.text =
                              result['caption'] ?? '';
                        }

                        if (!result.containsKey('shouldSend') ||
                            !result['shouldSend']) {
                          return;
                        }

                        widget.onSendTap(result);
                      }
                    }),
                    child: OpacityEffect(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24, right: 16),
                        color: Colors.transparent,
                        child: Text(
                          localized(album),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget assetSelectedTab() {
    List<String> tabList = [
      localized(all),
      localized(
        widget.assetPickerProvider.selectedAssets.length > 1
            ? selectedAssetTexts
            : selectedAssetText,
        params: [
          widget.assetPickerProvider.selectedAssets.length.toString(),
        ],
      ),
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorBackground6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTabBar(
        tabController: widget.controller,
        tabList: tabList,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SelectedAssetView extends StatelessWidget {
  final List<AssetEntity> selectedAssets;
  final AssetPickerProvider provider;
  final AssetPickerConfig pickerConfig;
  final CustomInputController controller;
  final void Function(Map<String, dynamic>? onDoneSelect) onSendTap;

  const SelectedAssetView({
    super.key,
    required this.selectedAssets,
    required this.provider,
    required this.pickerConfig,
    required this.onSendTap,
    required this.controller,
  });

  bool get isSingleAssetMode => provider.maxAssets == 1;

  void selectAsset(BuildContext context, AssetEntity asset, bool selected) {
    if (isSingleAssetMode) {
      provider.selectedAssets.clear();
    }

    if (provider.selectedAssets.contains(asset)) {
      provider.unSelectAsset(asset);
    } else {
      provider.selectAsset(asset);
    }
  }

  void onAssetTap(BuildContext context, int index) {
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'provider': provider,
        'pConfig': pickerConfig,
        'isSelectedMode': true,
        'caption': controller.mediaPickerInputController.text,
        'asset': provider.selectedAssets[index],
        'chat': controller.chat,
      },
    )?.then((result) {
      if (notBlank(result)) {
        onSendTap(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 1.0,
        ),
        itemCount: selectedAssets.length,
        itemBuilder: (BuildContext context, int index) {
          final AssetEntity asset = selectedAssets[index];
          return imageAndVideoItemBuilder(
            context,
            index,
            asset,
          );
        },
      ),
    );
  }

  Widget imageAndVideoItemBuilder(
    BuildContext context,
    int index,
    AssetEntity asset,
  ) {
    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      asset,
      isOriginal: false,
      thumbnailSize: pickerConfig.gridThumbnailSize,
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            child: AssetEntityGridItemBuilder(
              key: ValueKey(asset.id),
              image: imageProvider,
              failedItemBuilder: failedItemBuilder,
            ),
          ),
        ),
        selectedBackdrop(context, index, asset),
        selectIndicator(context, index, asset),
        itemBannedIndicator(context, asset),
        if (asset.type == AssetType.video) videoIndicator(context, asset),
      ],
    );
  }

  Widget selectedBackdrop(
    BuildContext context,
    int currentIndex,
    AssetEntity asset,
  ) {
    return GestureDetector(
      onTap: () => onAssetTap(context, currentIndex),
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  Widget selectIndicator(
    BuildContext context,
    int currentIndex,
    AssetEntity asset,
  ) {
    final double indicatorSize =
        context.mediaQuery.size.width / pickerConfig.gridCount / 3;
    final Duration duration = const Duration(milliseconds: 300) * 0.75;

    final bool selected =
        provider.selectedDescriptions.contains(asset.toString());
    final int selectIndex = provider.selectedAssets.indexOf(asset);
    final Widget innerSelector = AnimatedContainer(
      duration: duration,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: Colors.white,
        ),
        color: selected ? themeColor : null,
        shape: BoxShape.circle,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        child: selected
            ? Text(
                '${selectIndex + 1}',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  fontSize: 16,
                  height: Platform.isIOS ? 1.15 : 1.3,
                  fontWeight: MFontWeight.bold5.value,
                  fontFamily: appFontfamily,
                ),
                textAlign: TextAlign.center,
              )
            : const SizedBox.shrink(),
      ),
    );
    final Widget selectorWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => selectAsset(context, asset, selected),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: indicatorSize,
        height: indicatorSize,
        alignment: AlignmentDirectional.topEnd,
        child: (isSingleAssetMode && !selected)
            ? const SizedBox.shrink()
            : isSingleAssetMode
                ? const SizedBox.shrink()
                : innerSelector,
      ),
    );

    return PositionedDirectional(
      top: 0,
      end: 0,
      child: selectorWidget,
    );
  }

  Widget itemBannedIndicator(BuildContext context, AssetEntity asset) {
    final bool isDisabled = !provider.selectedAssets.contains(asset) &&
        provider.selectedMaximumAssets;
    if (isDisabled) {
      return Container(
        color: Colors.white.withOpacity(.85),
      );
    }
    return const SizedBox.shrink();
  }

  Widget videoIndicator(BuildContext context, AssetEntity asset) {
    return PositionedDirectional(
      end: 8,
      bottom: 8,
      child: Container(
        height: 20,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: const Color(0xff121212).withOpacity(0.48),
        ),
        child: Text(
          Singleton.textDelegate.durationIndicatorBuilder(
            Duration(seconds: asset.duration),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
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
}
