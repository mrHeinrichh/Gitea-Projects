import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/media/general_media_picker.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_create/moment_publish_dialog.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MomentHomeController extends GetxController {
  final double MOMENT_COVER_HEIGHT = 350;
  final ScrollController scrollController = ScrollController();
  Map<int, GlobalKey> momentCellKey = {};

  Timer? _coverTextTimer;
  Timer? _coverHeadTimer;

  bool isLoading = false;
  final postList = <MomentPosts>[].obs;

  RxBool hasMore = true.obs;
  RxString coverPath = ''.obs;
  RxBool isClickingCover = false.obs;
  bool isCoverFocusing = false;
  RxBool appBarIconInvert = false.obs;
  RxDouble appBarOpacity = 0.0.obs;

  RxDouble overlayBgHeight = 150.0.obs;

  RxDouble headOpacity = 1.0.obs;
  RxDouble coverTextOpacity = 0.0.obs;

  // 资源选择器
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;

  late TextEditingController inputController;
  final FocusNode inputFocusNode = FocusNode();
  RxBool isCommentInputExpand = false.obs;

  RxBool isSwitchingBetweenStickerAndKeyboard = false.obs;
  final stickerDebounce = Debounce(const Duration(milliseconds: 600));

  // 展示表情输入
  RxBool showFaceView = false.obs;
  Timer? onDeleteTimer;

  // 被回复的post id
  int? commentRepliedPostIdx;
  int? commentRepliedPostId;
  int? commentRepliedUserId;

  RxBool hasText = false.obs;
  RxBool isSendingPost = false.obs;

  final Rx<bool> isSending = false.obs;
  final Rx<bool> isDone = false.obs;
  final Rx<bool> isFailed = false.obs;
  bool isShowLoading = false;

  RxInt notificationStrongCount = 0.obs;
  RxList<MomentDetailUpdate> notificationDetailList =
      <MomentDetailUpdate>[].obs;

  double lastScrollPosition = 0.0;

  var keyboardHeights = 0.0.obs;

  late AnimationController _animationController;
  late AnimationController _animationLoadingController;

  var isSkeletonLoading = false.obs;
  var isSkeletonAnimationFinish = false.obs;
  var isAddFade = false.obs;
  double skeletonHeight = 118;
  Completer<bool> skeletonCompleter = Completer();

  @override
  void onInit() {
    super.onInit();
    isSkeletonLoading.value = objectMgr.momentMgr.postList.isEmpty;
    isAddFade.value = isSkeletonLoading.value;
    inputController = TextEditingController();

    coverPath.value = objectMgr.momentMgr.momentCoverPath;

    objectMgr.momentMgr.on(MomentMgr.MOMENT_COVER_UPDATE, _onCoverUpdate);
    objectMgr.momentMgr.on(MomentMgr.MOMENT_POST_DELETE, _onMomentDelete);
    objectMgr.momentMgr.on(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onNotificationUpdate,
    );
    _addListener();

    objectMgr.momentMgr.getSetting();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //先取一次資料
      _initNotification();
      _initPost();
    });
  }

  @override
  void onClose() {
    if (Get.isRegistered<MomentHomeController>()) {
      Get.delete<MomentHomeController>();
    }
    objectMgr.momentMgr.requestTotalPostsLength = 0;
    scrollController.removeListener(_onScrollListener);
    scrollController.dispose();

    inputFocusNode.removeListener(_onInputFocusChanged);
    inputController.removeListener(_onTextChanged);
    inputController.dispose();

    objectMgr.momentMgr.off(MomentMgr.MOMENT_COVER_UPDATE, _onCoverUpdate);
    objectMgr.momentMgr.off(MomentMgr.MOMENT_POST_DELETE, _onMomentDelete);
    objectMgr.momentMgr.off(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onNotificationUpdate,
    );
    _animationController.dispose();
    _animationLoadingController.dispose();
    super.onClose();
  }

  void _onInputFocusChanged() {
    if (inputFocusNode.hasFocus) {
      if (showFaceView.value) {
        isSwitchingBetweenStickerAndKeyboard.value = true;
        stickerDebounce.call(() {
          isSwitchingBetweenStickerAndKeyboard.value = false;
        });
      }

      showFaceView.value = false;
    } else {
      if (!showFaceView.value) {
        isCommentInputExpand.value = false;
      }
    }
  }

  void _onTextChanged() {
    if (inputController.text.length >= 4096) {
      Toast.showToast(localized(errorMaxCharInput));
    }

    if (inputController.text.trim().isEmpty && hasText.value) {
      hasText.value = false;
    } else if (inputController.text.trim().isNotEmpty && !hasText.value) {
      hasText.value = true;
    }
  }

  void closeKeyboard() {
    inputController.clear();
    inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void outsideTap() {
    inputFocusNode.unfocus();
    showFaceView.value = false;
    isCommentInputExpand.value = false;
    if (isClickingCover.value) {
      onCoverTap();
    }
    inputController.clear();
    FocusScope.of(Get.context!).unfocus();
  }

  // 更新封面
  void _onCoverUpdate(_, __, data) {
    if (!data) {
      Toast.showToast(localized(momentUploadCoverFailed));
    }

    if (coverPath.value == objectMgr.momentMgr.momentCoverPath) return;

    coverPath.value = objectMgr.momentMgr.momentCoverPath;
    if (isClickingCover.value) onCoverTap();
  }

  void _onMomentDelete(_, __, Object? data) {
    if (data is! int) return;
    postList.removeWhere((element) => element.post!.id == data);
  }

  void _onNotificationUpdate(_, __, ___) {
    notificationDetailList
        .assignAll(objectMgr.momentMgr.notificationStrongDetailList);
    notificationStrongCount.value = objectMgr.momentMgr.notificationStrongCount;
  }

  void _addListener() {
    scrollController.addListener(_onScrollListener);

    inputFocusNode.addListener(_onInputFocusChanged);
    inputController.addListener(_onTextChanged);
  }

  void _onScrollListener() async {
    if (scrollController.position.pixels + 800 >
            scrollController.position.maxScrollExtent &&
        !isLoading &&
        hasMore.value &&
        !isSkeletonLoading.value) {
      final post = postList[postList.length - 1].post;
      getPost(start: post!.createdAt!, postId: post.id!, userId: post.userId!);
    }

    if (isClickingCover.value && !isCoverFocusing) {
      onCoverTap();
    }

    if (scrollController.offset > 500) {
      return;
    }

    if (scrollController.offset < 0) {
      overlayBgHeight.value = 150 - scrollController.offset;
    } else {
      overlayBgHeight.value = 150 - min(150, scrollController.offset);
    }

    const heightGap = 330 - kToolbarHeight;
    if (scrollController.offset > heightGap) {
      appBarIconInvert.value = true;

      final diff = scrollController.offset - heightGap;
      appBarOpacity.value = (diff / 15).clamp(0.0, 1.0);
    } else {
      appBarIconInvert.value = false;
      appBarOpacity.value = 0.0;
    }
  }

  void _initNotification() async {
    notificationDetailList
        .assignAll(objectMgr.momentMgr.notificationStrongDetailList);
    notificationStrongCount.value = objectMgr.momentMgr.notificationStrongCount;

    objectMgr.momentMgr.clearNotificationInfo();

    MomentNotificationResponse notifyList =
        await objectMgr.momentMgr.getNotificationList(
      startIdx: 0,
      limit: notificationStrongCount.value,
    );

    if (!notBlank(notifyList.notifications)) {
      objectMgr.momentMgr.clearNotificationList();
      return;
    }

    objectMgr.momentMgr.notificationStrongDetailList =
        notifyList.notifications ?? [];

    notificationDetailList
        .assignAll(objectMgr.momentMgr.notificationStrongDetailList);
    notificationStrongCount.value = objectMgr.momentMgr.notificationStrongCount;
  }

  void skeletonDone() {
    Future.delayed(const Duration(milliseconds: 300), () {
      isSkeletonLoading.value = false;
      isSkeletonAnimationFinish.value = true;
      isAddFade.value = false;
      setLoadingAnimation(false);
    });
  }

  Future<void> performSkeleton() async {
    //必須等待一次shimmer完成
    final shimmerFuture = Future.delayed(const Duration(seconds: 2));
    final requestFuture = getPost();
    await Future.wait([shimmerFuture, requestFuture]);
    skeletonDone();
  }

  void _initPost() async {
    if (objectMgr.momentMgr.postList.isEmpty) {
      setLoadingAnimation(true);
      performSkeleton();
    } else {
      postList.assignAll(objectMgr.momentMgr.postList);
      setLoadingAnimation(true);
      Future.delayed(const Duration(seconds: 1), (){
        getPost().then((value) => setLoadingAnimation(false));
      });
    }
  }

  Future<void> getPost({
    int start = 0,
    int postId = 0,
    int userId = 0,
  }) async {
    if (isLoading) return;
    isLoading = true;

    if (start != 0) {
      setLoadingAnimation(true);
    }

    if (start == 0) {
      objectMgr.momentMgr.clearNotificationInfo();
    }

    final List<MomentPosts> newPostList =
        await objectMgr.momentMgr.getStories(start, postId, userId);

    if (newPostList.isNotEmpty && newPostList.first.networkError) {
      //當無網路，瞬間切換有網路時，在直接刷新拿資料，雖然有網路，但未正確連接上，會有網路錯誤的問題.
      isLoading = false;
      if (start != 0) {
        setLoadingAnimation(false);
      }
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
      return;
    }

    if (postList.isNotEmpty && newPostList.isEmpty) {
      hasMore.value = false;
    } else {
      hasMore.value = true;
    }

    if (start == 0 && newPostList.isNotEmpty) {
      postList.assignAll(newPostList);
    } else if (newPostList.isNotEmpty) {
      postList.addAllUnique(newPostList);
    } else if (start == 0 && postList.isNotEmpty && newPostList.isEmpty) {
      postList.clear();
    }

    if (start != 0) {
      setLoadingAnimation(false);
    }

    isLoading = false;
  }

  void freshPost() {
    objectMgr.momentMgr.requestTotalPostsLength = 0;
  }

  void backAction() {
    if (!isClickingCover.value) {
      Get.back();
    }
  }

  bool handleBackNavigation() {
    Get.back();
    return false;
  }

  void onCreateTab() async {
    if (!isClickingCover.value) {
      if (overlayScreen != null && overlayScreen!.isOpen) {
        Toast.showToast(localized(momentBtnStatusSending));
      } else {
        inputFocusNode.unfocus();
        closeKeyboard();
        Get.toNamed(
          RouteName.uploadMoment,
        )?.then((post) {
          if (post == null) return;
          postList.insert(0, post);
          postList.refresh();
          scrollController.jumpTo(0);
        });
      }
    } else {
      isClickingCover.value = !isClickingCover.value;
    }
  }

  void insertPost(post) {
    if (post == null) return;
    postList.insert(0, post);
    postList.refresh();
    scrollController.jumpTo(0);
  }

  void updatePost(MomentPosts post, MomentVisibility momentVisibility,
      List<User> selectedFriends, List<Tags> selectedLabel) async {
    onShowLoadingDialog(Get.context!);

    List<int> tagUid = selectedLabel.map((e) => e.uid).toList();
    List<int> targetUid = selectedFriends.map((e) => e.uid).toList();
    bool result = await objectMgr.momentMgr.updateMomentVisibilityPost(
        post, momentVisibility,
        targets: targetUid, target_tags: tagUid);
    isDone.value = false;
    isSending.value = false;
    if (!result) {
      isFailed.value = true;
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      onCloseLoadingDialog(Get.context!);
    });
  }

  void onShowLoadingDialog(BuildContext context) {
    isSending.value = true;
    isFailed.value = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
          () => MomentPublishDialog(
            isSending: isSending.value,
            isDone: isDone.value,
            isFailed: isFailed.value,
            sendingLocalizationKey: localized(momentModifying),
            doneLocalizationKey: localized(momentModified),
            failedLocalizationKey: localized(momentModificationFailed),
          ),
        );
      },
    );
    isShowLoading = true;
  }

  void onCloseLoadingDialog(BuildContext context) {
    if (isShowLoading) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.of(context).pop();
        isShowLoading = false;
      });
    }
  }

  void onCoverTap() {
    inputFocusNode.unfocus();
    showFaceView.value = false;
    isCommentInputExpand.value = false;

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

    closeKeyboard();

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
                titleTextStyle: jxTextStyle.textStyle20(color: themeColor)),
            SelectionOptionModel(
                title: localized(chooseFromGalley),
                titleTextStyle: jxTextStyle.textStyle20(color: themeColor)),
          ],
          callback: (i) => onAssetSelectedCallback(context, i),
        );
      },
    );
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

  void slideAnimationState(bool status) {
    isLoading
        ? _animationController.forward()
        : _animationController.reactive();
  }

  Future<void> onNotificationTap() async {
    if (isClickingCover.value) {
      isClickingCover.value = !isClickingCover.value;
      return;
    }
    Get.toNamed(RouteName.momentNotification);
  }

  // void onMyPostsTap(int uid,var key) async {
  void onMyPostsTap(int uid) async {
    if (isClickingCover.value) {
      isClickingCover.value = !isClickingCover.value;
      return;
    }

    closeKeyboard();

    Get.toNamed(
      RouteName.momentMyPosts,
      arguments: {
        'userId': uid,
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
          builder: (BuildContext context) => CamerawesomePage(
            enableRecording: false,
            maximumRecordingDuration: const Duration(seconds: 600),
            onResult: (result) {
              if (!notBlank(result)) return;

              entity = result["result"];
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
                  "isFromPhoto": false,
                  'backAction': () {
                    // 按返回键
                    if (Platform.isIOS) onPhoto(context);
                  },
                },
              )?.then((result) async {
                if (notBlank(result)) {
                  if (!result.containsKey('shouldSend') ||
                      !result['shouldSend']) {
                    return;
                  }

                  final asset =
                      (result['assets'] as List<AssetPreviewDetail>).first;
                  // 上传cover
                  objectMgr.momentMgr.uploadCover(
                    asset.editedFile?.path ??
                        (await asset.entity.originFile)!.path,
                    asset.editedWidth ?? asset.entity.width,
                    asset.editedHeight ?? asset.entity.height,
                  );

                  if (!Platform.isIOS) Get.back();
                }
              });
            },
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
        "isFromPhoto": false,
        'backAction': () {
          // 按返回键
          if (Platform.isIOS) onPhoto(context);
        },
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
              onSelectFromGallery(context);
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

  void clickHead({String? userId}) {
    // Get.toNamed(RouteName.momentDetail, arguments: user_id);
  }

  void enterMomentDetail(BuildContext context, MomentPosts momentPosts) async {
    Get.toNamed(
      RouteName.momentDetail,
      arguments: {
        'detail': momentPosts,
      },
    );
  }

  void onCommentPost() async {
    if (inputController.text.trim().isEmpty ||
        commentRepliedPostId == null ||
        commentRepliedPostIdx == null) {
      inputController.clear();
      inputFocusNode.unfocus();
      commentRepliedPostIdx = null;
      commentRepliedPostId = null;
      commentRepliedUserId = null;
      isCommentInputExpand.value = false;
      update(['input_text_field'].toList(), true);
      return;
    }

    if (isSendingPost.value) {
      return;
    }

    isSendingPost.value = true;

    final post = postList[commentRepliedPostIdx!];

    // commentRepliedUserId
    final result = await objectMgr.momentMgr.onCommentPost(
      commentRepliedPostId!,
      inputController.text.trim(),
      replyUserId: commentRepliedUserId ?? 0,
    );

    if (result) {
      final commentDetail = await objectMgr.momentMgr.getMomentCommentDetail(
        commentRepliedPostId!,
        limit: 1000,
      );
      if (commentDetail == null) {
        post.commentDetail!.totalCount = post.commentDetail!.totalCount! + 1;
        post.commentDetail!.comments!.add(
          MomentComment(
            id: 0,
            userId: objectMgr.userMgr.mainUser.uid,
            postId: post.post!.id,
            replyUserId: commentRepliedUserId,
            content: inputController.text,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        postList[commentRepliedPostIdx!] = post;
        objectMgr.momentMgr.updateMoment(post);
        inputController.clear();
        inputFocusNode.unfocus();
        commentRepliedPostIdx = null;
        commentRepliedPostId = null;
        commentRepliedUserId = null;
        isCommentInputExpand.value = false;
        update(['input_text_field'].toList(), true);

        objectMgr.momentMgr.event(
          objectMgr.momentMgr,
          MomentMgr.MOMENT_POST_UPDATE,
          data: post,
        );
        return;
      }

      post.commentDetail = commentDetail;
      postList[commentRepliedPostIdx!] = post;
      objectMgr.momentMgr.updateMoment(post);
      inputController.clear();
      inputFocusNode.unfocus();
      commentRepliedPostIdx = null;
      commentRepliedPostId = null;
      commentRepliedUserId = null;
      isCommentInputExpand.value = false;

      update(['input_text_field'].toList(), true);
      objectMgr.momentMgr.event(
        objectMgr.momentMgr,
        MomentMgr.MOMENT_POST_UPDATE,
        data: post,
      );
    }

    isSendingPost.value = false;
  }

  double get getKeyboardHeight {
    if (keyboardHeight.value == 0) {
      if (KeyBoardObserver.instance.keyboardHeightOpen < 200 &&
          keyboardHeight.value < 200) {
        keyboardHeight.value = getPanelFixHeight;
        KeyBoardObserver.instance.keyboardHeightOpen = getPanelFixHeight;
      } else {
        keyboardHeight.value = KeyBoardObserver.instance.keyboardHeightOpen;
        return keyboardHeight.value;
      }
      if (Platform.isIOS) {
        return 336;
      } else {
        return 240;
      }
    }
    return keyboardHeight.value < MediaQuery.of(Get.context!).viewInsets.bottom
        ? MediaQuery.of(Get.context!).viewInsets.bottom
        : keyboardHeight.value;
  }

  double get getPanelFixHeight {
    if (Platform.isIOS) {
      var sWidth = 1;
      var sHeight = 1;
      if (sWidth == 430 && sHeight == 932) {
        return 346;
      } else if (sWidth == 375 && sHeight == 667) {
        ///iphone SE
        return 260;
      } else {
        return 336;
      }
    } else {
      return 294;
    }
  }

  void onEmojiClick() {
    /// 已经打开表情窗口 并且 键盘没有出现
    if (showFaceView.value) {
      showFaceView.value = false;
      inputFocusNode.requestFocus();

      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
    } else {
      showFaceView.value = true;
      inputFocusNode.unfocus();
    }
  }

  void addEmoji(String emoji) {
    inputController.text = inputController.text + emoji;
  }

  void onTextDeleteTap() {
    final originalText = inputController.text;
    final newText = originalText.characters.skipLast(1).string;
    inputController.text = newText;
  }

  void onTextDeleteLongPress() {
    onDeleteTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!showFaceView.value ||
          !isCommentInputExpand.value ||
          inputFocusNode.hasFocus) {
        onDeleteTimer?.cancel();
        onDeleteTimer = null;
        return;
      }
      onTextDeleteTap();
    });
  }

  void onTextDeleteLongPressEnd(_) {
    onDeleteTimer?.cancel();
    onDeleteTimer = null;
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

extension UniqueAddAllMomentPosts on List<MomentPosts> {
  void addAllUnique(Iterable<MomentPosts> iterable) {
    Set<String> existingIds =
        map((e) => "${e.post!.id}${e.post!.userId}").toSet(); // 获取当前列表中所有的id
    for (var element in iterable) {
      if (!existingIds.contains("${element.post!.id}${element.post!.userId}")) {
        add(element);
        existingIds.add("${element.post!.id}${element.post!.userId}"); // 更新id集合
      }
    }
  }
}
