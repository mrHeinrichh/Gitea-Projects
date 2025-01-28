import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/services/media/media_utils.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AlbumView extends StatefulWidget {
  const AlbumView({
    super.key,
  });

  @override
  State<AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<AlbumView> {
  // 资源选择器
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;

  bool showCaption = true;
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

  bool enableMediaPreview = true;

  bool typeRestrict = false;

  bool sendAsFile = false;

  Chat? chat;

  int videoRestrictDuration = -1;

  @override
  void initState() {
    super.initState();

    final arguments = Get.arguments as Map<String, dynamic>;

    if (!arguments.containsKey('provider') ||
        !arguments.containsKey('pConfig')) {
      Get.back();
      return;
    }

    assetPickerProvider = arguments['provider'] as DefaultAssetPickerProvider;
    pickerConfig = arguments['pConfig'] as AssetPickerConfig;
    ps = arguments['ps'] as PermissionState;

    if (arguments.containsKey('showCaption')) {
      showCaption = arguments['showCaption'] as bool;
    }

    if (arguments.containsKey('caption')) {
      inputController.text = arguments['caption'] as String;
    }

    if (arguments.containsKey('chat')) {
      chat = arguments['chat'] as Chat;
    }

    if (arguments.containsKey('enableMediaPreview')) {
      enableMediaPreview = arguments['enableMediaPreview'] as bool;
    }

    if (arguments.containsKey('typeRestrict')) {
      typeRestrict = arguments['typeRestrict'] as bool;
    }

    if (arguments.containsKey('sendAsFile')) {
      sendAsFile = arguments['sendAsFile'] as bool;
    }

    if (arguments.containsKey('videoRestrictDuration')) {
      videoRestrictDuration = arguments['videoRestrictDuration'] as int;
    }
  }

  void onSelectedAlbumTap(PathWrapper<AssetPathEntity> pathEntity) async {
    assetPickerProvider!.switchPath(pathEntity);
    Get.toNamed(
      RouteName.selectedAlbumView,
      arguments: {
        'provider': assetPickerProvider,
        'pConfig': pickerConfig,
        'ps': ps,
        'typeRestrict': typeRestrict,
        'showCaption': showCaption,
        'caption': inputController.text,
        'enableMediaPreview': enableMediaPreview,
        'sendAsFile': sendAsFile,
        'chat': chat,
        'videoRestrictDuration': videoRestrictDuration,
      },
    )?.then((result) {
      if (notBlank(result)) {
        if (result!.containsKey('caption')) {
          inputController.text = result['caption'] ?? '';
        }

        if (mounted) setState(() {});

        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        Get.back(
          result: {
            'caption': showCaption ? inputController.text.trim() : null,
            'assets': result['assets'] ?? <AssetPreviewDetail>[],
            'shouldSend': true,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(
            result: {
              'caption': showCaption ? inputController.text.trim() : null,
            },
          ),
          child: OpacityEffect(
            child: Icon(
              Icons.arrow_back_ios,
              color: themeColor,
            ),
          ),
        ),
        title: Text(localized(album)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: assetPickerProvider!.isAssetsEmpty
          ? Center(
              child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                SvgPicture.asset(
                  'assets/svgs/noPermission_state_photo.svg',
                  width: 148,
                  height: 148,
                ),
                const SizedBox(height: 16),
                Text(
                  localized(chatEmptyList),
                  style: jxTextStyle.textStyleBold16(),
                ),
              ],
            ))
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: assetPickerProvider?.paths.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PathWrapper<AssetPathEntity> pathEntity =
                          assetPickerProvider!.paths.elementAt(index);
                      final Uint8List? data = assetPickerProvider?.paths
                          .elementAt(index)
                          .thumbnailData;

                      if (pathEntity.assetCount == 0) {
                        return const SizedBox.shrink();
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onSelectedAlbumTap(pathEntity),
                        child: OverlayEffect(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getPathName(pathEntity.path),
                                        style: jxTextStyle.textStyleBold16(
                                          fontWeight: MFontWeight.bold6.value,
                                        ),
                                      ),
                                      const SizedBox(height: 5.0),
                                      Text(
                                        pathEntity.assetCount.toString(),
                                        style: const TextStyle(
                                          color: colorTextSecondary,
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
                        ),
                      );
                    },
                  ),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.bottomCenter,
                    curve: Curves.easeOut,
                    heightFactor:
                        assetPickerProvider!.selectedAssets.isEmpty ? 0.0 : 1.0,
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
                                    contextMenuBuilder: textMenuBar,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textAlignVertical: TextAlignVertical.center,
                                    textAlign:
                                        inputController.text.isNotEmpty ||
                                                inputFocusNode.hasFocus
                                            ? TextAlign.left
                                            : TextAlign.center,
                                    maxLines: 10,
                                    minLines: 1,
                                    focusNode: inputFocusNode,
                                    controller: inputController,
                                    keyboardType: TextInputType.multiline,
                                    scrollPhysics:
                                        const ClampingScrollPhysics(),
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
                                        borderRadius:
                                            BorderRadius.circular(30.0),
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
              ],
            ),
    );
  }
}
