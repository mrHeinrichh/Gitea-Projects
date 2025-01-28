import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as imc;
import 'package:jxim_client/im/services/media/media_utils.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SelectedAlbumView extends StatefulWidget {
  const SelectedAlbumView({
    super.key,
  });

  @override
  State<SelectedAlbumView> createState() => _SelectedAlbumViewState();
}

class _SelectedAlbumViewState extends State<SelectedAlbumView> {
  Chat? chat;

  // 资源选择器
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;

  RxBool sendState = false.obs;

  // 是否是从朋友圈进入
  bool isMoment = false;

  bool showCaption = true;
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

  bool showResolution = true;
  bool enableMediaPreview = true;

  // 是否限制类型
  bool typeRestrict = false;

  // 视频时长限制
  int videoRestrictDuration = -1;

  @override
  void initState() {
    super.initState();
    assetPickerProvider = Get.arguments['provider'];
    pickerConfig = Get.arguments['pConfig'];
    ps = Get.arguments['ps'];

    if (assetPickerProvider!.selectedAssets.isNotEmpty) {
      sendState.value = true;
    }

    if (Get.arguments.containsKey('showCaption')) {
      showCaption = Get.arguments['showCaption'];
    }

    if (Get.arguments.containsKey('caption')) {
      inputController.text = Get.arguments['caption'] as String;
    }

    if (Get.arguments.containsKey('showResolution')) {
      showResolution = Get.arguments['showResolution'];
    }

    if (Get.arguments.containsKey('enableMediaPreview')) {
      enableMediaPreview = Get.arguments['enableMediaPreview'];
    }

    if (Get.arguments.containsKey('typeRestrict')) {
      typeRestrict = Get.arguments['typeRestrict'];
    }

    if (Get.arguments.containsKey('chat')) {
      chat = Get.arguments['chat'];
    }

    if (Get.arguments.containsKey('videoRestrictDuration')) {
      videoRestrictDuration = Get.arguments['videoRestrictDuration'];
    }

    assetPickerProvider!.addListener(onAssetPickerChanged);
  }

  @override
  void dispose() {
    assetPickerProvider!.removeListener(onAssetPickerChanged);
    super.dispose();
  }

  void onAssetPickerChanged() {
    if (assetPickerProvider!.selectedAssets.isEmpty) {
      sendState.value = false;
      return;
    }

    bool allImage =
        assetPickerProvider!.selectedAssets.first.type == AssetType.image;
    final lastAsset = assetPickerProvider!.selectedAssets.last;

    if (typeRestrict &&
        ((allImage && lastAsset.type != AssetType.image) ||
            (!allImage && lastAsset.type == AssetType.image))) {
      imBottomToast(
        context,
        title: localized(momentRestrictSelectPhotoAndVideo),
        icon: ImBottomNotifType.warning,
      );
      assetPickerProvider!.selectedAssets.remove(lastAsset);
      return;
    }

    sendState.value = true;
  }

  void onAssetTap(BuildContext context, int index) async {
    if (!enableMediaPreview) return;
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'provider': assetPickerProvider,
        'pConfig': pickerConfig,
        'caption': inputController.text,
        'showCaption': showCaption,
        'showResolution': showResolution,
        'chat': chat,
        'index': index,
        'videoRestrictDuration': videoRestrictDuration,
      },
    )?.then((result) {
      if (notBlank(result)) {
        if (result!.containsKey('caption')) {
          inputController.text = result['caption'] ?? '';
        }

        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        Get.back(
          result: {
            'caption': showCaption ? inputController.text.trim() : null,
            'assets': result['assets'] ?? <AssetPreviewDetail>[],
            'shouldSend': true,
            'translation': result['translation'],
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        leading: GestureDetector(
          onTap: () => Get.back(
            result: {
              'caption': showCaption ? inputController.text.trim() : null,
            },
          ),
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            alignment: Alignment.center,
            child: OpacityEffect(
              child: Text(
                localized(buttonBack),
                style: jxTextStyle.textStyle17(color: themeColor),
              ),
            ),
          ),
        ),
        title: Text(
          getPathName(
            assetPickerProvider!.currentPath?.path,
          ),
          style: const TextStyle(
            fontSize: 18.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AssetPicker<AssetEntity, AssetPathEntity>(
              key: UniqueKey(),
              builder: DefaultAssetPickerBuilderDelegate(
                provider: assetPickerProvider!,
                initialPermission: ps!,
                gridCount: pickerConfig!.gridCount,
                pickerTheme: pickerConfig!.pickerTheme,
                gridThumbnailSize: pickerConfig!.gridThumbnailSize,
                previewThumbnailSize: pickerConfig!.previewThumbnailSize,
                specialPickerType: pickerConfig!.specialPickerType,
                specialItemPosition: pickerConfig!.specialItemPosition,
                specialItemBuilder: pickerConfig!.specialItemBuilder,
                loadingIndicatorBuilder: pickerConfig!.loadingIndicatorBuilder,
                selectPredicate: pickerConfig!.selectPredicate,
                shouldRevertGrid: pickerConfig!.shouldRevertGrid,
                limitedPermissionOverlayPredicate:
                    pickerConfig!.limitedPermissionOverlayPredicate,
                pathNameBuilder: pickerConfig!.pathNameBuilder,
                textDelegate: pickerConfig!.textDelegate,
                themeColor: themeColor,
                locale: Localizations.maybeLocaleOf(context),
                onAssetTap: (int index, AssetEntity asset) =>
                    onAssetTap(context, index),
              ),
            ),
          ),
          Obx(
            () => ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.bottomCenter,
                curve: Curves.easeOut,
                heightFactor: !sendState.value ? 0.0 : 1.0,
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
                        child: !showCaption
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
                      // Send Button
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => Get.back(
                          result: {
                            'caption': showCaption
                                ? inputController.text.trim()
                                : null,
                            'shouldSend': true,
                          },
                        ),
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
                              color: themeColor,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
