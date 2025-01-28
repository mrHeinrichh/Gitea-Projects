import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/api/file_upload.dart' as upload;
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/net/upload_link_info.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_uploader.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:video_compress/video_compress.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/photo_picker.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';

class UploadReelController extends GetxController {
  final String REMOTE_VIDEO_KEY = "remoteVideoUrl";
  final String REMOTE_COVER_KEY = "remoteCoverUrl";
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  PermissionState? ps;
  final resultPath = <AssetEntity>[].obs;
  bool isVideoProcessing = false;
  final isValidSubmit = false.obs;
  TextEditingController titleTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  RxList<String> tagList = <String>["+自定义"].obs;
  final selectedTagList = <String>[].obs;
  final isTagExpand = true.obs;
  int assetType = 1;

  /// AddTagView
  TextEditingController tagTextController = TextEditingController();
  final isValidCreateTag = false.obs;
  RxInt tagWordCount = 0.obs;
  RxList<String> searchTagList = <String>[].obs;
  Debounce debounce = Debounce(const Duration(milliseconds: 500));

  @override
  void onInit() {
    super.onInit();
    getSuggestTag();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
    titleTextController.dispose();
    descriptionTextController.dispose();
  }

  Future<void> getSuggestTag() async {
    TagData res = await suggestedTag();
    if (res.tags != null && res.tags!.isNotEmpty) {
      tagList.addAll(res.tags!);
    }
  }

