import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';

class SelectedAlbumView extends StatefulWidget {
  const SelectedAlbumView({
    Key? key,
  }) : super(key: key);

  @override
  State<SelectedAlbumView> createState() => _SelectedAlbumViewState();
}

class _SelectedAlbumViewState extends State<SelectedAlbumView> {
  late final CustomInputController controller;
  bool sendAsFile = false;

  FocusNode inputFocusNode = FocusNode();

  final RxBool originalSelect = false.obs;
  ValueNotifier<List<AssetEntity>> selectedAssets = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    controller = Get.arguments['controller'];

    if (Get.arguments.containsKey('sendAsFile')) {
      sendAsFile = Get.arguments['sendAsFile'];
    }

    if (Get.arguments.containsKey('originalSelect')) {
      originalSelect.value = Get.arguments['originalSelect'];
    }
  }

  void onSendTap({Map<String, dynamic>? result}) async {
    if (notBlank(result)) {
      if (result!.containsKey('originalSelect')) {
        originalSelect.value = result['originalSelect'] ?? false;
      }

      if (result.containsKey('caption')) {
        controller.mediaPickerInputController.text = result['caption'] ?? '';
      }

      if (!result.containsKey('shouldSend') || !result['shouldSend']) {
        return;
      }
    }

    await controller.onSend(
      controller.mediaPickerInputController.text.isEmpty
          ? null
          : controller.mediaPickerInputController.text.trim(),
      assets: result != null
          ? (result['assets'] ?? <AssetPreviewDetail>[])
          : <AssetPreviewDetail>[],
      isOriginalImageSend: originalSelect.value,
      sendAsFile: sendAsFile,
    );
    Get.close(3);
    return;
  }

  void onAssetTap(BuildContext context, int index) async {
    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'provider': controller.assetPickerProvider,
          'pConfig': controller.pickerConfig,
          'originalSelect': originalSelect.value,
          'caption': controller.mediaPickerInputController.text,
          'index': index,
        })?.then((result) {
      if (notBlank(result)) {
        onSendTap(result: result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: GestureDetector(
          onTap: () => Get.back(
            result: {
              'originalSelect': originalSelect.value,
              'caption': controller.mediaPickerInputController.text.trim(),
            },
          ),
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            alignment: Alignment.center,
            child: Text(
              localized(buttonBack),
              style: TextStyle(color: accentColor),
            ),
          ),
        ),
        title: Text(
          controller.getPathName(
            controller.assetPickerProvider!.currentPath,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
            child: AssetPicker<AssetEntity, AssetPathEntity>(
              key: UniqueKey(),
              builder: DefaultAssetPickerBuilderDelegate(
                provider: controller.assetPickerProvider!,
                initialPermission: controller.ps!,
                gridCount: controller.pickerConfig!.gridCount,
                pickerTheme: controller.pickerConfig!.pickerTheme,
                gridThumbnailSize: controller.pickerConfig!.gridThumbnailSize,
                previewThumbnailSize:
                    controller.pickerConfig!.previewThumbnailSize,
                specialPickerType: controller.pickerConfig!.specialPickerType,
                specialItemPosition:
                    controller.pickerConfig!.specialItemPosition,
                specialItemBuilder: controller.pickerConfig!.specialItemBuilder,
                loadingIndicatorBuilder:
                    controller.pickerConfig!.loadingIndicatorBuilder,
                selectPredicate: controller.pickerConfig!.selectPredicate,
                shouldRevertGrid: controller.pickerConfig!.shouldRevertGrid,
                limitedPermissionOverlayPredicate:
                    controller.pickerConfig!.limitedPermissionOverlayPredicate,
                pathNameBuilder: controller.pickerConfig!.pathNameBuilder,
                textDelegate: controller.pickerConfig!.textDelegate,
                themeColor: accentColor,
                locale: Localizations.maybeLocaleOf(context),
                onAssetTap: (int index, AssetEntity asset) =>
                    onAssetTap(context, index),
              ),
            ),
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomCenter,
              curve: Curves.easeOut,
              child: Container(
                padding: EdgeInsets.only(
                  top: 8.0,
                  bottom: MediaQuery.of(context).padding.bottom + 8.0,
                ),
                color: iOSSystemColor,
                child: Column(children: assetInput()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> assetInput() {
    if (!controller.sendState.value) return [const SizedBox()];

    return [
      // Show caption
      Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 8.0,
        ),
        child: TextField(
          contextMenuBuilder: textMenuBar,
          autocorrect: false,
          enableSuggestions: false,
          textAlignVertical: TextAlignVertical.center,
          textAlign: controller.mediaPickerInputController.text.isNotEmpty ||
                  inputFocusNode.hasFocus
              ? TextAlign.left
              : TextAlign.center,
          enabled: !(controller.fileList.length > 1),
          maxLines: 10,
          minLines: 1,
          focusNode: inputFocusNode,
          controller: controller.mediaPickerInputController,
          keyboardType: TextInputType.multiline,
          scrollPhysics: const ClampingScrollPhysics(),
          selectionControls: controller.txtSelectControl,
          maxLength: 4096,
          inputFormatters: [
            LengthLimitingTextInputFormatter(4096),
          ],
          cursorColor: accentColor,
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
            hintStyle: TextStyle(
              fontSize: 16.0,
              color: JXColors.supportingTextBlack,
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

      // Selected
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /// View Button
            GestureDetector(
              onTap: () {
                final selectedIdx;
                if (controller.assetPickerProvider!.selectedAssets.isNotEmpty) {
                  selectedIdx = controller.assetPickerProvider!.currentAssets
                      .indexOf(
                          controller.assetPickerProvider!.selectedAssets.first);
                } else {
                  selectedIdx = 0;
                }

                onAssetTap(context, selectedIdx);
              },
              child: OpacityEffect(
                child: Text(
                  localized(previewImage),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),

            Offstage(
              offstage: sendAsFile,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => originalSelect.value = !originalSelect.value,
                child: Obx(
                  () => OpacityEffect(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CheckTickItem(
                            isCheck: originalSelect.value,
                          ),
                        ),
                        Text(
                          localized(original),
                          style: jxTextStyle.textStyleBold16(
                              color: JXColors.primaryTextBlack,
                              fontWeight: MFontWeight.bold6.value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Send Button
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: controller.sendState.value
                  ? () => onSendTap(result: {
                        'originalSelect': originalSelect.value,
                        'caption':
                            controller.mediaPickerInputController.text.trim(),
                        'shouldSend': true,
                      })
                  : null,
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
                    width: 20,
                    height: 20,
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
