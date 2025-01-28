import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/media/general_media_picker.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_post_viewer_page.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MomentMyPostsController extends GetxController {
  final double MOMENT_COVER_HEIGHT = 350;
  List<String> monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final ScrollController scrollController = ScrollController();

  final postList = <MomentPosts>[].obs;

  RxBool isLoading = false.obs;
  RxBool isClickingCover = false.obs;
  bool isCoverFocusing = false;
  RxBool isSendingPost = false.obs;
  RxBool hasText = false.obs;
  RxBool hasMore = true.obs;

  RxBool appBarIconInvert = false.obs;
  RxDouble appBarOpacity = 0.0.obs;
  RxDouble headOpacity = 1.0.obs;
  RxDouble coverTextOpacity = 0.0.obs;
  RxDouble overlayBgHeight = 150.0.obs;

  RxString coverPath = ''.obs;

  Rx<Color> appBarColor = Colors.transparent.obs;

  double lastScrollPosition = 0.0;

  RxDouble coverWidth = 0.0.obs;
  RxDouble coverHeight = 0.0.obs;

  Timer? _coverTextTimer;
  Timer? _coverHeadTimer;
  Timer? _requestTimer;

  // 资源选择器
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;

  int userId = objectMgr.userMgr.mainUser.uid;

  late AnimationController _animationController;
  late AnimationController _animationLoadingController;

  final IndicatorController indicatorController = IndicatorController();

  MomentMyPostsController({required this.userId});

  @override
  void onInit() {
    super.onInit();

    objectMgr.momentMgr.on(MomentMgr.MOMENT_COVER_UPDATE, _onCoverUpdate);
    objectMgr.momentMgr
        .on(MomentMgr.MOMENT_FRIEND_COVER_UPDATE, _onFriendCoverUpdate);

    //get local cover cache.
    if (userId == objectMgr.userMgr.mainUser.uid) {
      coverWidth.value = objectMgr.momentMgr.coverWidth;
      coverHeight.value = objectMgr.momentMgr.coverHeight;
      coverPath.value = objectMgr.momentMgr.momentCoverPath;
    } else {
      coverPath.value = objectMgr.momentMgr.getFriendCover(userId);
    }

    if (userId != objectMgr.userMgr.mainUser.uid) {
      objectMgr.momentMgr.getFriendSetting(userId);
    }

    //get local posts cache.
    List<MomentPosts> myPostList =
        objectMgr.momentMgr.getMyPostSharePreference(userId) ?? [];
    if (myPostList.isNotEmpty) {
      postList.assignAll(myPostList);
    } else {
      if ((objectMgr.appInitState.value == AppInitState.no_network ||
              objectMgr.appInitState.value == AppInitState.no_connect) &&
          userId != objectMgr.userMgr.mainUser.uid) {
        // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
      }
    }

    _initPost();
    _addListener();
  }

  @override
  void onClose() {
    objectMgr.momentMgr.off(MomentMgr.MOMENT_COVER_UPDATE, _onCoverUpdate);
    objectMgr.momentMgr
        .off(MomentMgr.MOMENT_FRIEND_COVER_UPDATE, _onFriendCoverUpdate);

    _coverTextTimer = null;
    _coverHeadTimer = null;
    _requestTimer = null;
    _animationController.dispose();
    _animationLoadingController.dispose();
    super.onClose();
  }

  void _initPost() async {
    // 加载最新的帖子
    getPost(start: 0, userId: userId);
  }

  Future<void> getPost({
    int start = 0,
    int userId = 0,
    int limit = 50,
  }) async {
    if (isLoading.value) {
      return;
    }

    if (start != 0) {
      isLoading.value = true;
      setLoadingAnimation(true);
    }

    final List<MomentPosts> newPostList =
        await objectMgr.momentMgr.getUserPost(userId, start, limit: limit);
    if (newPostList.isNotEmpty && newPostList.first.networkError) {
      //當無網路，瞬間切換有網路時，在直接刷新拿資料，雖然有網路，但未正確連接上，會有網路錯誤的問題.
      isLoading.value = false;
      if (start != 0) {
        setLoadingAnimation(false);
      }
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
      return;
    }

    if ((postList.isNotEmpty && newPostList.isEmpty) ||
        newPostList.length < 30) {
      hasMore.value = false;
    } else {
      hasMore.value = true;
    }

    if (start == 0) {
      postList.assignAll(newPostList);
    } else if (newPostList.isNotEmpty) {
      postList.addAll(newPostList);
    }

    if (start != 0) {
      isLoading.value = false;
      setLoadingAnimation(false);
    }
    update(['my_post_list'].toList(), true);
  }

  void _addListener() {
    scrollController.addListener(_onScrollListener);
  }

  void _onScrollListener() async {
    if (isClickingCover.value && !isCoverFocusing) {
      onCoverTap();
    }

    if (scrollController.offset < 0) {
      overlayBgHeight.value = 150 - scrollController.offset;
    } else {
      overlayBgHeight.value = 150 - min(150, scrollController.offset);
    }

    var heightGap = MOMENT_COVER_HEIGHT - kToolbarHeight;

    if (scrollController.offset > heightGap) {
      appBarIconInvert.value = true;

      final diff = scrollController.offset - heightGap;
      appBarOpacity.value = (diff / 15).clamp(0.0, 1.0);
    } else {
      appBarIconInvert.value = false;
      appBarOpacity.value = 0.0;
    }

    if (scrollController.position.pixels > lastScrollPosition) {
      if (scrollController.position.pixels + 800 >
              scrollController.position.maxScrollExtent &&
          !isLoading.value &&
          hasMore.value) {
        if (_requestTimer == null || !_requestTimer!.isActive) {
          final post = postList[postList.length - 1].post;

          //防止短時間內多次請求
          _requestTimer = Timer(const Duration(milliseconds: 500), () {});

          if (objectMgr.appInitState.value == AppInitState.no_network ||
              objectMgr.appInitState.value == AppInitState.no_connect) {
            // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
            return;
          }

          getPost(start: post!.id!, userId: userId);
        }
      }
    }
    lastScrollPosition = scrollController.position.pixels;
  }

  // 更新封面
  void _onCoverUpdate(_, __, data) {
    if (userId != objectMgr.userMgr.mainUser.uid) {
      return;
    }

    if (!data) {
      Toast.showToast(localized(momentUploadCoverFailed));
    }

    coverPath.value = objectMgr.momentMgr.momentCoverPath;
    if (isClickingCover.value) onCoverTap();
  }

  void updateCoverSize(String path, userId) {
    if (path.isEmpty) return;
    try {
      List<String> dimensions = objectMgr.momentMgr.getImageDimensions(path);
      if (dimensions.isNotEmpty) {
        coverWidth.value = double.parse(dimensions[0]);
        coverHeight.value = double.parse(dimensions[1]);
        objectMgr.localStorageMgr.write(
            "${LocalStorageMgr.MOMENT_COVER_SIZE}_$userId",
            dimensions.join(","));
      }
    } catch (e) {
      pdebug('get moment setting error: $e');
    }
  }

  // 更新好友封面
  void _onFriendCoverUpdate(_, __, Object? data) {
    updateCoverSize(objectMgr.momentMgr.momentFriendCoverPath[data]!, data);
    coverPath.value = objectMgr.momentMgr.momentFriendCoverPath[data]!;
  }

  void outsideTap() {
    if (isClickingCover.value) {
      onCoverTap();
    }
  }

  String getUserNickName(int userId) {
    User? data = objectMgr.userMgr.getUserById(userId);
    return objectMgr.userMgr.getUserTitle(data);
  }
  
  void routeToChat() {
    if(userId != objectMgr.userMgr.mainUser.uid){
      Chat? chat = objectMgr.chatMgr.getChatByUserId(userId);
      if(chat!=null){
        Get.find<HomeController>().pageIndex.value = 0;
        Get.find<HomeController>().tabController!.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
        Routes.toChat(chat: chat);
      }
    }
  }

  bool isSameYear(currentPostedTime, lastPostedTime) {
    DateTime current = DateTime.fromMillisecondsSinceEpoch(currentPostedTime);
    DateTime next = DateTime.fromMillisecondsSinceEpoch(lastPostedTime);
    return (current.year == next.year);
  }

  bool isShowingDate(currentPostedTime, lastPostTime) {
    DateTime current = DateTime.fromMillisecondsSinceEpoch(currentPostedTime);
    DateTime last = DateTime.fromMillisecondsSinceEpoch(lastPostTime);
    String currentYMD =
        DateFormat.yMd(Localizations.localeOf(Get.context!).toString())
            .format(current);
    String lastYMD =
        DateFormat.yMd(Localizations.localeOf(Get.context!).toString())
            .format(last);
    return !(currentYMD == lastYMD);
  }

  void onCoverTap() {
    if (_coverTextTimer != null || _coverHeadTimer != null) {
      return;
    }

    isClickingCover.value = !isClickingCover.value;
  }

  void onCoverTapDown(details) {
    isCoverFocusing = true;
  }

  void onCoverPointerUp() {
    isCoverFocusing = false;
  }

  void resetCoverStatus() {
    isClickingCover.value = false;
    isCoverFocusing = false;
  }

  void changeCoverAction(BuildContext context) async {
    resetCoverStatus();
    if (objectMgr.momentMgr.isUploadCover) {
      Toast.showToast(localized(reelUploading));
      return;
    }

    //ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: <SelectionOptionModel>[
            SelectionOptionModel(title: localized(camera)),
            SelectionOptionModel(title: localized(chooseFromGalley)),
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

    AssetEntity? entity;
    if (Platform.isIOS) {
      entity = await CamerawesomePage.openImCamera(
          enableRecording: false,
          maximumRecordingDuration: const Duration(seconds: 600),
          isMirrorFrontCamera: isMirrorFrontCamera);
    } else {
      final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const CamerawesomePage(
            enableRecording: false,
            maximumRecordingDuration: Duration(seconds: 600),
          ),
        ),
      );

      if (res == null) return;

      entity = res["result"];
    }

    if (entity == null) return;

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
      },
    )?.then((result) async {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        final asset = (result['assets'] as List<AssetPreviewDetail>).first;
        // 上传cover
        objectMgr.momentMgr.uploadCover(
          asset.editedFile?.path ?? (await asset.entity.originFile)!.path,
          asset.editedWidth ?? asset.entity.width,
          asset.editedHeight ?? asset.entity.height,
        );
      }
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
            'shouldSend': true,
          }),
        );
      },
    ).then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        Get.toNamed(
          RouteName.mediaPreviewView,
          preventDuplicates: false,
          arguments: {
            'provider': assetPickerProvider,
            'pConfig': pickerConfig,
            'showSelected': true,
            'showCaption': false,
            'showResolution': false,
          },
        )?.then((result) async {
          if (notBlank(result)) {
            if (!result.containsKey('shouldSend') || !result['shouldSend']) {
              return;
            }
            final asset = (result['assets'] as List<AssetPreviewDetail>).first;

            // 上传cover
            objectMgr.momentMgr.uploadCover(
              asset.editedFile?.path ?? (await asset.entity.originFile)!.path,
              asset.editedWidth ?? asset.entity.width,
              asset.editedHeight ?? asset.entity.height,
            );
          }
        });
      }
    });
  }

  void onCreateTab() async {
    if (isClickingCover.value) {
      isClickingCover.value = false;
      return;
    }

    if (!isClickingCover.value) {
      if (overlayScreen != null && overlayScreen!.isOpen) {
        Toast.showToast(localized(momentBtnStatusSending));
      } else {
        Get.toNamed(
          RouteName.uploadMoment,
        )?.then((post) {
          if (post == null) return;
          postList.insert(0, post);
          postList.refresh();
          scrollController.jumpTo(0);
        });
      }
    }
  }

  void insertPost(post) {
    if (post == null) return;
    postList.insert(0, post);
    postList.refresh();
    scrollController.jumpTo(0);
  }

  void onCellTap(int index, String routeName) {
    if (isClickingCover.value) {
      isClickingCover.value = false;
      return;
    }

    if (RouteName.momentDetail == routeName) {
      Get.toNamed(
        RouteName.momentDetail,
        arguments: {
          'detail': postList[index],
        },
      )?.then((value) {
        Map<String, dynamic> jsonResult = value ?? {};
        if (jsonResult['isDeleted'] ?? false) {
          Future.delayed(const Duration(milliseconds: 250), () {
            postList.removeAt(index);
          });
        }
      });
    } else {
      Get.to(
        () => MomentMyPostViewerPage(index: index,momentMyPostsController: this,),
        transition: Transition.fadeIn,
      );
    }
  }

  bool handleBackNavigation() {
    Get.back();
    return false;
  }

  loadingAnimation(var state) {
    _animationLoadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: state,
    );

    return _animationLoadingController;
  }

  setLoadingAnimation(bool isTailLoading) {
    if (isTailLoading) {
      _animationController.forward();
      _animationLoadingController.repeat();
    } else {
      _animationController.reverse();
      _animationLoadingController.stop();
    }
  }

  slideAnimation(var state) {
    return Tween<Offset>(
      begin: const Offset(0.9, -1.0),
      end: const Offset(0.9, 2.5),
    ).animate(
      CurvedAnimation(
        parent: _animationController = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: state,
        ),
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> onGoNotification() async {
    if (isClickingCover.value) {
      isClickingCover.value = false;
      return;
    }
    Get.toNamed(RouteName.momentNotification);
  }

  // =============================== 工具 ===================================
  Future<bool> onPrepareMediaPicker(BuildContext context) async {
    ps = await requestAssetPickerPermission();
    if (ps == PermissionState.denied) return false;

    pickerConfig = AssetPickerConfig(
      requestType: RequestType.image,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: 1,
      specialPickerType: SpecialPickerType.noPreview,
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
