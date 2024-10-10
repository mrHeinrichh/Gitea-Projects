import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as imc;
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class GeneralMediaPicker extends StatefulWidget {
  final DefaultAssetPickerProvider provider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;

  // 展示相册入口
  final bool showAlbumEntry;

  // 是否显示caption输入框
  final bool showCaption;

  // 选择类型是否强限制为一个类型
  final bool typeRestrict;

  // 视频选择时长限制
  final int videoRestrictDuration;

  // 发送回调
  final VoidCallback? onSend;

  const GeneralMediaPicker({
    super.key,
    required this.provider,
    required this.pickerConfig,
    required this.ps,
    this.showAlbumEntry = true,
    this.showCaption = false,
    this.typeRestrict = false,
    this.videoRestrictDuration = -1,
    this.onSend,
  });

  @override
  State<GeneralMediaPicker> createState() => _GeneralMediaPickerState();
}

class _GeneralMediaPickerState extends State<GeneralMediaPicker> {
  bool titleSwap = false;

  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    widget.provider.addListener(assetProviderListener);
  }

  @override
  void dispose() {
    inputController.dispose();
    inputFocusNode.dispose();

    widget.provider.removeListener(assetProviderListener);
    super.dispose();
  }

  void assetProviderListener() async {
    if (widget.provider.selectedAssets.isEmpty) {
      titleSwap = false;
      setState(() {});

      return;
    }

    bool allImage =
        widget.provider.selectedAssets.first.type == AssetType.image;
    final lastAsset = widget.provider.selectedAssets.last;

    if (widget.videoRestrictDuration > -1 &&
        lastAsset.duration > widget.videoRestrictDuration) {
      imBottomToast(
        context,
        title: localized(momentRestrictSelectVideoDuration),
        icon: ImBottomNotifType.warning,
      );
      widget.provider.selectedAssets.remove(lastAsset);
      return;
    }

    if (widget.typeRestrict) {
      final firstAssetType = widget.provider.selectedAssets.first.type;
      final isDifferentType = lastAsset.type != firstAssetType;
      final isVideoConflict = lastAsset.type == AssetType.video &&
          firstAssetType == AssetType.video;
      if (widget.provider.selectedAssets.length > 1 &&
          (isDifferentType || (!allImage && isVideoConflict))) {
        imBottomToast(
          context,
          title: isDifferentType
              ? localized(momentRestrictSelectPhotoAndVideo)
              : localized(momentSelectedOneVideoOnly),
          icon: ImBottomNotifType.warning,
        );
        widget.provider.selectedAssets.remove(lastAsset);
        return;
      }
    }

    titleSwap = true;
    setState(() {});
  }

  void onAssetTap(BuildContext context, int index, AssetEntity asset) async {
    if (widget.provider.selectedAssets.isNotEmpty) {
      bool allImage =
          widget.provider.selectedAssets.first.type == AssetType.image;

      if (widget.typeRestrict) {
        final firstAssetType = widget.provider.selectedAssets.first.type;
        final isDifferentType = asset.type != firstAssetType;
        final isVideoConflict =
            asset.type == AssetType.video && firstAssetType == AssetType.video;
        if ((isDifferentType || (!allImage && isVideoConflict)) && widget.provider.selectedAssets.first.id!=asset.id) {
          imBottomToast(
            context,
            title: isDifferentType
                ? localized(momentRestrictSelectPhotoAndVideo)
                : localized(momentSelectedOneVideoOnly),
            icon: ImBottomNotifType.warning,
          );
          return;
        }
      }
    }

    if (asset.type == AssetType.video &&
        widget.videoRestrictDuration != -1 && asset.duration > widget.videoRestrictDuration) {
      imBottomToast(
        context,
        title: localized(momentRestrictSelectVideoDuration),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'provider': widget.provider,
        'pConfig': widget.pickerConfig,
        'ps': widget.ps,
        'index': index,
        'showCaption': false,
        'videoRestrictDuration': widget.videoRestrictDuration,
      },
    )?.then((result) {
      // if (notBlank(result)) {
      //   widget.onSendTap(result);
      // }

      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        final data = result["assets"] as List<AssetPreviewDetail>;
        final firstAsset = data.first.entity;

        if (widget.videoRestrictDuration != -1 && firstAsset.duration > widget.videoRestrictDuration) {
          imBottomToast(
            context,
            title: localized(momentRestrictSelectVideoDuration),
            icon: ImBottomNotifType.warning,
          );
          return;
        }

        Navigator.of(context).pop(<String, dynamic>{
          ...result,
          'openPreview': false,
        });
      }
    });
  }

  void onAlbumTap() {
    Get.toNamed(
      RouteName.albumView,
      preventDuplicates: false,
      arguments: {
        // 'tag': widget.tag,
        'provider': widget.provider,
        'pConfig': widget.pickerConfig,
        'ps': widget.ps,
        'typeRestrict': widget.typeRestrict,
        'showCaption': widget.showCaption,
        'enableMediaPreview': widget.showAlbumEntry,
        'videoRestrictDuration': widget.videoRestrictDuration,
      },
    )?.then((result) {
      final AssetPathEntity pathEntity = widget.provider.pathsList.keys.first;
      widget.provider.switchPath(pathEntity);

      if (notBlank(result)) {
        if (result!.containsKey('caption')) {
          inputController.text = result['caption'] ?? '';
        }

        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        Get.back(
          result: {
            'shouldSend': true,
            'assets': result['assets'],
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: <Widget>[
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: colorBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorBorder,
                  blurRadius: 0.0,
                  offset: Offset(0.0, -1.0),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: Navigator.of(context).pop,
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
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -1.0),
                            end: const Offset(0.0, 0.0),
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      key: ValueKey(titleSwap),
                      titleSwap
                          ? localized(
                              selectedAssetText,
                              params: [
                                widget.provider.selectedAssets.length
                                    .toString(),
                              ],
                            )
                          : '${localized(select)} ${localized(chatPhoto)}',
                      textAlign: TextAlign.center,
                      style: jxTextStyle.appTitleStyle(
                        color: colorTextPrimary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onAlbumTap,
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
              ],
            ),
          ),
          Expanded(
            child: AssetPicker<AssetEntity, AssetPathEntity>(
              key: Singleton.pickerKey,
              builder: DefaultAssetPickerBuilderDelegate(
                provider: widget.provider,
                initialPermission: widget.ps,
                gridCount: widget.pickerConfig.gridCount,
                pickerTheme: widget.pickerConfig.pickerTheme,
                gridThumbnailSize: widget.pickerConfig.gridThumbnailSize,
                previewThumbnailSize: widget.pickerConfig.previewThumbnailSize,
                specialPickerType: widget.pickerConfig.specialPickerType,
                specialItemPosition: widget.pickerConfig.specialItemPosition,
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
                onAssetTap: (i, a) => onAssetTap(context, i, a),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomCenter,
              curve: Curves.easeOut,
              heightFactor: widget.provider.selectedAssets.isEmpty ? 0.0 : 1.0,
              child: Container(
                padding: EdgeInsets.only(
                  top: 8.0,
                  bottom: MediaQuery.of(context).padding.bottom + 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
                color: colorBackground,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: !widget.showCaption
                          ? const SizedBox()
                          : TextField(
                              contextMenuBuilder: imc.textMenuBar,
                              autocorrect: false,
                              enableSuggestions: false,
                              textAlignVertical: TextAlignVertical.center,
                              textAlign: inputController.text.isNotEmpty ||
                                      inputFocusNode.hasFocus
                                  ? TextAlign.left
                                  : TextAlign.center,
                              maxLines: 10,
                              minLines: 1,
                              focusNode: inputFocusNode,
                              controller: inputController,
                              keyboardType: TextInputType.multiline,
                              scrollPhysics: const ClampingScrollPhysics(),
                              maxLength: 4096,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4096),
                              ],
                              cursorColor: themeColor,
                              style: const TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 16.0,
                                color: Colors.black,
                                height: 1.25,
                                textBaseline: TextBaseline.alphabetic,
                              ),
                              enableInteractiveSelection: true,
                              decoration: InputDecoration(
                                hintText: localized(writeACaption),
                                hintStyle: const TextStyle(
                                  fontSize: 16.0,
                                  color: colorTextSupporting,
                                  fontFamily: appFontfamily,
                                ),
                                isDense: true,
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: const BorderSide(
                                    style: BorderStyle.none,
                                    width: 0,
                                  ),
                                ),
                                isCollapsed: true,
                                counterText: '',
                                contentPadding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                  right: 12,
                                  left: 16,
                                ),
                              ),
                            ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: widget.onSend,
                      child: OpacityEffect(
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(
                            left: 10.0,
                          ),
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.centerRight,
                          child: SvgPicture.asset(
                            'assets/svgs/send_arrow.svg',
                            width: 20,
                            height: 20,
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
}