  void showPickPhotoOption(BuildContext context) {
    List<SelectionOptionModel> options = [];
    options.add(
      SelectionOptionModel(
        title: localized(takeAPhoto),
      ),
    );
    options.add(
      SelectionOptionModel(
        title: localized(chooseFromGalley),
      ),
    );
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
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

  void getCameraPhoto(BuildContext context) {
    checkPermission(context).then((isGranted) async {
      if (isGranted) {
        // final AssetEntity? entity = await CameraPicker.pickFromCamera(
        //   context,
        //   pickerConfig: CameraPickerConfig(
        //     enableRecording: true,
        //     enableAudio: true,
        //     theme: CameraPicker.themeData(accentColor),
        //     textDelegate: cameraPickerTextDelegateFromLocale(
        //         objectMgr.langMgr.currLocale),
        //   ),
        // );
        final Map<String, dynamic>? res = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) =>
                    CamerawesomePage(enableRecording: true)));
        if (res == null) {
          return;
        }
        final AssetEntity? entity = res["result"];
        if (entity == null) {
          return;
        } else {
          resultPath.add(entity);
          validateSubmit();
        }
      }
    });
  }

  Future<void> getGalleryPhoto(BuildContext context) async {
    pickerConfig = AssetPickerConfig(
      maxAssets: 1,
      requestType: RequestType.video,
      specialPickerType: SpecialPickerType.noPreview,
      shouldRevertGrid: false,
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
    );
    provider!.addListener(() {
      if (provider!.selectedAssets.isNotEmpty) {
        Get.back();
      }
    });

    checkPermission(context).then(
      (isGranted) async {
        if (isGranted) {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            builder: (context) => PhotoPicker(
              provider: provider!,
              pickerConfig: pickerConfig!,
              ps: PermissionState.authorized,
            ),
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
      },
    );
  }

  void onTagExpand(bool expanded) {
    isTagExpand.value = expanded;
  }

  void selectTag(String tag, {alwaysSelect = false}) {
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
      // if (notBlank(titleTextController.text) &&
      //     notBlank(descriptionTextController.text)) {
      isValidSubmit.value = true;
      // } else {
      //   isValidSubmit.value = false;
      // }
    } else {
      isValidSubmit.value = false;
    }
  }

  void onSubmit() async {
    if (!isValidSubmit.value) return;
    if (isVideoProcessing) {
      Toast.showToast("视频还在创建中...");
      return;
    }

    if (overlayScreen != null && !overlayScreen!.isOpen) {
      overlayScreen!.show();
    }

    Get.back();

    isVideoProcessing = true;

    AssetEntity asset = resultPath.first;
    DateTime now = DateTime.now();
    final String uploadKey =
        '${now.millisecondsSinceEpoch.toString().substring(8)}${makeMD5(asset.id).substring(27, 32)}';
    File? file = await asset.originFile;
    if (file != null) {
      final String? fileHash =
          await compute<String, String?>(calculateMD5FromPath, file.path);

      if (fileHash != null) {
        Map<String, dynamic> urlData = {};
        List<UploadLinkInfo> uploadInfo = await upload.checkFileExist(fileHash);
        bool shouldUpload = true;
        if (uploadInfo.isNotEmpty) {
          uploadInfo.forEach((element) {
            if (element.code > 0 || element.error.isNotEmpty) {
              shouldUpload = false;
              urlData[REMOTE_VIDEO_KEY] = uploadInfo.first.path;
              urlData['width'] = asset.width;
              urlData['height'] = asset.height;
              urlData['size'] = file.lengthSync();
            }
          });
        }

        File? coverF = await generateThumbnailWithPath(
          file.path,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpeg',
          sub: 'cover',
        );
        if (shouldUpload) {
          bool standardVideo = standardResolution(asset.width, asset.height);
          final File? compressedVideo =
              standardVideo ? file : await compressVideo(file);
          pdebug(
              "compressedVideo==============> $standardVideo-${compressedVideo?.path}");
          if (compressedVideo != null) {
            UploadFile fileInfo = UploadFile.fromFile(
              uploadKey,
              UploadExt.video,
              compressedVideo,
              fileHash,
              AssetType.video,
              asset.width,
              asset.height,
              now.millisecondsSinceEpoch,
              cover: coverF.path,
            );
            fileInfo.originalFileName = getFileName(file.path);

            final uploadRes = await uploadVideo(fileInfo);
            urlData.assignAll(uploadRes);
          } else {
            Toast.showToast("压缩失败");
            overlayScreen!.close();
          }
        } else {
          final coverHash =
              await compute<String, String?>(calculateMD5FromPath, coverF.path);
          if (coverHash != null) {
            UploadFile coverInfo = UploadFile.fromFile(
                uploadKey,
                UploadExt.image,
                coverF,
                coverHash,
                AssetType.image,
                asset.width,
                asset.height,
                now.millisecondsSinceEpoch);

            String? coverUrl = await FileUploader.shared.uploadFile(coverInfo);
            urlData[REMOTE_COVER_KEY] = coverUrl ?? "";
          }

          closeFloatProgress();
        }
        pdebug("remoteVideoUrl==============> $urlData");
        if (urlData.isNotEmpty) {
          urlData['duration'] = asset.duration;
          createReel(urlData);
        }
      } else {
        closeFloatProgress();
      }
    } else {
      closeFloatProgress();
    }
    isVideoProcessing = false;
  }

  Future<File?> compressVideo(File file) async {
    final File? compressedVideo = await videoCompress(
      file,
      quality: VideoQuality.Res1280x720Quality,
      savePath: '${DateTime.now().millisecondsSinceEpoch}.mp4',
      onProgress: (double progress) {
        pdebug(
            "compressedProcess==============> ${overlayScreen == null}-$progress");
        if (overlayScreen == null) return;

        overlayScreen!.curStatus.value = SubmitStatus.COMPRESSING;
        if (overlayScreen!.isOpen) {
          overlayScreen!.updateProgress(progress / 100);
        }
      },
    );

    if (overlayScreen != null) {
      overlayScreen!.reset();
      overlayScreen!.curStatus.value = SubmitStatus.WAIT_UPLOAD;
    }

    return compressedVideo;
  }

  Future<Map<String, dynamic>> uploadVideo(UploadFile uploadFile) async {
    String coverUrl = "";
    final remoteVideoUrl = await FileUploader.shared.uploadFile(uploadFile,
        onProgress: (bytes, total) {
      if (overlayScreen == null) return;

      overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
      double progress = double.parse(
          (uploadFile.sentBytes / uploadFile.totalBytes).toStringAsFixed(2));
      if (overlayScreen!.isOpen) {
        overlayScreen!.updateProgress(progress);

        if (progress >= 1) {
          overlayScreen!.close();
        }
      }
    }, onCoverUploaded: (url) {
      coverUrl = url;
    });

    //上传成功后调用
    upload.updateUploadStatus({
      'key': uploadFile.originalFileHash,
      'status': 'SUCCESS',
    });
    return {
      REMOTE_VIDEO_KEY: remoteVideoUrl ?? "",
      REMOTE_COVER_KEY: coverUrl,
      'width': uploadFile.width,
      'height': uploadFile.height,
      'size': uploadFile.totalBytes,
    };
  }

  void createReel(Map<String, dynamic> urlData) async {
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
      selectedTagList,
      urlData[REMOTE_COVER_KEY]!,
    );

    if (resp) {
      overlayScreen!.curStatus.value = SubmitStatus.DONE;
      Future.delayed(
          const Duration(milliseconds: 1000), () => closeFloatProgress());
      Toast.showToast("创建成功");
    }
  }

  closeFloatProgress() {
    overlayScreen!.close();
  }

  /// add tag view

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
    SearchTagData res = await searchTag(value);
    if (res.datas != null && res.datas!.isNotEmpty) {
      searchTagList.value = res.datas!;
    }
  }

  void createTag() {
    if (isValidCreateTag.value) {
      String tag = tagTextController.text;
      if (notBlank(tag)) {
        if (!tagList.contains(tag)) {
          tagList.insert(1, tag);
        }
        selectTag(tag, alwaysSelect: true);
      }
    }
    getBackPage();
  }

  void getBackPage() {
    tagTextController.clear();
    isValidCreateTag.value = false;
    searchTagList.clear();
    Get.back();
  }

  void onClickSearchTag(String tag) {
    tagTextController.text = tag;
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
