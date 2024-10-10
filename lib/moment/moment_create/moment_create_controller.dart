import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/media/general_media_picker.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/component/mentioned_friend_bottom_sheet.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_create/moment_create_viewer.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MomentCreateController extends GetxController {
  // 朋友圈文案输入器
  final TextEditingController momentDescTextController =
      TextEditingController();
  final FocusNode momentDescFocus = FocusNode();

  final RxList<AssetPreviewDetail> assetList = <AssetPreviewDetail>[].obs;

  // 资源选择器
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;

  RxBool isDragging = false.obs;
  RxBool isInDeleteArea = false.obs;
  RxInt draggedIndex = RxInt(-1);
  double dragDeleteAreaHeight = 0.0;

  final resProcessLock = Lock();

  // 能被谁看见
  MomentVisibility viewPermission = MomentVisibility.public;

  RxList<User> mentionedFriends = <User>[].obs;

  final CancelToken cancelToken = CancelToken();

  @override
  void onInit() {
    super.onInit();

    unawaited(onPrepareMediaPicker(Get.context!));
  }

  @override
  void dispose() {
    momentDescTextController.dispose();
    momentDescFocus.dispose();

    cancelToken.cancel();

    super.dispose();
  }

  void onSelectAssets(BuildContext context) async {
    await onPrepareMediaPicker(context);
    momentDescFocus.unfocus();

    //ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: <SelectionOptionModel>[
            SelectionOptionModel(
              title: localized(camera),
              titleTextStyle: jxTextStyle.textStyle20(color: themeColor),
            ),
            SelectionOptionModel(
              title: localized(chooseFromGalley),
              titleTextStyle: jxTextStyle.textStyle20(color: themeColor),
            ),
          ],
          callback: (i) => onAssetSelectedCallback(context, i),
        );
      },
    );
  }

  void onAssetSelectedCallback(BuildContext context, int index) {
    switch (index) {
      case 0:
        onPhoto(context);
        break;
      case 1:
        onSelectFromGallery(context);
        break;
    }
  }

  void onPhoto(BuildContext context) async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    VolumePlayerService.sharedInstance.stopPlayer();
    VolumePlayerService.sharedInstance.resetPlayer();

    bool isVideo = true;

    if (assetList.isNotEmpty) {
      if (assetList.first.entity.type == AssetType.video) {
        // 逻辑错误, 如果是视频不应该有这个入口
        imBottomToast(
          context,
          title: localized(momentRestrictSelectPhotoAndVideo),
          icon: ImBottomNotifType.warning,
        );
        return;
      } else {
        isVideo = false;
      }
    }

    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
        enableRecording: isVideo,
        maximumRecordingDuration: const Duration(seconds: 600),
        manualCloseOnSuccess: true,
        isMirrorFrontCamera: isMirrorFrontCamera
      );
    } else {
      //Android
      final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => CamerawesomePage(
            enableRecording: isVideo,
            maximumRecordingDuration: const Duration(seconds: 600),
            onResult: (result) async {
              if (!notBlank(result)) return;
              gotoMediaPreviewView(result["result"], isFromPhoto: true);
            },
          ),
        ),
      );

      if (res == null) return;
      entity = res["result"];
    }

    if (entity == null) return;

    gotoMediaPreviewView(entity, isFromPhoto: false);
  }

  void gotoMediaPreviewView(
    AssetEntity? entity, {
    bool isFromPhoto = false,
  }) async {
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'entity': entity,
        'provider': assetPickerProvider,
        'pConfig': pickerConfig,
        'showCaption': false,
        'showResolution': false,
        'isEdit': true,
        'isFromPhoto': isFromPhoto,
        'backAction': () {
          if (Platform.isIOS) {
            onPhoto(Get.context!);
          }
        },
      },
    )?.then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }
        assetList.addAll(result['assets']);
        return;
      } else {}
      return;
    });
  }

  void onSelectFromGallery(BuildContext context) async {
    //ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return GeneralMediaPicker(
          provider: assetPickerProvider!,
          pickerConfig: pickerConfig!,
          ps: ps!,
          typeRestrict: true,
          onSend: () => Navigator.of(context).pop({
            'assets': assetPickerProvider!.selectedAssets,
            'shouldSend': true,
          }),
        );
      },
    ).then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        // if (result.containsKey('openPreview') && !result['openPreview']) {
        //   assetList.addAll(result['assets']);
        //   return;
        // }

        List<AssetPreviewDetail> tempAssetList = [];
        if (result['assets'] is List<AssetEntity>) {
          for (int i = 0; i < result['assets'].length; i++) {
            AssetEntity entity = result['assets'][i];
            tempAssetList.add(
              AssetPreviewDetail(
                id: entity.id,
                entity: entity,
                index: i,
                caption: '',
              ),
            );
          }
        } else if (result['assets'] is List<AssetPreviewDetail>) {
          tempAssetList.addAll(result['assets']);
        }

        if ((result['assets'] == null || (result['assets'] as List).isEmpty) &&
            assetPickerProvider!.selectedAssets.isNotEmpty) {
          for (int i = 0; i < assetPickerProvider!.selectedAssets.length; i++) {
            AssetEntity entity = assetPickerProvider!.selectedAssets[i];
            tempAssetList.add(
              AssetPreviewDetail(
                id: entity.id,
                entity: entity,
                index: i,
                caption: '',
              ),
            );
          }
        }

        assetList.addAll(tempAssetList);
      }
    });
  }

  void onTapImage(int index) {
    Get.to(
      () => MomentCreateViewer(
        index: index,
        assetList: assetList,
      ),
    );
  }

  void onAssetReorder(int oldIndex, int newIndex) {
    if (newIndex >= assetList.length) {
      final item = assetList.removeAt(oldIndex);
      assetList.add(item);
      return;
    }

    final item = assetList.removeAt(oldIndex);
    assetList.insert(newIndex, item);
  }

  void onDeleteAsset(AssetPreviewDetail asset) {
    assetList.remove(asset);
  }

  void getBackPage() {
    momentDescTextController.dispose();
    momentDescFocus.dispose();
    Get.back();
  }

  // 朋友圈发布
  void onPublishMoment(BuildContext context) async {

    if (momentDescTextController.text.trim().isEmpty && assetList.isEmpty) {
      imBottomToast(
        context,
        title: localized(momentCreateContentEmpty),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    momentDescFocus.unfocus();
    FocusScope.of(Get.context!).unfocus();

    if (overlayScreen != null && !overlayScreen!.isOpen) {
      String descText = "";
      AssetEntity asset;
      if(assetList.isEmpty){
        descText = momentDescTextController.text.trim();
        asset = AssetEntity(id: "", typeInt: 0, width: 0, height: 0,mimeType: "text",title: descText);
      }else{
        asset = assetList.first.entity;
      }
      overlayScreen!.show(asset);
    }

    final content = MomentContent(
      text: momentDescTextController.text.trim(),
      assets: <MomentContentDetail>[],
    );

    getBackPage();

    bool isFail = false;

    await resProcessLock.synchronized(() async {
      // 资源上传
      if (assetList.isNotEmpty) {
        if (assetList.first.entity.type == AssetType.image)
        {
          overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
          double totalProgress = 0.0;
          double perEach = (9/assetList.length)*0.1;
          // 图片上传
          for (int i = 0; i < assetList.length; i++) {
            final asset = assetList[i];
            if (cancelToken.isCancelled) {
              isFail = true;
              continue;
            }

            String filePath = asset.editedFile != null
                ? asset.editedFile!.path
                : (await asset.entity.originFile)!.path;
            int width = asset.editedWidth ?? asset.entity.orientatedWidth;
            int height = asset.editedHeight ?? asset.entity.orientatedHeight;

            Size fileSize = getResolutionSize(
              width,
              height,
              MediaResolution.image_standard.minSize,
            );

            String gausPath = "";
            final url = await imageMgr.upload(
              filePath,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
              cancelToken: cancelToken,
              enableGaussian: true,
              onSendProgress: (int sent, int total) {},
              onGaussianComplete: (String aGausPath) {
                gausPath = aGausPath;
              },
            );

            await imageMgr.resizeImageTo384(filePath,url!);

            if (notBlank(url)) {
              content.assets!.add(
                MomentContentDetail(
                  type: 'image',
                  url: url,
                  width: width,
                  height: height,
                  gausPath: gausPath
                ),
              );
            } else {
              cancelToken.cancel();
            }
            totalProgress +=perEach;
            overlayScreen!.updateProgress(totalProgress);
          }
        }
        else {
          String filePath = assetList.first.editedFile != null
              ? assetList.first.editedFile!.path
              : (await assetList.first.entity.originFile)!.path;
          String localFilePath = filePath;
          int width = assetList.first.editedWidth ??
              assetList.first.entity.orientatedWidth;
          int height = assetList.first.editedHeight ??
              assetList.first.entity.orientatedHeight;

          // 缩略图上传
          File? coverF = assetList.first.editedThumbFile;

          if (coverF == null) {
            File? assetFile = await assetList.first.entity.originFile;
            if (assetFile != null) {
              coverF = File(
                await downloadMgr.getTmpCachePath(
                  '${path.basenameWithoutExtension(assetFile.path)}.jpeg',
                ),
              );
              if (!coverF.existsSync() || coverF.lengthSync() == 0) {
                coverF.createSync(recursive: true);
                coverF.writeAsBytesSync(
                  (await assetList.first.entity.thumbnailDataWithSize(
                    ThumbnailSize(
                      assetList.first.entity.width,
                      assetList.first.entity.height,
                    ),
                    format: ThumbnailFormat.jpeg,
                    quality: 80,
                  ))!,
                );
              }
            }
          }

          Size fileSize = getResolutionSize(
            width,
            height,
            MediaResolution.video_standard.minSize,
          );

          String gausPath = "";
          final String? coverThumbnail = await imageMgr.upload(
            coverF!.path,
            fileSize.width.toInt(),
            fileSize.height.toInt(),
            cancelToken: cancelToken,
            enableGaussian: true,
            onSendProgress: (int sent, int total) {},
            onGaussianComplete: (String aGausPath) {
              gausPath = aGausPath;
            },
          );

          await imageMgr.resizeImageTo384(coverF.path,coverThumbnail!);

          // 视频上传
          final (url, _) = await videoMgr.upload(
              filePath,
              accurateWidth: fileSize.width.toInt(),
              accurateHeight: fileSize.height.toInt(),
              cancelToken: cancelToken,
              onCompressProgress: (double progress)
              {
                if (overlayScreen == null) return;
                overlayScreen!.curStatus.value = SubmitStatus.COMPRESSING;
                if (overlayScreen!.isOpen) overlayScreen!.updateProgress((progress / 100) / 2); //這階段的滿給50%
              },
              onCompressCallback: (String path) {
                localFilePath = path;
                overlayScreen!.reset();
                overlayScreen!.curStatus.value = SubmitStatus.WAIT_UPLOAD;
              },
              onStatusChange: (int status) {
                // 0: Display Duration,
                // 1: Preparing (0.0),
                // 2: Compressing (0.05) - No Progress | Md5 Checksum,
                // 3: Uploading (Real Progress),
                // 4: Complete(100%)
                if (status == 4) {
                  overlayScreen!.curStatus.value = SubmitStatus.UPLOADED;
                }
              },
              onSendProgress: (int bytes, int total) {
                if (overlayScreen == null) return;
                overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
                double progress = double.parse((bytes / total).toStringAsFixed(2));

                if (progress > 1) progress = 1.0; //暂时强制为 100%。

                if (overlayScreen!.isOpen) {
                  double p = (progress / 2) + 0.5 - 0.05;
                  double showProgress = p < 0.5 ? 0.5 : p; //避免在這階段出現小於50%的狀況
                  overlayScreen!.updateProgress(showProgress); //這階段的滿給95%
                }
              }
          );

          if (notBlank(url) && notBlank(coverThumbnail)) {
            objectMgr.tencentVideoMgr.moveFile(localFilePath, url);
            content.assets!.add(
              MomentContentDetail(
                type: 'video',
                url: url,
                cover: coverThumbnail,
                width: width,
                height: height,
                gausPath: gausPath,
              ),
            );
          } else {
            isFail = true;
          }
        }
      }else{
        overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
        overlayScreen!.updateProgress(0.9);
      }

      if (isFail) {
        imBottomToast(
          context,
          title: localized(momentSentFailed),
          icon: ImBottomNotifType.warning,
        );
        overlayScreen!.updateProgress(1);
        closeFloatProgress();
        return;
      }

      // visibility

      // targets 标签

      try {
        overlayScreen!.updateProgress(0.96);
        final post = await objectMgr.momentMgr.createMoment(
          content,
          visibility: viewPermission,
          mentions: mentionedFriends.map((e) => e.uid).toList(),
        );
        overlayScreen!.updateProgress(0.97);

        if (!notBlank(post)) {
          overlayScreen!.updateProgress(1);
          //ignore: use_build_context_synchronously
          imBottomToast(
            context,
            title: localized(momentSentFailed),
            icon: ImBottomNotifType.warning,
          );
          closeFloatProgress();
          return;
        }
        overlayScreen!.updateProgress(1);
        Future.delayed(const Duration(milliseconds: 200), () {
           closeFloatProgress();
           showReelToast(value: localized(reelSuccessPublished));
           Get.find<MomentHomeController>().insertPost(post);
           Get.find<MomentMyPostsController>().insertPost(post);
        });
      } catch (e, s) {
        overlayScreen!.updateProgress(1);
        closeFloatProgress();
        pdebug(e, error: e, stackTrace: s);
      }

    });
  }

  closeFloatProgress() {
    overlayScreen!.close();
  }

  void onMentionedFriends() async {
    CreateGroupBottomSheetController createGroupBottomSheetController =
        Get.put(CreateGroupBottomSheetController());
    if (mentionedFriends.isNotEmpty) {
      createGroupBottomSheetController.selectedMembers
          .assignAll(mentionedFriends);
    }

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return MentionedFriendBottomSheet(
          title: localized(momentNotifyViewer),
          placeHolder: localized(momentAtFriends),
          controller: createGroupBottomSheetController,
          confirmCallback: (List<User> mentionedFriends) {
            this.mentionedFriends.assignAll(mentionedFriends);
            createGroupBottomSheetController.closePopup();
          },
          cancelCallback: () {
            createGroupBottomSheetController.closePopup();
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateGroupBottomSheetController>();
    });
  }

  void onReorderStart(BuildContext context, int index) async {
    momentDescFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    draggedIndex.value = index;
    dragDeleteAreaHeight = MediaQuery.of(context).size.height - 150;

    HapticFeedback.mediumImpact();
  }

  void onItemPointerMove(dynamic event) async {
    if (draggedIndex.value == -1) return;

    if (!isDragging.value) {
      isDragging.value = true;
    }

    final position = event is PointerMoveEvent
        ? event.position.dy
        : event is DragUpdateDetails
            ? event.globalPosition.dy
            : 0.0;

    if (position > dragDeleteAreaHeight) {
      if (!isInDeleteArea.value) {
        HapticFeedback.mediumImpact();
      }

      isInDeleteArea.value = true;
    } else {
      isInDeleteArea.value = false;
    }
  }

  void onItemPointerUp(_) {
    if (isInDeleteArea.value) {
      onDeleteAsset(assetList[draggedIndex.value]);
    }

    isDragging.value = false;
    draggedIndex.value = -1;
    isInDeleteArea.value = false;
  }

  // =============================== 工具 ===================================
  Future<void> onPrepareMediaPicker(BuildContext context) async {
    ps = await const AssetPickerDelegate().permissionCheck();

    RequestType type = RequestType.common;
    if (assetList.isNotEmpty) {
      if (assetList.first.entity.type == AssetType.video) {
        type = RequestType.video;
      }

      if (type == RequestType.common) {
        type = RequestType.image;
      }
    }

    pickerConfig = AssetPickerConfig(
      requestType: type,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: 9 - assetList.length,
      textDelegate: Get.locale!.languageCode.contains('en')
          ? const EnglishAssetPickerTextDelegate()
          : const AssetPickerTextDelegate(),
    );
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: pickerConfig!.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );
  }
}
