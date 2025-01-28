import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/photo_picker.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:path/path.dart' as mypath;
import 'package:synchronized/synchronized.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class UploadReelController extends GetxController {
  final resPorcessLock = Lock();
  final String REMOTE_VIDEO_KEY = "remoteVideoUrl";
  final String REMOTE_SETTING_KEY = "setting";
  final String REMOTE_COVER_KEY = "remoteCoverUrl";
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  PermissionState? ps;
  final resultPath = <AssetEntity>[].obs;
  bool isVideoProcessing = false;
  final isValidSubmit = false.obs;
  TextEditingController titleTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  RxList<ReelUploadTag> tagList =
      <ReelUploadTag>[ReelUploadTag(tag: localized(reelCustomize))].obs;
  final selectedTagList = <ReelUploadTag>[].obs;
  final isTagExpand = false.obs;
  int assetType = 1;

  TextEditingController tagTextController = TextEditingController();
  final isValidCreateTag = false.obs;
  RxInt tagWordCount = 0.obs;
  RxList<String> searchTagList = <String>[].obs;
  Debounce debounce = Debounce(const Duration(milliseconds: 500));
  Debounce uploadDebounce = Debounce(const Duration(seconds: 20));

  @override
  void onInit() {
    super.onInit();
    getSuggestTag();
  }

  @override
  void onClose() {
    getBackPage();
    tagList.clear();
    titleTextController.dispose();
    descriptionTextController.dispose();
    tagTextController.dispose();
    pickerConfig = null;
    provider?.dispose();
    super.onClose();
  }

  Future<void> getSuggestTag() async {
    tagList.addAll(objectMgr.reelCacheMgr.getLocalTags());
    try {
      TagData res = await suggestedTag();
      if (res.tags != null && res.tags!.isNotEmpty) {
        for (String tag in res.tags!) {
          ReelUploadTag? uploadTag =
              tagList.firstWhereOrNull((element) => element.tag == tag);
          if (uploadTag != null) continue;
          tagList.add(ReelUploadTag(tag: tag, count: 1));
        }
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
  }

  Future<void> showPickPhotoOption(BuildContext context) async {
    List<SelectionOptionModel> options = [];
    options.add(
      SelectionOptionModel(
        title: localized(takeAPhoto),
        titleTextStyle: jxTextStyle.textStyle20(color: themeColor),
      ),
    );
    options.add(
      SelectionOptionModel(
        title: localized(chooseFromGalley),
        titleTextStyle: jxTextStyle.textStyle20(color: themeColor),
      ),
    );

    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) {
        return SelectionBottomSheet(
          cancelButtonTextStyle: jxTextStyle.textStyle20(color: themeColor),
          context: c,
          selectionOptionModelList: options,
          callback: (int index) async {
            if (index == 0) {
              if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
                Toast.showToast(localized(toastEndCallFirst));
                return;
              }
              getCameraPhoto(context);
            } else if (index == 1) {
              getGalleryPhoto(context);
            }
          },
        );
      },
    );
  }

  void getCameraPhoto(BuildContext context) async {
    bool isGranted = await checkCameraOrPhotoPermission(type: 1);
    if (!isGranted) return;

    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
          enableRecording: true,
          enablePhoto: false,
          isMirrorFrontCamera: isMirrorFrontCamera);
    } else {
      final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              const CamerawesomePage(enableRecording: true),
        ),
      );
      if (res == null) {
        return;
      }
      entity = res["result"];
    }

    if (entity == null) {
      return;
    } else {
      if (entity.type == AssetType.video) {
        resultPath.add(entity);
        validateSubmit();
        return;
      }

      Toast.showToast(localized(reelOnlySupportVideo));
    }
  }

  Future<void> getGalleryPhoto(BuildContext context) async {
    ps = await requestAssetPickerPermission();
    if (ps == PermissionState.denied) return;

    pickerConfig = AssetPickerConfig(
      maxAssets: 1,
      requestType: RequestType.video,
      specialPickerType: SpecialPickerType.noPreview,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
    );
    provider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: pickerConfig!.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
      removeLivePhotos: true,
    );
    provider!.addListener(() {
      if (provider!.selectedAssets.isNotEmpty) {
        Get.back();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (BuildContext c) {
        return SizedBox(
          height: MediaQuery.of(c).size.height - 22,
          child: PhotoPicker(
            provider: provider!,
            pickerConfig: pickerConfig!,
            ps: ps!,
          ),
        );
      },
    ).then(
      (asset) async {
        if (provider!.selectedAssets.isNotEmpty) {
          if (provider!.selectedAssets.first.type == AssetType.video) {
            assetType = 1;
          }

          /// add to result path
          resultPath.add(provider!.selectedAssets.first);
          validateSubmit();

          /// reset
          provider!.selectedAssets = [];
          provider!.removeListener(() {});
          pickerConfig = null;
          provider = null;
        }
      },
    );
  }

  void onTagExpand(bool expanded) {
    isTagExpand.value = expanded;
  }

  void selectTag(ReelUploadTag tag, {alwaysSelect = false}) {
    if (alwaysSelect) {
      selectedTagList.add(tag);
    } else {
      if (selectedTagList.isNotEmpty && selectedTagList.contains(tag)) {
        selectedTagList.remove(tag);
      } else {
        selectedTagList.add(tag);
      }
    }
  }

  void onChangeValue(String value) {
    validateSubmit();
  }

  void validateSubmit() {
    if (resultPath.isNotEmpty) {
      isValidSubmit.value = true;
    } else {
      isValidSubmit.value = false;
    }
  }

  void onSubmit() async {
    if (!isValidSubmit.value) return;
    objectMgr.reelCacheMgr.updateTagList(selectedTagList);
    if (isVideoProcessing) {
      Toast.showToast(localized(reelVideoStillBeingCreated));
      return;
    }

    AssetEntity asset = resultPath.first;

    if (overlayScreen != null && !overlayScreen!.isOpen) {
      overlayScreen!.show(asset);
    }

    Get.back();

    isVideoProcessing = true;

    File? file = await asset.originFile;
    if (file != null) {
      String localFilePath = file.path;
      int fileSize = file.lengthSync();
      Map<String, dynamic> urlData = {};

      CancelToken cancelToken = CancelToken();
      int orientedWidth = asset.orientatedWidth;
      int orientedHeight = asset.orientatedHeight;
      if (orientedWidth == 0 || orientedHeight == 0) {
        MediaInformationSession infoSession =
            await FFprobeKit.getMediaInformation(file.path);
        MediaInformation? mediaInformation = infoSession.getMediaInformation();

        final List<StreamInformation> streams =
            mediaInformation?.getStreams() ?? [];
        if (streams.isEmpty) {
          Toast.showToast(localized(toastVideoNotExit));
          closeFloatProgress();
          isVideoProcessing = false;
          return;
        }

        final videoStream =
            streams.firstWhere((stream) => stream.getType() == 'video');

        orientedWidth = videoStream.getWidth() ?? 0;
        orientedHeight = videoStream.getHeight() ?? 0;
      }

      bool standardVideo = standardResolution(orientedWidth, orientedHeight);

      await resPorcessLock.synchronized(() async {
        try {
          File? coverF = File(
            await downloadMgr.getTmpCachePath(
              '${mypath.basenameWithoutExtension(file.path)}.jpeg',
            ),
          );
          if (!coverF.existsSync() || coverF.lengthSync() == 0) {
            coverF.createSync(recursive: true);
            coverF.writeAsBytesSync(
              (await asset.thumbnailDataWithSize(
                ThumbnailSize(orientedWidth, orientedHeight),
                format: ThumbnailFormat.jpeg,
                quality: 80,
              ))!,
            );
          }

          Map<String, dynamic> extendedData = {};
          final String? coverThumbnail = await imageMgr.upload(
            coverF.path,
            orientedWidth,
            orientedHeight,
            cancelToken: cancelToken,
            storageType: StorageType.reels,
            format: GaussianGenFormat.blurHash,
            onGaussianComplete: (String gausPath) {
              extendedData['gausPath'] = gausPath;
            },
          );

          final (String path, String _) = await videoMgr.upload(
            file.path,
            accurateWidth: orientedWidth,
            accurateHeight: orientedHeight,
            fileType: UploadExt.reels,
            cancelToken: cancelToken,
            storageType: StorageType.reels,
            onCompressProgress: (double progress) {
              pdebug(
                "compressedProcess==============> ${overlayScreen == null}-$progress",
              );
              if (overlayScreen == null) return;

              overlayScreen!.curStatus.value = SubmitStatus.COMPRESSING;
              if (overlayScreen!.isOpen) {
                overlayScreen!.updateProgress((progress / 100) / 2);
              }
            },
            onCompressCallback: (String path) {
              localFilePath = path;
              fileSize = File(path).lengthSync();
              pdebug("compressedVideo==============> $standardVideo-$path");
              overlayScreen!.reset();
              overlayScreen!.curStatus.value = SubmitStatus.WAIT_UPLOAD;
            },
            onStatusChange: (int status) {
              if (status == 4) {
                overlayScreen!.curStatus.value = SubmitStatus.UPLOADED;
              }
            },
            onSendProgress: (int bytes, int total) {
              if (overlayScreen == null) return;

              overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
              double progress =
                  double.parse((bytes / total).toStringAsFixed(2));
              if (progress > 1) {
                progress = 1.0;
              }
              if (overlayScreen!.isOpen) {
                double p = (progress / 2) + 0.5 - 0.05;
                double showProgress = p < 0.5 ? 0.5 : p;
                if (showProgress > overlayScreen!.curProgress.value) {
                  overlayScreen!.updateProgress(showProgress);
                }
              }
            },
          );

          if (notBlank(path) && notBlank(coverThumbnail)) {
            await Future.delayed(const Duration(seconds: 1));
            imageMgr.resizeImageTo384(coverF.path, coverThumbnail!);
            objectMgr.tencentVideoMgr.moveFile(localFilePath, path);
            urlData[REMOTE_VIDEO_KEY] = path;
            urlData[REMOTE_COVER_KEY] = coverThumbnail;
            urlData['width'] = orientedWidth;
            urlData['height'] = orientedHeight;
            urlData['size'] = fileSize;
            if (extendedData.isNotEmpty) {
              urlData[REMOTE_SETTING_KEY] = jsonEncode(extendedData);
            }
          }

          if (urlData.isNotEmpty) {
            urlData['duration'] = asset.duration;
            createReel(urlData);
          } else {
            closeFloatProgress();
          }
        } catch (e, s) {
          pdebug(e, stackTrace: s);
          closeFloatProgress();
        }
      });
    } else {
      closeFloatProgress();
    }
    isVideoProcessing = false;
  }

  void createReel(Map<String, dynamic> urlData) async {
    List<String> tags = selectedTagList.map((element) => element.tag).toList();
    try {
      overlayScreen!.updateProgress(0.96);
      final resp = await createPost(
        assetType,
        titleTextController.text,
        descriptionTextController.text,
        urlData['duration'],
        [
          {
            'path': urlData[REMOTE_VIDEO_KEY],
            'width': urlData['width'],
            'height': urlData['height'],
            'size': urlData['size'],
          },
        ],
        tags,
        urlData[REMOTE_COVER_KEY]!,
        urlData[REMOTE_SETTING_KEY],
      );
      overlayScreen!.updateProgress(0.97);

      if (resp) {
        overlayScreen!.curStatus.value = SubmitStatus.DONE;
        const List<int> durations = [1000, 1200, 1800];
        const List<double> progresses = [0.98, 0.99, 1.0];

        for (int i = 0; i < durations.length; i++) {
          Future.delayed(Duration(milliseconds: durations[i]), () {
            overlayScreen!.updateProgress(progresses[i]);
          });
        }

        Future.delayed(const Duration(milliseconds: 2000), () {
          closeFloatProgress();
          showReelToast(value: localized(reelSuccessPublished));
        });
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      overlayScreen!.curStatus.value = SubmitStatus.DONE;
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => closeFloatProgress(),
      );
    }
  }

  closeFloatProgress() {
    overlayScreen!.close();
  }

  void redirectToAddTag() {
    getSearchTag("");
    Get.toNamed(RouteName.addTag);
  }

  void onChangeTagValue(String value) {
    tagWordCount.value = value.length;
    validateCreateTag();
    debounce.call(() {
      getSearchTag(value);
    });
  }

  Future<void> getSearchTag(String value) async {
    searchTagList.clear();
    try {
      SearchTagData res = await searchTag(value);
      if (res.datas != null && res.datas!.isNotEmpty) {
        searchTagList.value = res.datas!;
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
  }

  void createTag() {
    if (isValidCreateTag.value) {
      String tag = tagTextController.text;
      if (notBlank(tag)) {
        ReelUploadTag? item =
            tagList.firstWhereOrNull((element) => element.tag == tag);
        if (item == null) {
          ReelUploadTag newTag = ReelUploadTag(tag: tag, count: 1);
          tagList.insert(1, newTag);
          selectTag(newTag, alwaysSelect: true);
        } else {
          selectTag(item, alwaysSelect: true);
        }
      }
    }

    Get.back();
  }

  void getBackPage() {
    tagTextController.clear();
    isValidCreateTag.value = false;
    searchTagList.clear();

    final ReelController controller = Get.find<ReelController>();
    if (controller == null) return;
    if (controller.selectedBottomIndex.value == 2) return;
    controller.onReturnNavigation();
  }

  void onClickSearchTag(String tag) {
    tagTextController.text = tag;
    tagWordCount.value = tag.length;
    validateCreateTag();
  }

  void validateCreateTag() {
    if (notBlank(tagTextController.text)) {
      isValidCreateTag.value = true;
    } else {
      isValidCreateTag.value = false;
    }
  }
}
