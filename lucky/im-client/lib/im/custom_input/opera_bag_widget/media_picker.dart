import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../component/media_selector_view.dart';

class MediaPicker extends StatefulWidget {
  final DefaultAssetPickerProvider assetPickerProvider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final String tag;
  final TabController controller;
  final List<AssetEntity> selectedAssets;
  final bool originalSelect;

  final void Function(Map<String, dynamic>? onDoneSelect) onSendTap;

  const MediaPicker({
    Key? key,
    required this.assetPickerProvider,
    required this.pickerConfig,
    required this.ps,
    required this.tag,
    required this.controller,
    required this.selectedAssets,
    required this.originalSelect,
    required this.onSendTap,
  }) : super(key: key);

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
    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'provider': widget.assetPickerProvider,
          'pConfig': widget.pickerConfig,
          'originalSelect': widget.originalSelect,
          'caption': controller.mediaPickerInputController.text,
          'index': index,
        })?.then((result) {
      if (notBlank(result)) {
        widget.onSendTap(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      // color: Colors.white,
      child: Stack(
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
                      specialItemBuilder:
                          widget.pickerConfig.specialItemBuilder,
                      loadingIndicatorBuilder:
                          widget.pickerConfig.loadingIndicatorBuilder,
                      selectPredicate: widget.pickerConfig.selectPredicate,
                      shouldRevertGrid: widget.pickerConfig.shouldRevertGrid,
                      limitedPermissionOverlayPredicate:
                          widget.pickerConfig.limitedPermissionOverlayPredicate,
                      pathNameBuilder: widget.pickerConfig.pathNameBuilder,
                      textDelegate: widget.pickerConfig.textDelegate,
                      themeColor: accentColor,
                      locale: Localizations.maybeLocaleOf(context),
                      onAssetTap: (int index, AssetEntity asset) =>
                          onAssetTap(context, index),
                    ),
                  ),
                  SelectedAssetView(
                    selectedAssets: widget.selectedAssets,
                    provider: widget.assetPickerProvider,
                    pickerConfig: widget.pickerConfig,
                    originalSelect: widget.originalSelect,
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
              decoration: BoxDecoration(
                color: sheetTitleBarColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: dividerColor,
                    blurRadius: 0.0,
                    offset: const Offset(0.0, -1.0),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    cancelWidget(context),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 133),
                          key: ValueKey(widget.selectedAssets.length),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: widget.selectedAssets.isNotEmpty
                              ? assetSelectedTab()
                              : Text(
                                  localized(picture),
                                  style: jxTextStyle.appTitleStyle(
                                      color: JXColors.primaryTextBlack),
                                ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 16.0,
                      child: GestureDetector(
                        onTap: () => Get.toNamed(RouteName.albumView,
                            preventDuplicates: false,
                            arguments: {
                              'tag': widget.tag,
                              'caption':
                                  controller.mediaPickerInputController.text,
                              'originalSelect': widget.originalSelect,
                            })?.then((value) {
                          final AssetPathEntity pathEntity =
                              widget.assetPickerProvider.pathsList.keys.first;
                          widget.assetPickerProvider.switchPath(pathEntity);
                        }),
                        child: OpacityEffect(
                          child: Container(
                            color: Colors.transparent,
                            child: Text(
                              localized(album),
                              style:
                                  jxTextStyle.textStyle17(color: accentColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget assetSelectedTab() {
    return Container(
      height: 30,
      child: TabBar(
        controller: widget.controller,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
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
              '${widget.assetPickerProvider.selectedAssets.length} ${localized(selectedAssetText)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
            ),
          ),
        ],
        indicator: BoxDecoration(
          color: JXColors.bgTertiaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorPadding: const EdgeInsets.all(2),
        indicatorColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 14,
        ),
        labelColor: JXColors.primaryTextBlack,
        unselectedLabelColor: JXColors.secondaryTextBlack,
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
  final bool originalSelect;
  final CustomInputController controller;
  final void Function(Map<String, dynamic>? onDoneSelect) onSendTap;

  const SelectedAssetView({
    super.key,
    required this.selectedAssets,
    required this.provider,
    required this.pickerConfig,
    required this.onSendTap,
    required this.controller,
    this.originalSelect = false,
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
    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'provider': provider,
          'pConfig': pickerConfig,
          'originalSelect': originalSelect,
          'isSelectedMode': true,
          'caption': controller.mediaPickerInputController.text,
          'index': index,
        })?.then((result) {
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
      ],
    );
  }

  Widget selectedBackdrop(
    BuildContext context,
    int currentIndex,
    AssetEntity asset,
  ) {
    final int index = provider.selectedAssets.indexOf(asset);
    final bool selected = index != -1;

    return GestureDetector(
      onTap: () => onAssetTap(context, currentIndex),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? accentColor : Colors.transparent,
            width: 2,
          ),
          color: selected ? Colors.white.withOpacity(0.5) : Colors.transparent,
        ),
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
        color: selected ? accentColor : null,
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
                    fontFamily: appFontfamily),
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
