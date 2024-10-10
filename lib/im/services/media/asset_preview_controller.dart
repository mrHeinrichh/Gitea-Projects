import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/im/services/media/media_resolution_selection.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/unescape_util.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewController extends GetxController
    with GetTickerProviderStateMixin {
  late final PhotoViewPageController pageController;
  final RxInt currentPage = 0.obs;

  RxBool isEdit = false.obs;
  RxBool videoHasLoaded = false.obs;
  RxBool isFromPhoto = false.obs;

  RxBool showTranslateBar = false.obs;
  RxBool isTranslating = false.obs;
  RxString translatedText = ''.obs;
  RxString translateLocale = ''.obs;
  Chat? chat;
  Timer? _typingDebounce;
  Timer? _timer;

  bool showSelected = false;

  bool showCaption = true;

  bool showResolution = true;

  late AssetPreviewDetail currentAsset;

  final RxList<AssetPreviewDetail> currentAssets = <AssetPreviewDetail>[].obs;
  final RxList<AssetPreviewDetail> selectedAssets = <AssetPreviewDetail>[].obs;

  Map<String, String> compressedSelectedAsset = <String, String>{};

  final RxInt selectedAssetCount = 0.obs;

  late AssetPickerProvider provider;
  late AssetPickerConfig pConfig;

  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocus = FocusNode();

  final bottomBarHeight = 48.0;
  Function? backAction;
  final coverFilePath = Rx<dynamic>(null);

  int videoRestrictDuration = -1;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>;

    if (!arguments.containsKey('provider') ||
        !arguments.containsKey('pConfig')) {
      Get.back();
      return;
    }

    if (arguments['isEdit'] != null) {
      isEdit.value = true;
    }
    if (arguments['isFromPhoto'] != null) {
      isFromPhoto.value = arguments['isFromPhoto'] as bool;
    }

    if (arguments['showSelected'] != null) {
      showSelected = true;
    }

    provider = arguments['provider'] as AssetPickerProvider;
    pConfig = arguments['pConfig'] as AssetPickerConfig;

    if (arguments['chat'] != null) {
      chat = arguments['chat'];
      translateLocale.value = getAutoLocale(chat: chat);
    }
    backAction = arguments['backAction'];

    if (arguments['showCaption'] != null && !arguments['showCaption']) {
      showCaption = false;
    }

    if (arguments['showResolution'] != null && !arguments['showResolution']) {
      showResolution = false;
    }

    if (arguments['videoRestrictDuration'] != null) {
      videoRestrictDuration = arguments['videoRestrictDuration'] as int;
    }

    bool hasCaption = false;
    if (arguments.containsKey('caption')) {
      hasCaption = true;
      captionController.text = arguments['caption'] as String;
    }

    if (!isEdit.value && !showSelected) {
      for (final entity in provider.currentAssets) {
        currentAssets.add(AssetPreviewDetail(
          id: entity.id,
          index: currentAssets.length,
          entity: entity,
          caption: hasCaption ? captionController.text : '',
        ));
      }

      for (int i = 0; i < provider.selectedAssets.length; i++) {
        final element = provider.selectedAssets[i];
        _preCompressAsset(element);
        selectedAssets.add(AssetPreviewDetail(
          id: element.id,
          index: i,
          entity: element,
          caption: hasCaption ? captionController.text : '',
        ));
      }
    }

    if (showSelected) {
      for (final entity in provider.selectedAssets) {
        _preCompressAsset(entity);
        final asset = AssetPreviewDetail(
          id: entity.id,
          index: currentAssets.length,
          entity: entity,
          caption: hasCaption ? captionController.text : '',
        );
        currentAssets.add(asset);
        selectedAssets.add(asset);
      }

      pageController = PhotoViewPageController();
    }

    if (arguments.containsKey('index') && arguments['index'] >= 0) {
      currentPage.value = arguments['index'] as int;
      pageController = PhotoViewPageController(initialPage: arguments['index']);
    }

    selectedAssetCount.value = selectedAssets.length;

    if (arguments.containsKey('asset')) {
      final foundIdx = currentAssets
          .indexWhere((element) => element.entity == arguments['asset']);
      if (foundIdx != -1) {
        currentPage.value = foundIdx;
        pageController = PhotoViewPageController(initialPage: foundIdx);
      }
    }

    if (isEdit.value) {
      currentAsset = AssetPreviewDetail(
        id: arguments['entity'].id,
        index: 0,
        entity: arguments['entity'] as AssetEntity,
        caption: hasCaption ? captionController.text : '',
      );
      pageController = PhotoViewPageController();
      currentAssets.add(currentAsset);
      selectedAssets.add(currentAsset);
    } else {
      currentAsset = currentAssets[currentPage.value];
    }

    provider.addListener(assetProviderListener);

    captionController.addListener(inputListener);
    if (chat != null) {
      objectMgr.chatMgr.on(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    }
  }

  @override
  void onClose() {
    provider.removeListener(assetProviderListener);

    captionController.removeListener(inputListener);
    if (chat != null) {
      objectMgr.chatMgr.off(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    objectMgr.updateAudioSettings();
    super.onClose();
  }

  void assetProviderListener() {
    if (provider.selectedAssets.length != selectedAssetCount.value) {
      if (provider.selectedAssets.length > selectedAssetCount.value) {
        for (var asset in provider.selectedAssets) {
          int idx =
              currentAssets.indexWhere((element) => element.entity == asset);
          if (idx != -1 && !selectedAssetList.contains(asset)) {
            _preCompressAsset(asset);
            selectedAssets.add(currentAssets[idx]);
            selectedAssetCount.value++;
          }
        }
      } else {
        for (int i = 0; i < selectedAssetList.length; i++) {
          final element = selectedAssetList.elementAt(i);
          final removePath = compressedSelectedAsset.remove(element.id);
          if (removePath != null) File(removePath).delete();
          if (!provider.selectedAssets.contains(element)) {
            selectedAssets.removeAt(i);
            selectedAssetCount.value--;
          }
        }
      }
    }
  }

  void assetTabListener() {
    final idx = selectedAssets.indexOf(currentAsset);
    if (idx == -1) {
      currentPage.value = 0;
      pageController.jumpToPage(0);
      return;
    }

    currentPage.value = idx;
    pageController.jumpToPage(idx);
  }

  void previewScrollListener() {}

  void inputListener() {
    currentAsset.caption = captionController.text;

    if (selectedAssetList.contains(currentAsset.entity)) {
      final idx = selectedAssetList.toList().indexOf(currentAsset.entity);
      selectedAssets[idx].caption = captionController.text;
    }

    if (_typingDebounce?.isActive ?? false) _typingDebounce?.cancel();
    if (chat != null) {
      if (chat!.isAutoTranslateOutgoing) {
        _typingDebounce = Timer(const Duration(milliseconds: 500), () {
          _translateText();
        });

        if (captionController.text.isNotEmpty) {
          if (!EmojiParser.hasOnlyEmojis(captionController.text)) {
            showTranslateBar.value = true;
          }
        } else {
          _typingDebounce?.cancel();
          showTranslateBar.value = false;
          translatedText.value = '';
        }
      }
    }
  }

  _translateText() async {
    if (!await serversUriMgr.checkIsConnected()) return;
    bool doneAnimation = false;
    isTranslating.value = true;
    _timer = Timer(const Duration(milliseconds: 995), () {
      if (doneAnimation) {
        isTranslating.value = false;
      }
    });

    Map<String, String> res = await objectMgr.chatMgr.getMessageTranslation(
      captionController.text,
      locale: translateLocale.value,
    );
    if (res['translation'] != '') {
      translatedText.value = UnescapeUtil.encodedString(res['translation']!);
    } else {
      translatedText.value = '';
    }
    if (_timer!.isActive) {
      doneAnimation = true;
    } else {
      isTranslating.value = false;
    }
  }

  _onChatReplace(_, __, data) {
    if (data is Chat && chat!.chat_id == data.chat_id) {
      chat = data;
      if (!chat!.isAutoTranslateOutgoing) {
        showTranslateBar.value = false;
        isTranslating.value = false;
        translatedText.value = '';
        if (_typingDebounce?.isActive ?? false) _typingDebounce?.cancel();
      }
      translateLocale.value = getAutoLocale(chat: chat);
      _translateText();
    }
  }

  void onPageChanged(BuildContext context, int index) {
    currentAsset = currentAssets[index];
    videoHasLoaded.value = false;

    update(['selectedAsset', 'captionChanged']);

    if (index + 3 > currentAssets.length) {
      provider.loadMoreAssets();
    }

    currentPage.value = index;
  }

  void _preCompressAsset(AssetEntity entity) async {
    if (entity.type != AssetType.image) return;

    final file = await entity.originFile;
    if (file == null) return;

    // 获取压缩以后的上传尺寸
    Size fileSize = getResolutionSize(
      entity.orientatedWidth,
      entity.orientatedHeight,
      MediaResolution.image_standard.minSize,
    );

    final compressedImage = await imageMgr.compressImage(
      file.path,
      fileSize.width.toInt(),
      fileSize.height.toInt(),
    );

    if (compressedImage == null) return;

    compressedSelectedAsset[entity.id] = compressedImage;
  }

  final int _cacheRange = 2;

  preloadImage(BuildContext context, int index) {
    List<AssetPreviewDetail> assets = currentAssets;
    for (int i = index - _cacheRange; i < index + _cacheRange; i++) {
      if (i >= assets.length || i < 0) continue;
      final asset = assets[i];
      if (asset.entity.type == AssetType.video) continue;
      AssetPreviewDetail detail = currentAssets[i];

      final isOriginal =
          asset.entity.width < 3000 && asset.entity.height < 3000;
      ThumbnailSize? thumbnailSize;
      if (isEdit.value) {
        if (!isOriginal) {
          final ratio = asset.entity.width / asset.entity.height;
          if (asset.entity.width > asset.entity.height) {
            thumbnailSize = ThumbnailSize(2000, 2000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((2000 * ratio).toInt(), 2000);
          }
        }
      } else {
        if (!isOriginal) {
          final ratio = asset.entity.width / asset.entity.height;
          if (asset.entity.width > asset.entity.height) {
            thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
          }
        }
      }

      if (detail.editedFile != null) {
        precacheImage(ExtendedFileImageProvider(detail.editedFile!), context);
      } else {
        precacheImage(
          AssetEntityImageProvider(
            asset.entity,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          context,
          onError: (Object exception, StackTrace? stackTrace) {
            pdebug("#### - Precache failed - ${detail.entity.id}");
          },
        );
      }
    }
  }

  void onTabChanged(int index) {}

  void onAssetTap(int index) {
    pageController.jumpToPage(index);
    currentPage.value = index;
  }

  void onSwitchToolOption() {
    captionFocus.unfocus();
  }

  void selectAsset(
      BuildContext context, AssetEntity asset, bool isSelected) async {
    if (isEdit.value) return;

    if (provider.selectedAssets.contains(asset)) {
      provider.unSelectAsset(asset);
      final idx = selectedAssetList.toList().indexOf(asset);
      if (idx != -1) {
        selectedAssets.removeAt(idx);
      }
    } else {
      if (selectedAssetCount.value >= pConfig.maxAssets) {
        showWarningToast(localized(maxImageCount, params: ["9"]));
        return;
      }
      await provider.selectAsset(asset);
    }
    update(['selectedAsset']);
  }

  void editAsset(BuildContext context) async {
    final AssetPreviewDetail assetDetail = currentAssets[currentPage.value];
    File? assetFile =
        assetDetail.editedFile ?? await assetDetail.entity.originFile;

    if (isEdit.value) {
      assetFile =
          currentAsset.editedFile ?? await currentAsset.entity.originFile;
    }

    if (assetFile == null) {
      Toast.showToast(localized(toastFileFailed));
      return;
    }

    try {
      coverFilePath.value = assetDetail.editedFile ?? assetDetail.entity;
      final newFile = await copyImageFile(assetFile);
      var done = await FlutterPhotoEditor().editImage(newFile.path,
          languageCode: objectMgr.langMgr.currLocale.languageCode);

      ui.Image uiImage = await createUiImage(newFile.readAsBytesSync());

      final result = EditorImageResult(
        uiImage.width.toInt(),
        uiImage.height.toInt(),
        newFile,
      );

      if (done) {
        final File file = result.newFile;

        AssetEntity entity;
        if (isEdit.value) {
          currentAsset.editedFile = file;
          currentAsset.editedWidth = result.imgWidth;
          currentAsset.editedHeight = result.imgHeight;

          ImageGallerySaver.saveFile(newFile.path);

          update(['editedChanged']);
          return;
        }

        entity = currentAssets[currentPage.value].entity;

        final int idx =
            currentAssets.indexWhere((a) => a.entity.id == entity.id);
        currentAssets[idx].editedFile = file;
        currentAssets[idx].editedWidth = result.imgWidth;
        currentAssets[idx].editedHeight = result.imgHeight;

        double ratio = result.imgWidth / result.imgHeight;

        if (currentAssets[idx].imageResolution == MediaResolution.image_high) {
          if (min(result.imgWidth, result.imgHeight) <
              MediaResolution.image_high.minSize) {
            currentAssets[idx].imageResolution = MediaResolution.image_standard;
            update(['resolutionChanged'], true);
          }
        }

        currentAssets[idx].editedThumbFile = await getThumbImageWithPath(
          file,
          64,
          (64 / ratio).round(),
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'preview_thumbnail',
        );

        if (!provider.selectedAssets.contains(entity)) {
          await provider.selectAsset(entity);
          update(['selectedAsset']);
        }

        int selectedIdx = provider.selectedAssets.indexOf(entity);
        if (selectedIdx != -1) {
          selectedAssets[selectedIdx].editedFile = file;
          selectedAssets[selectedIdx].editedWidth = result.imgWidth;
          selectedAssets[selectedIdx].editedHeight = result.imgHeight;

          if (selectedAssets[selectedIdx].imageResolution ==
              MediaResolution.image_high) {
            if (min(result.imgWidth, result.imgHeight) <
                MediaResolution.image_high.minSize) {
              selectedAssets[selectedIdx].imageResolution =
                  MediaResolution.image_standard;
            }
          }

          selectedAssets[selectedIdx].editedThumbFile =
              await getThumbImageWithPath(
            file,
            64,
            (64 / ratio).round(),
            savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            sub: 'preview_thumbnail',
          );
        }

        update(['editedChanged']);

        ImageGallerySaver.saveFile(newFile.path);
      }
    } catch (_) {}
  }

  bool get isVideo => currentAsset.entity.type == AssetType.video;

  bool get shouldShowHighResolution =>
      (isVideo &&
          min(
                  currentAsset.editedHeight ??
                      currentAsset.entity.orientatedHeight,
                  currentAsset.editedWidth ??
                      currentAsset.entity.orientatedWidth) >
              MediaResolution.video_high.minSize) ||
      (!isVideo &&
          min(
                  currentAsset.editedHeight ??
                      currentAsset.entity.orientatedHeight,
                  currentAsset.editedWidth ??
                      currentAsset.entity.orientatedWidth) >
              MediaResolution.image_high.minSize);

  void onChangeResolution(BuildContext context) async {
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return MediaResolutionSelection(
            asset: currentAsset,
            type: currentAsset.entity.type,
            fromCamera: isEdit.value,
          );
        }).then((value) {
      if (value is MediaResolution) {
        bool isVideo = currentAsset.entity.type == AssetType.video;
        if (isVideo) {
          currentAsset.videoResolution = value;
          final idx = selectedAssets
              .indexWhere((element) => element.id == currentAsset.id);
          if (idx != -1) {
            selectedAssets[idx].videoResolution = value;
          }
        } else {
          currentAsset.imageResolution = value;
          final idx = selectedAssets
              .indexWhere((element) => element.id == currentAsset.id);
          if (idx != -1) {
            selectedAssets[idx].imageResolution = value;
          }
        }

        String resolutionText = '';
        if ((isVideo && value == MediaResolution.video_standard) ||
            (!isVideo && value == MediaResolution.image_standard)) {
          resolutionText = localized(standardResolutionText);
        } else {
          resolutionText = localized(highResolutionText);
        }

        ImBottomToast(
          context,
          title: localized(
            sendAsResolution,
            params: [
              isVideo ? localized(videoText) : localized(imageText),
              resolutionText,
            ],
          ),
          icon: ImBottomNotifType.success,
          duration: 3,
        );

        update(['resolutionChanged'], true);
      }
    });
  }

  void sendAsset() {
    List<AssetPreviewDetail> assetsCopy = <AssetPreviewDetail>[];

    if (selectedAssets.isEmpty) {
      assetsCopy.add(currentAssets[currentPage.value]);
    } else {
      compressedSelectedAsset.forEach((key, value) {
        final tempSAssets = selectedAssets.firstWhereOrNull((e) => e.id == key);
        if (tempSAssets != null &&
            tempSAssets.editedFile == null &&
            tempSAssets.imageResolution == MediaResolution.image_standard) {
          tempSAssets.editedFile = File(value);
          tempSAssets.editedWidth = tempSAssets.entity.orientatedWidth;
          tempSAssets.editedHeight = tempSAssets.entity.orientatedHeight;
          tempSAssets.isCompressed = true;
        }
      });
    }

    Map<String, dynamic> res = {
      'assets': selectedAssets.isEmpty
          ? [currentAssets[currentPage.value]]
          : selectedAssets.toList(),
      'caption': captionController.text,
      'shouldSend': true,
    };

    if (translatedText.value != '') {
      res.addAll({'translation': translatedText.value});
    }

    if (videoRestrictDuration != -1) {
      if (currentAsset.entity.type == AssetType.video) {
        if (currentAsset.entity.duration > videoRestrictDuration) {
          showWarningToast(localized(momentRestrictSelectVideoDuration));
          return;
        }
      }
    }

    Get.back(result: res);
    if (isFromPhoto.value) {
      Get.back();
    }
  }

  bool isClosing = false;

  void onClickBack() {
    if (backAction == null) {
      Get.back(result: <String, dynamic>{
        'caption': captionController.text,
        'shouldSend': false,
      });
      return;
    }

    isClosing = true;
    backAction?.call();
    Future.delayed(Duration(milliseconds: backAction == null ? 0 : 150), () {
      Get.back();
    });
  }

  Set<AssetEntity> get selectedAssetList =>
      selectedAssets.map<AssetEntity>((p) => p.entity).toSet();
}
