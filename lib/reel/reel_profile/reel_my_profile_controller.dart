import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/api/reel.dart' as r;
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_like_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_save_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ReelMyProfileController extends GetxController {
  static const String s3Folder = 'avatar';
  RxInt userId = objectMgr.userMgr.mainUser.uid.obs;

  TabController? tabController;
  int selectedTab = 0;

  Rx<ReelProfile> reelProfile = ReelProfile(
    userid: objectMgr.userMgr.mainUser.uid,
    name: objectMgr.userMgr.mainUser.username,
  ).obs;
  Rxn<File> tempAvatar = Rxn<File>();
  RxList<ReelPost> posts = RxList<ReelPost>();
  RxList<ReelPost> savedPosts = RxList<ReelPost>();
  RxList<ReelPost> likedPosts = RxList<ReelPost>();
  RxList<ReelPost> filterLikedPosts = RxList<ReelPost>();
  RxList<ReelPost> filterSavedPosts = RxList<ReelPost>();
  RxBool isLoading = false.obs;

  RxList tabBarList = [
    'reel_post',
    'reel_draft',
    'reel_saved',
    'reel_liked',
    // localized(postParam, params: ["0"]),
    // localized(draft),
    // localized(saved),
    // localized(liked),
  ].obs;

  ReelMyProfileController() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      updateController();
    });
  }

  clearCache() {
    tabController?.dispose();
    tabController = null;
  }

  @override
  onClose() {
    // posts.clear();
    super.onClose();
  }

  void handleTabSelection() {
    if (tabController!.indexIsChanging) {
      // Handle tab change
      switch (tabController!.index) {
        case 0:
          getPosts(userId.value);
          break;
        case 1:
          break;
        case 2:
          getSavedPosts();
          break;
        case 3:
          getLikedPosts();
          break;
        default:
          break;
      }
      // You can perform actions based on the selected tab index here
    }
  }

  Future<ReelProfile?> getProfile(int userId) async {
    this.userId.value = userId;
    return await ReelProfileMgr.instance.getUserProfile(userId);
  }

  Future<List<ReelPost>> getPosts(int userId, {int? lastId}) async {
    try {
      final list = await ReelPostMgr.instance.getPosts(userId, lastId: lastId);
      if (list.isNotEmpty) {
        if (lastId == null) {
          posts.assignAll(list);
        } else {
          posts.addAll(list);
        }
      }

      return list;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return [];
    }
  }

  Future<List<ReelPost>> getSavedPosts({int? lastId}) async {
    try {
      final list = await ReelPostMgr.instance
          .getSavedPosts(userId.value, lastId: lastId);
      if (list.isNotEmpty) {
        if (lastId == null) {
          savedPosts.assignAll(list);
          list.removeWhere((element) => (element.deleteAt.value != null && element.deleteAt.value! > 0) || !notBlank(element.file.value?.path));
          filterSavedPosts.assignAll(list);
        } else {
          savedPosts.addAll(list);
          list.removeWhere((element) => (element.deleteAt.value != null && element.deleteAt.value! > 0) || !notBlank(element.file.value?.path));
          filterSavedPosts.addAll(list);
        }
      }
      return list;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return [];
    }
  }

  Future<List<ReelPost>> getLikedPosts({int? lastId}) async {
    try {
      final list = await ReelPostMgr.instance
          .getLikedPosts(userId.value, lastId: lastId);
      if (list.isNotEmpty) {
        if (lastId == null) {
          likedPosts.assignAll(list);
          list.removeWhere((element) => (element.deleteAt.value != null && element.deleteAt.value! > 0) || !notBlank(element.file.value?.path));
          filterLikedPosts.assignAll(list);
        } else {
          likedPosts.addAll(list);
          list.removeWhere((element) => (element.deleteAt.value != null && element.deleteAt.value! > 0) || !notBlank(element.file.value?.path));
          filterLikedPosts.addAll(list);
        }
      }
      return list;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return [];
    }
  }

  Future<void> updateController() async {
    final futures = <Future>[];
    userId.value = objectMgr.userMgr.mainUser.uid;
    reelProfile.value = ReelProfileMgr.instance.getCurrentProfile(userId.value);
    futures.add(getProfile(userId.value));
    futures.add(getPosts(userId.value));
    await Future.wait(futures);
  }

  RxList<ReelPost> getPostForManaging(ReelPostType type) {
    switch (type) {
      case ReelPostType.save: //收藏
        return filterSavedPosts;
      case ReelPostType.liked: //點讚
        return filterLikedPosts;
      case ReelPostType.post:
      // case ReelPostType.draftRepost: //已發貼文存草稿
      // case ReelPostType.draft: //草稿
      default:
        return posts; //貼文
    }
  }

  Future<bool> updateProfileInfo({
    String? name,
    String? bio,
    String? profilePic,
    String? backgroundPic,
  }) async {
    bool success = await ReelProfileMgr.instance.updateUserInfo(
      reelProfile.value,
      name: name,
      bio: bio,
      profilePic: profilePic,
      backgroundPic: backgroundPic,
    );
    return success;
  }

  List<RxList<ReelPost>> listForSynchronizingData(ReelPostType type) {
    switch (type) {
      case ReelPostType.save:
        return [];
      case ReelPostType.liked:
        return [];
      default:
        return [filterLikedPosts, filterSavedPosts];
    }
  }

  void onSave() {
    if (tempAvatar.value == null) {
      Get.back();
      return;
    }
    onUpdateProfile();
  }

  Future<String?> uploadPhoto(File imageFile, String uploadKey) async {
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      cancelToken: CancelToken(),
    );

    return imageUrl;
  }

  void onUpdateProfile() async {
    isLoading(true);
    String uploadPath = generateAvatarUrl();
    String profilePath = "";
    if (tempAvatar.value != null) {
      String? imgUrl = await uploadPhoto(tempAvatar.value!, uploadPath);
      if (notBlank(imgUrl)) {
        String? cachePath = downloadMgr.checkLocalFile(
          imgUrl!,
          mini: Config().messageMin,
        );

        if (cachePath == null) {
          await cacheMediaMgr.downloadMedia(
            imgUrl,
            mini: Config().messageMin,
          );
        }

        profilePath = removeEndPoint(imgUrl);
      }

      if (notBlank(profilePath)) {
        try {
          bool success = await updateProfileInfo(profilePic: profilePath);
          isLoading(false);

          if (success) {
            Get.back();
            // Toast.showSnackBar(context: context, message: localized(profileUpdated));
            imBottomToast(
              navigatorKey.currentContext!,
              title: localized(reelProfileUpdated),
              icon: ImBottomNotifType.success,
            );
          }
        } on AppException catch (e) {
          imBottomToast(
            navigatorKey.currentContext!,
            title: e.getMessage(),
            icon: ImBottomNotifType.warning,
          );
          // Toast.showToast(e.getMessage());
          isLoading(false);
        }
      }
    }
  }

  void deletePosts(ReelPostType type) async {
    var currentPosts = getPostForManaging(type);
    var postsToDelete = currentPosts.where((p0) => p0.isSelected).toList();
    List<int> ids = [];
    for (var element in postsToDelete) {
      element.isSelected = false;
      ids.add(element.id.value!);
      switch (type) {
        case ReelPostType.save:
          break;
        case ReelPostType.liked:
          element.isLiked.value = false;
          element.likedCount.value = element.likedCount.value! - 1;
          break;
        default:
          break;
      }
    }
    currentPosts.removeWhere((element) => postsToDelete.contains(element));

    //若另外两道list也有相同视频，也需要删
    listForSynchronizingData(type).forEach((element) {
      element.removeWhere((element) => ids.contains(element.id.value!));
    });

    //主页同步（暂时不做主页同步）
    // ReelController controller = Get.find<ReelController>();
    // controller.synchronizeDeletedIds(ids);

    try {
      switch (type) {
        case ReelPostType.save: //收藏
          ReelSaveMgr.instance.updateSave(postsToDelete, false);
          break;
        case ReelPostType.liked: //点赞
          ReelLikeMgr.instance.updateLike(postsToDelete, false);
          break;
        case ReelPostType.post: //貼文
          await r.deletePosts(ids);
          break;
        case ReelPostType.draftRepost: //已發貼文存草稿
        case ReelPostType.draft: //草稿
        default:
          break;
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
    //更新影片数量
    await updateController();
  }

  final isClear = false.obs;
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  late CommonAlbumController commonAlbumController;
  void showPickPhotoOption(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (Get.isRegistered<CommonAlbumController>()) {
      String commonAlbumTag = "200";
      commonAlbumController =
          Get.find<CommonAlbumController>(tag: commonAlbumTag);
    } else {
      commonAlbumController =
          Get.put(CommonAlbumController(), tag: commonAlbumTag);
    }

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext c) {
        return CupertinoActionSheet(
          actions: [
            if (!objectMgr.loginMgr.isDesktop)
              Container(
                color: Colors.white,
                child: OverlayEffect(
                  child: CupertinoActionSheetAction(
                    onPressed: () {
                      if (objectMgr.callMgr.getCurrentState() !=
                          CallState.Idle) {
                        Toast.showToast(localized(toastEndCallFirst));
                        return;
                      }
                      getCameraPhoto(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      localized(takeAPhoto),
                      style: jxTextStyle.textStyle20(color: themeColor),
                    ),
                  ),
                ),
              ),
            Container(
              color: Colors.white,
              child: OverlayEffect(
                child: CupertinoActionSheetAction(
                  onPressed: () async {
                    Get.back();
                    await getGalleryPhoto(context);
                  },
                  child: Text(
                    localized(chooseFromGalley),
                    style: jxTextStyle.textStyle20(color: themeColor),
                  ),
                ),
              ),
            ),
            // Visibility(
            //   visible: !isClear.value,
            //   child: Container(
            //     color: Colors.white,
            //     child: OverlayEffect(
            //       child: CupertinoActionSheetAction(
            //         onPressed: () {
            //           clearPhoto();
            //           Get.back();
            //           // Navigator.pop(context);
            //         },
            //         child: Text(
            //           localized(deletePhoto),
            //           style: jxTextStyle.textStyle16(color: colorRed),
            //         ),
            //       ),
            //     ),
            //   ),
            // )
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              // Navigator.pop(context);
              Get.back();
            },
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle20(color: themeColor),
            ),
          ),
        );
      },
    );
  }

  getCameraPhoto(BuildContext context) {
    checkPermission().then((isGranted) async {
      if (isGranted) {
        AssetEntity? entity;
        if (await isUseImCamera) {
          entity = await CamerawesomePage.openImCamera(
              isMirrorFrontCamera: isMirrorFrontCamera);
        } else {
          final Map<String, dynamic>? res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const CamerawesomePage(),
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
          processImage(entity);
        }
      }
    });
  }

  processImage(AssetEntity asset) async {
    File? assetFile = await asset.file;
    if (assetFile != null) {
      File? croppedFile = await cropImage(assetFile);
      if (croppedFile != null) {
        File? compressedFile = await getThumbImageWithPath(
          croppedFile,
          asset.width,
          asset.height,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'head',
        );
        tempAvatar.value = compressedFile;
        isClear(false);
        // validProfile.value = didChangeDetails();
      }
    } else {
      Toast.showToast(localized(photoGetFailed));
    }
  }

  processImageDesktop(File assetFile) async {
    Uint8List initialImageData = assetFile.readAsBytesSync();
    var decodedImage = await decodeImageFromList(initialImageData);

    Size fileSize = getImageCompressedSize(
      decodedImage.width,
      decodedImage.height,
    );

    File? compressedFile = await getThumbImageWithPath(
      assetFile,
      fileSize.width.toInt(),
      fileSize.height.toInt(),
      savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      sub: 'head',
    );

    tempAvatar.value = compressedFile;
    isClear(false);
    // validProfile.value = didChangeDetails();
  }

  getGalleryPhoto(BuildContext context) async {
    if (objectMgr.loginMgr.isDesktop) {
      try {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png'],
        );
        final XFile? file =
            await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

        if (file != null) {
          await processImageDesktop(File(file.path));
        }
      } catch (e) {
        pdebug('.......................$e');
      }
    } else {
      try {
        pickerConfig = AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
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
        );
        provider!.addListener(() {
          if (provider!.selectedAssets.isNotEmpty) {
            Get.back();
          }
        });
        //初始化共用相冊元件
        commonAlbumController.init(context);
        //取得選取的相片callback
        commonAlbumController.selectedAction =
            (AssetEntity selectedFile) async {
          Get.until(
            (route) => route.settings.name == RouteName.commonAlbumView,
          );
          Navigator.pop(context);
          provider?.selectAsset(selectedFile);
        };
        //設置共用相冊
        await commonAlbumController.onPrepareMediaPicker();

        checkPermission().then((isGranted) {
          if (isGranted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ProfilePhotoPicker(
                provider: provider!,
                pickerConfig: pickerConfig!,
                ps: PermissionState.authorized,
                isUseCommonAlbum: true,
              ),
            ).then((asset) async {
              if (provider!.selectedAssets.isNotEmpty) {
                await processImage(provider!.selectedAssets.first);
                provider!.selectedAssets = [];
                provider!.removeListener(() {});
                pickerConfig = null;
                provider = null;
              }
            });
          }
        });
      } catch (e) {
        openSettingPopup(
          Permissions()
              .getPermissionsName([Permission.camera, Permission.photos]),
        );
      }
    }
  }

  generateAvatarUrl() {
    String path =
        "$s3Folder/${userId.value}/reel/${DateTime.now().millisecondsSinceEpoch}";
    return path;
  }

  onReturnFromSave() {
    Get.back();
    selectedTab = 2;
    if (tabController != null) {
      tabController?.animateTo(2);
    }
  }
}
