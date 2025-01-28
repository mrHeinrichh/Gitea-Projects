import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AlbumView extends StatefulWidget {
  const AlbumView({
    Key? key,
  }) : super(key: key);

  @override
  State<AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<AlbumView> {
  late String tag;
  bool sendAsFile = false;
  late final CustomInputController controller;

  FocusNode inputFocusNode = FocusNode();
  final RxBool originalSelect = false.obs;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>;
    tag = arguments['tag'];
    if (arguments.containsKey('sendAsFile')) {
      sendAsFile = arguments['sendAsFile'];
    }

    if (arguments.containsKey('originalSelect')) {
      originalSelect.value = arguments['originalSelect'];
    }

    controller = Get.find<CustomInputController>(tag: tag);
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
    Get.close(2);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(result: {
            'originalSelect': originalSelect.value,
            'caption': controller.mediaPickerInputController.text.trim(),
          }),
          child: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).iconTheme.color),
        ),
        title: Text(localized(album)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: controller.assetPickerProvider?.pathsList.keys.length,
              itemBuilder: (BuildContext context, int index) {
                final AssetPathEntity pathEntity = controller
                    .assetPickerProvider!.pathsList.keys
                    .elementAt(index);
                final Uint8List? data = controller
                    .assetPickerProvider?.pathsList.values
                    .elementAt(index);

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    controller.assetPickerProvider!.switchPath(pathEntity);
                    Get.toNamed(RouteName.selectedAlbumView, arguments: {
                      'controller': controller,
                      'sendAsFile': sendAsFile,
                      'originalSelect': originalSelect.value,
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        if (data != null)
                          Image.memory(
                            data,
                            width: 60.0,
                            height: 60.0,
                            fit: BoxFit.cover,
                          ),
                        if (data != null) const SizedBox(width: 5.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.getPathName(pathEntity),
                                style: jxTextStyle.textStyleBold16(
                                    fontWeight: MFontWeight.bold6.value),
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                pathEntity.assetCount.toString(),
                                style: TextStyle(
                                  color: systemColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
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

            GestureDetector(
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
