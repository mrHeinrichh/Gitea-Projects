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
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/component/mentioned_friend_bottom_sheet.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_create/moment_create_viewer.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/link_analyzer/link_analyzer.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MomentCreateController extends GetxController {
  // 朋友圈文案输入器
  final TextEditingController momentDescTextController =
      TextEditingController();

  FocusNode momentDescFocus  = FocusNode();

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

  Rx<MomentVisibility> viewPermission = MomentVisibility.public.obs;

  RxList<User> mentionedFriends = <User>[].obs;

  final CancelToken cancelToken = CancelToken();

  RxList<User> selectedFriends = <User>[].obs;
  RxList<User> selectLabelFriends = <User>[].obs;

  RxList<Tags> selectedLabel = <Tags>[].obs;

  bool isPublish = false;

  String oldText = '';
  RxList<File> fileList = <File>[].obs;

  final linkSearchingDebounce = Debounce(const Duration(milliseconds: 1000));
  CancelToken? linkSearchCancelToken;

  Rxn<Metadata> linkPreviewData = Rxn<Metadata>();
  final isLinkLoading = false.obs;
  String metadataGausBlurHash = "";
  bool isCancelShowingLink = false;

  @override
  void onInit() {
    super.onInit();
    momentDescFocus = FocusNode();
    linkPreviewData.value = null;
    momentDescTextController.addListener(()
    {
      final newText = momentDescTextController.text;
      _onMatchLink();
      oldText = newText;
    });

    momentDescFocus.addListener(() {
      if (momentDescFocus.hasFocus) {
          isCancelShowingLink = false;
      }
    });
  }

  @override
  void dispose() {
    momentDescTextController.dispose();
    momentDescFocus.dispose();
    cancelToken.cancel();
    super.dispose();
  }

  void _onMatchLink() {
    String text = momentDescTextController.text;
    if (oldText == text){
      return;
    }

    if (text.isEmpty)
    {
      isLinkLoading.value = false;
      update(['momentLinkPreview'].toList());
      return;
    }

    if (text.startsWith('H'))
    {
      text = text[0].toLowerCase() + text.substring(1);
    }

    final temp = Regular.extractLink(text);
    final List<String> linkList = [];

    if (temp.isNotEmpty) {
      linkList.assignAll(temp.map((match) => match.group(0)!).toList());
    }

    if(isCancelShowingLink){
      return;
    }


    if (linkList.isEmpty || ShareLinkUtil.isMatchShareLink(text) || assetList.isNotEmpty)
    {
      if (linkSearchCancelToken != null) {
        linkSearchCancelToken!.cancel('Cancel By User');
        linkSearchCancelToken = null;
      }

      /// 如果有选中资源，或者有文件上传，清空预览数据
      if(assetList.isNotEmpty){
        linkPreviewData.value = null;
      }

      update(['momentLinkPreview'].toList());
      return;
    }

    assert(linkList.isNotEmpty, "Match Link must have value. Please check [ShareLinkUtil.extractLinkFromText] method to identify Regex matching pattern.");

    const uutalkDomain = 'uutalk';
    const heytalkDomain = 'heytalk';
    const uliaoDomain = 'uliao';

    String? firstMatchedLink = linkList.firstWhereOrNull((link) =>
    !link.contains(uutalkDomain) &&
        !link.contains(heytalkDomain) &&
        !link.contains(uliaoDomain));

    if (firstMatchedLink == null) {
      return;
    }

    bool shouldLoadMetadata = false;

    if (linkPreviewData.value == null)
    {
      linkPreviewData.value = Metadata()..url = firstMatchedLink;
      shouldLoadMetadata = true;
    }

    if (linkSearchCancelToken != null) {
      linkSearchCancelToken!.cancel('Cancel By User');
      linkSearchCancelToken = null;
    }

    linkSearchCancelToken = CancelToken();

    // 1. Compare linkList first item with MetaData variable
    linkSearchingDebounce.call(()
    {
      if ((
          (linkPreviewData.value != null && linkPreviewData.value!.url == firstMatchedLink) && !shouldLoadMetadata
          && isParserLink(linkPreviewData.value!))
          || (linkSearchCancelToken == null || linkSearchCancelToken!.isCancelled)) {
        return;
      }

      isLinkLoading.value = true;
      update(['momentLinkPreview'].toList());
      LinkAnalyzer.getInfoClientSide(firstMatchedLink, cancelToken: linkSearchCancelToken,).then((metadata) async
      {
        if (metadata != null)
        {
          if (notBlank(metadata.image) && metadata.image!.startsWith('http'))
          {
            downloadMgrV2.download(metadata.image!).then((DownloadResult value){
              if(value.success)
              {
                if(linkPreviewData.value!.imageWidth == null)
                {
                  if(value.localPath==null){
                    linkPreviewData.value!.image = null;
                    update(['momentLinkPreview'].toList());
                  }else{
                    isJpgFileByHeader(value.localPath!).then((isJpg){
                      if(isJpg){
                        String? result = renameFile(value.localPath, '${const Uuid().v4()}.jpg');
                        linkPreviewData.value!.image = result;
                        linkPreviewData.value!.imageWidth = "128";
                        linkPreviewData.value!.imageHeight = "128";
                      }else{
                        isPngFileByHeader(value.localPath!).then((isPng){
                          if(isPng){
                            String? result = renameFile(value.localPath, '${const Uuid().v4()}.png');
                            linkPreviewData.value!.image = result;
                            linkPreviewData.value!.imageWidth = "128";
                            linkPreviewData.value!.imageHeight = "128";
                          }else{
                            linkPreviewData.value!.image = null;
                          }});
                      }
                      update(['momentLinkPreview'].toList());
                    });
                  }
                }
              }else{
                linkPreviewData.value!.image = null;
              }
              if (metadata.hasData) {
                linkPreviewData.value = metadata;
              }
              update(['momentLinkPreview'].toList());
            });
          } else {
            metadata.image = null;
            if (metadata.hasData) {
              linkPreviewData.value = metadata;
            }
          }
        }

        isLinkLoading.value = false;
        update(['momentLinkPreview'].toList());
      }).whenComplete(() => linkSearchCancelToken = null);
    });
  }

  bool isParserLink(Metadata metadata){
    return (metadata.title != null || metadata.desc != null || metadata.imageWidth != null || metadata.image!=null);
  }

  void oTapLinkClose(){
    linkPreviewData.value = null;
    oldText = "";
    linkSearchCancelToken?.cancel(["cancel by user"]);
    isCancelShowingLink = true;
    update(['momentLinkPreview'].toList());
  }

  Future<bool> isJpgFileByHeader(String filePath) async {
    final file = File(filePath);
    final fileBytes = await file.openRead(0, 2).first;
    // JPEG 文件的头部标志是 FFD8
    return fileBytes[0] == 0xFF && fileBytes[1] == 0xD8;
  }

  Future<bool> isPngFileByHeader(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    // 读取文件的前 8 个字节
    final fileBytes = await file.openRead(0, 8).first;

    // PNG 文件的文件头
    final pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    return List<int>.from(fileBytes).take(8).toList().toString() == pngSignature.toString();
  }


  void onSelectAssets(BuildContext context) async {
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

  void onAssetSelectedCallback(BuildContext context, int index) async {
    switch (index) {
      case 0:
        if (!await checkCameraOrPhotoPermission(type: 1)) return;
        onPhoto(context);
        break;
      case 1:
        if (!await onPrepareMediaPicker(context)) return;
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
          isMirrorFrontCamera: isMirrorFrontCamera);
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
        oTapLinkClose();
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
        oTapLinkClose();
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
    var tempMeta = linkPreviewData.value;

    if (momentDescTextController.text.trim().isEmpty && assetList.isEmpty && tempMeta == null) {
      imBottomToast(
        context,
        title: localized(momentCreateContentEmpty),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    if (isLinkLoading.value || (tempMeta != null && (tempMeta.title == null && tempMeta.desc == null && tempMeta.imageWidth == null))) {
      linkSearchCancelToken?.cancel("Cancel by user");
      tempMeta = null;
    } else if (tempMeta != null && tempMeta.imageWidth == null) {
      linkSearchCancelToken?.cancel("Cancel by user");
      tempMeta.image = null;
    }

    if(!isPublish){
      isPublish = true;
    }else{
      return;
    }

    momentDescFocus.unfocus();
    FocusScope.of(Get.context!).unfocus();

    if (overlayScreen != null && !overlayScreen!.isOpen) {
      String descText = "";
      AssetEntity asset;
      if (assetList.isEmpty) {
        descText = momentDescTextController.text.trim();
        asset = AssetEntity(
            id: "",
            typeInt: 0,
            width: 0,
            height: 0,
            mimeType: "text",
            title: descText);
      } else {
        asset = assetList.first.entity;
      }
      overlayScreen!.show(asset);
    }

    tempMeta ??= Metadata()..title = MomentMgr.MOMENT_NO_LINK_CONTENT;

    final content = MomentContent(
      text: momentDescTextController.text.trim(),
      metadata: tempMeta,
      metadataGausBlurHash: metadataGausBlurHash,
      assets: <MomentContentDetail>[],
    );

    getBackPage();

    bool isFail = false;

    await resProcessLock.synchronized(() async
    {
      //鏈結圖片上傳
      if(tempMeta!.title!=MomentMgr.MOMENT_NO_LINK_CONTENT
          && tempMeta.image!=null
          && tempMeta.image!.isNotEmpty
          && tempMeta.imageWidth!=null
          && tempMeta.imageHeight!=null)
      {
          Size fileSize = getResolutionSize(
            int.parse(tempMeta.imageWidth!),
            int.parse(tempMeta.imageHeight!),
            MediaResolution.image_standard.minSize,
          );

          String? filePath = downloadMgrV2.getLocalPath(tempMeta.image!);
          filePath = renameFile(filePath, '${const Uuid().v4()}.jpg');

          if(filePath!=null){
            String gausPath = "";
            String? compressPath = await imageMgr.compressImage(
              filePath,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
            );

            final url = await imageMgr.upload(
              compressPath??filePath,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
              cancelToken: cancelToken,
              enableGaussian: true,
              storageType: StorageType.moment,
              onSendProgress: (int sent, int total) {},
              onGaussianComplete: (String aGausPath) {
                gausPath = aGausPath;
              },
            );

            await imageMgr.resizeImageTo384(filePath, url!,mini:Config().dynamicMin);

            content.metadata!.image = url;
            content.metadata!.imageWidth = fileSize.width.toString();
            content.metadata!.imageHeight = fileSize.height.toString();
            content.metadataGausBlurHash = gausPath;
          }
      }

      // 资源上传
      if (assetList.isNotEmpty) {
        if (assetList.first.entity.type == AssetType.image)
        {
          overlayScreen!.curStatus.value = SubmitStatus.UPLOADING;
          double totalProgress = 0.0;
          double perEach = (9 / assetList.length) * 0.1;

          // 图片上传
          for (int i = 0; i < assetList.length; i++)
          {
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
            String? compressPath = await imageMgr.compressImage(
              filePath,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
            );

            final url = await imageMgr.upload(
              compressPath ?? filePath,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
              cancelToken: cancelToken,
              enableGaussian: true,
              storageType: StorageType.moment,
              onSendProgress: (int sent, int total) {},
              onGaussianComplete: (String aGausPath) {
                gausPath = aGausPath;
              },
            );

            await imageMgr.resizeImageTo384(filePath, url!);

            if (notBlank(url)) {
              content.assets!.add(
                MomentContentDetail(
                    type: 'image',
                    url: url,
                    width: width,
                    height: height,
                    gausPath: gausPath),
              );
            } else {
              cancelToken.cancel();
            }

            totalProgress += perEach;
            overlayScreen!.updateProgress(totalProgress);
          }
        } else {
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
            assetList.first.videoResolution==MediaResolution.video_standard?MediaResolution.video_standard.minSize:MediaResolution.video_high.minSize,
          );

          String gausPath = "";
          final String? coverThumbnail = await imageMgr.upload(
            coverF!.path,
            fileSize.width.toInt(),
            fileSize.height.toInt(),
            cancelToken: cancelToken,
            enableGaussian: true,
            storageType: StorageType.moment,
            onSendProgress: (int sent, int total) {},
            onGaussianComplete: (String aGausPath) {
              gausPath = aGausPath;
            },
          );

          await imageMgr.resizeImageTo384(coverF.path, coverThumbnail!);

          // 视频上传
          final (url, _) = await videoMgr.upload(
            filePath,
            accurateWidth: fileSize.width.toInt(),
            accurateHeight: fileSize.height.toInt(),
            cancelToken: cancelToken,
            storageType: StorageType.moment,
            onCompressProgress: (double progress) {
              if (overlayScreen == null) return;
              overlayScreen!.curStatus.value = SubmitStatus.COMPRESSING;
              if (overlayScreen!.isOpen) {
                overlayScreen!.updateProgress((progress / 100) / 2);
              } //這階段的滿給50%
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
              double progress =
                  double.parse((bytes / total).toStringAsFixed(2));

              if (progress > 1) progress = 1.0; //暂时强制为 100%。

              if (overlayScreen!.isOpen) {
                double p = (progress / 2) + 0.5 - 0.05;
                double showProgress = p < 0.5 ? 0.5 : p; //避免在這階段出現小於50%的狀況
                overlayScreen!.updateProgress(showProgress); //這階段的滿給95%
              }
            },
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
      } else {
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
          visibility: viewPermission.value,
          targets: selectedFriends.map((e) => e.uid).toList(),
          target_tags: selectedLabel.map((e) => e.uid).toList(),
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
          if (Get.isRegistered<MomentHomeController>()){
            Get.find<MomentHomeController>().insertPost(post);
          }
          if (Get.isRegistered<MomentMyPostsController>()) {
            Get.find<MomentMyPostsController>().insertPost(post);
          }
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

  String? renameFile(String? filePath, String newFileName) {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    final newFilePath = file.parent.path + Platform.pathSeparator + newFileName;
    file.renameSync(newFilePath);
    return newFilePath;
  }

  void onPermissionSelect() {
    Get.toNamed(
      RouteName.momentPermission,
      arguments: {
        'momentVisibility': viewPermission.value,
        'selectFriends': selectedFriends,
        'selectLabel': selectedLabel,
      },
    )?.then((value) {
      if (value != null) {
        if (value is Map) {
          viewPermission.value = value['momentVisibility'] ?? viewPermission;
          selectedFriends.value = value['selectFriends'] ?? selectedFriends;
          selectedLabel.value = value['selectLabel'] ?? selectedLabel;
          selectLabelFriends.value = value['selectLabelFriends'] ?? selectLabelFriends;
        }
      }
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
  Future<bool> onPrepareMediaPicker(BuildContext context) async {
    ps = await requestAssetPickerPermission();
    if (ps == PermissionState.denied) return false;

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
    return true;
  }
}
