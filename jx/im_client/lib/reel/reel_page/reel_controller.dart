import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/moment_create/moment_publish_dialog.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_share_mgr.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/services/preload_page_view.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/wake_lock_utils.dart';

enum ReelTagBackFromEnum { reelItem, reelPreview }

class ReelController extends GetxController with GetTickerProviderStateMixin {
  static const int cacheSegmentCount = 2;

  static const int cacheVideoCount = 5;

  static const int FOLLOW_TAB = 1;
  static const int RECOMMEND_TAB = 2;

  final Rxn<int> currentTab = Rxn<int>();

  int currentPage = 0;
  final PreloadPageController pageController = PreloadPageController();
  Rxn<ReelCommentController> tempReelCommentController =
      Rxn<ReelCommentController>();

  RxList<ReelPost> postList = <ReelPost>[].obs;

  RxBool isLoading = false.obs;
  RxBool isScrolling = false.obs;
  RxBool actualScrolling = false.obs;
  RxBool triggerSwipeUp = false.obs;

  bool get isCurrentlyPlaying =>
      currentVideoStream.value?.state.value == TencentVideoState.PLAYING;
  bool toPlay = false;

  bool isPlaying = false;

  late TencentVideoStreamMgr videoStreamMgr;
  late StreamSubscription videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  TabController? tabController;
  RxInt selectedBottomIndex = 0.obs;
  RxBool isEnteringScreen = true.obs;
  final List<Function> _enteringScreenFunctions = [];

  @override
  void onInit() {
    super.onInit();
    videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
    videoStreamSubscription =
        videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);

    VolumePlayerService.sharedInstance.onClose();
    asyncInit();
    //
    tabController = TabController(
      length: 3,
      vsync: this,
    );

    prepareListeners();
    WakeLockUtils.enable();

    Future.delayed(const Duration(milliseconds: 250), () {
      //页面 切入250毫秒后（route transition时间）才更新tab数值
      currentTab.value = 2;
      isEnteringScreen.value = false;
      for (var fn in _enteringScreenFunctions) {
        fn.call();
      }
      _enteringScreenFunctions.clear();
    });
  }

  void asyncInit() async {
    List<ReelPost> posts;
    if (objectMgr.reelCacheMgr.cacheReels.isEmpty) {
      posts = objectMgr.reelCacheMgr.getLocalPosts();
    } else {
      posts = objectMgr.reelCacheMgr.cacheReels;
    }

    if (posts.isNotEmpty) {
      List<ReelPost> items = ReelPostMgr.instance
          .syncData(posts); //需要把数据同步至数据源，否则从缓存读取的数据更新关注状态或者名字头像时不会得到更新。
      postList.assignAll(items);
      precachePostAsset();
    } else {
      isLoading.value = true;
      await preloadPostList(downloadData: false);
    }

    if (isEnteringScreen.value) {
      _enteringScreenFunctions.add(() {
        // 若还在跳转中，则等待结束进行接下来的操作（二级数据操作）
        objectMgr.reelCacheMgr.refreshCache();
      });
    } else {
      objectMgr.reelCacheMgr.refreshCache();
    }
  }

  @override
  void onClose() {
    WakeLockUtils.disable();

    if (Get.isRegistered<ReelSearchController>()) {
      Get.delete<ReelSearchController>();
    }

    ReelProfileMgr.instance.removeAllData();
    ReelPostMgr.instance.removeAllData();

    videoStreamSubscription.cancel();
    objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr);

    pageController.dispose();
    reelNavigationMgr.clearCache();

    super.onClose();
  }

  void initializeControllerData() {}

  void onBottomTap(
    int index, {
    int nextSelected = 0,
  }) {
    if (index == 1) {
      doUploadPage();
    } else {
      if (selectedBottomIndex.value != 0 && index == 0) {
        var a = shouldPop();
        if (a) Get.back();
      } else {
        if (index != 0) {
          onNavigation();

          Get.toNamed(
            RouteName.reelMyProfileView,
            preventDuplicates: false,
            arguments: {
              "showBack": false,
              "onBack": (toDismiss) {
                var a = shouldPop();
                if (a && toDismiss) Get.back();
              },
            },
          );
        } else {
          onTapHomePage();
        }
      }
      selectedBottomIndex.value = index;
      // tabController!.animateTo(
      //   index,
      //   duration: const Duration(milliseconds: 100),
      //   curve: Curves.easeInOut,
      // );
    }
  }

  void onPageChanged(int index) async {
    currentPage = index;

    isScrolling.value = false;
    videoStreamMgr.updateCurrentIndex(currentPage);
    TencentVideoController? controller = videoStreamMgr.getVideo(index);

    processCacheVideo(currentPage);

    triggerSwipeUp.value = currentPage == postList.length - 1;
    if (currentPage + cacheVideoCount >= postList.length - 1) {
      preloadPostList();
    }

    await videoStreamMgr.pausePlayingControllers(index);
    if (controller != null) {
      await controller.play();
    }
  }

  Future<void> preloadPostList({bool downloadData = true}) async {
    await refreshReel(downloadData: downloadData);
    precachePostAsset();
  }

  void precachePostAsset() {
    if (postList.isEmpty || currentPage > postList.length) return;

    if (!checkVideoCacheExist(currentPage)) {
      final ReelPost reel = postList[currentPage];
      final String source = reel.file.value!.path.value!;
      final int width = reel.file.value!.width.value!;
      final int height = reel.file.value!.height.value!;

      preparePlayer(currentPage, source, reel.thumbnail.value!,
          reel.gausPath.value, width, height); //第一道视频需马上显示
    }

    if (currentPage + cacheSegmentCount < postList.length &&
        !checkVideoCacheExist(currentPage + cacheSegmentCount)) {
      final ReelPost reel = postList[currentPage + 1];
      final String source = reel.file.value!.path.value!;
      final int width = reel.file.value!.width.value!;
      final int height = reel.file.value!.height.value!;
      if (isEnteringScreen.value) {
        // 若还在跳转中，则等待结束进行接下来的操作（二级数据操作）
        _enteringScreenFunctions.add(() {
          preparePlayer(currentPage + 1, source, reel.thumbnail.value!,
              reel.gausPath.value, width, height);
        });
      } else {
        preparePlayer(currentPage + 1, source, reel.thumbnail.value!,
            reel.gausPath.value, width, height);
      }
    }
  }

  onTapHomePage() {
    pageController.animateToPage(
      currentPage + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutExpo,
    );
  }

  Future<void> onRefresh() async {
    pageController.jumpTo(0);
    postList.clear();
    await refreshReel();
    precachePostAsset();
  }

  Future<void> refreshReel({bool downloadData = true}) async {
    try {
      final List<ReelPost> posts = await objectMgr.reelCacheMgr
          .downloadReelsWithPreCache(downloadData: downloadData);
      postList.addAll(posts);
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
  }

  void preparePlayer(
    int page,
    String source,
    String cover,
    String? gausPath,
    int width,
    int height,
  ) async {
    TencentVideoConfig config = TencentVideoConfig(
      url: source,
      width: width,
      height: height,
      thumbnail: cover,
      thumbnailGausPath: gausPath,
      hasBottomSafeArea: false,
      hasTopSafeArea: false,
      autoplay: page == currentPage,
      isLoop: true,
    );

    if (page == currentPage) {
      videoStreamMgr.currentIndex.value = currentPage;
    }
    videoStreamMgr.addController(config, index: page);
  }

  void processCacheVideo(int index) {
    if (index < 0 || index >= postList.length) return;

    for (int i = 0; i < postList.length; i++) {
      ReelPost reel = postList[i];

      final String source = reel.file.value!.path.value!;

      videoStreamMgr.removeControllersOutOfRange(index, cacheSegmentCount);

      if (i >= index - cacheSegmentCount && i <= index + cacheSegmentCount) {
        final int width = reel.file.value?.width.value ?? 0;
        final int height = reel.file.value?.height.value ?? 0;
        preparePlayer(
          i,
          source,
          reel.thumbnail.value!,
          reel.gausPath.value,
          width,
          height,
        );
      }
    }
  }

  bool checkVideoCacheExist(int index) {
    if (index < 0 || index >= postList.length) return false;

    return videoStreamMgr.getVideoStream(index) != null;
  }

  void onVideoTap() async {
    if (currentVideoStream.value == null) return;

    isPlaying = !isPlaying;

    currentVideoStream.value?.controller.togglePlayState();
  }

  void onVideoLongPress() {
    if (currentVideoStream.value == null) return;
    currentVideoStream.value?.controller.setRate(2.0);
  }

  void onVideoLongPressEnd(_) {
    if (currentVideoStream.value == null) return;
    currentVideoStream.value?.controller.setRate(1.0);
  }

  void onClickTitleTab(int i) {
    switch (i) {
      case FOLLOW_TAB:
        Toast.showToast(localized(homeToBeContinue));

        break;
      case RECOMMEND_TAB:
        currentTab.value = RECOMMEND_TAB;
        break;
    }
  }

  doForward(ReelPost reel) async {
    if (reel.file.value?.width.value == 0 ||
        reel.file.value?.height.value == 0) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(reelShareFail),
        backgroundColor: colorWhite,
        textColor: colorTextPrimary,
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    final (Message m, bool observeForward) = _postToMessage(reel);
    showChatListSheet(m, reel, observeForward);
  }

  (Message, bool) _postToMessage(ReelPost post) {
    final Message msg = Message();
    msg.typ = messageTypeVideo;
    MessageVideo messageVideo = MessageVideo();
    messageVideo.url = post.file.value?.path.value ?? "";
    messageVideo.cover = post.thumbnail.value ?? "";
    messageVideo.second = post.duration.value ??
        (currentVideoStream.value!.controller.videoDuration.value ~/ 1000);
    messageVideo.height = post.file.value?.height.value ?? 0;
    messageVideo.width = post.file.value?.width.value ?? 0;
    messageVideo.forward_user_id = objectMgr.userMgr.mainUser.uid;
    messageVideo.forward_user_name = objectMgr.userMgr.mainUser.nickname;
    messageVideo.gausPath = post.gausPath.value ?? "";
    msg.content = jsonEncode(messageVideo);
    msg.decodeContent(
      cl: msg.getMessageModel(msg.typ),
      v: jsonEncode(messageVideo),
    );

    return (msg, messageVideo.gausPath.isEmpty);
  }

  void showChatListSheet(Message m, ReelPost reel, bool observeForward) {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colorOverlay40,
      builder: (BuildContext context) {
        return ForwardContainer(
          showSaveButton: false,
          forwardMsg: [m],
          onForwardProgressUpdate: observeForward
              ? (status) {
                  switch (status) {
                    case ForwardProgressStatus.start:
                      Get.back();
                      onShowLoadingDialog(navigatorKey.currentContext!);
                      break;
                    case ForwardProgressStatus.ended:
                      onCloseLoadingDialog(navigatorKey.currentContext!);
                      isSending.value = false;
                      ReelShareMgr.instance.updatePostSharing(reel);
                      break;
                    default:
                      break;
                  }
                }
              : null,
        );
      },
    ).whenComplete(() {
      if (!observeForward) {
        ReelShareMgr.instance.updatePostSharing(reel);
      }
    });
  }

  RxBool isSending = false.obs;

  void onShowLoadingDialog(BuildContext context) {
    isSending.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
          () => MomentPublishDialog(
            isSending: isSending.value,
            isDone: !isSending.value,
            sendingLocalizationKey: reelForwardSending,
          ),
        );
      },
    );
  }

  void onCloseLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  doUploadPage() {
    if (Get.isRegistered<UploadReelController>()) {
      final uploadReelController = Get.find<UploadReelController>();
      if (uploadReelController.isVideoProcessing) {
        Toast.showToast("请等待上一次视频上传完后在试");
        return;
      }
    }

    onNavigation();

    Get.toNamed(RouteName.uploadReel);
  }

  void onNavigation() {
    videoStreamMgr.enteringBusinessPausePhase = true;
    if (isCurrentlyPlaying) {
      toPlay = true;
      pause();
    }
  }

  void onReturnNavigation() {
    videoStreamMgr.enteringBusinessPausePhase = false;
    if (toPlay) play();
    toPlay = false;
    _updateData();
  }

  void onReturnReelPreview() {
    pause();
    _updateData();
  }

  void onSearchTap() {
    onNavigation();
    Get.toNamed(RouteName.reelSearch)?.then((value) => onReturnNavigation());
  }

  void pause() {
    if (currentVideoStream.value == null) return;
    currentVideoStream.value?.controller.pause();
  }

  void play() {
    resumePlaying();
  }

  updateProfile(int userId, String profilePic, String name) {
    postList
        .where((p0) => (p0.userid.value ?? 0) == userId)
        .toList()
        .forEach((element) {
      element.creator.value?.profilePic.value = profilePic;
    });
  }

  prepareListeners() {
    videoStreamSubscription =
        videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);
  }

  bool _isGettingPosts = false;
  int onStartPage = 0;

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      isScrolling.value = true;
      actualScrolling.value = true; //滑动进度条需要用到这个
      onStartPage = currentPage;
    } else if (notification is ScrollEndNotification) {
      isScrolling.value = false;
      actualScrolling.value = false; //滑动进度条需要用到这个
    }

    if (triggerSwipeUp.value) {
      if (!_isGettingPosts &&
          pageController.offset >= notification.metrics.maxScrollExtent) {
        _isGettingPosts = true;
        _notificationOnScroll();
      }
    }
    return true;
  }

  _notificationOnScroll() async {
    var a = postList.length;
    await preloadPostList();
    if (a < postList.length) {
      pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    _isGettingPosts = false;
  }

  void resumePlaying() {
    if (currentVideoStream.value == null) return;
    currentVideoStream.value?.controller.play();
  }

  _updateData() async {
    ReelPost data = postList[currentPage];
    try {
      final ReelPost reelData = await getReelDetail(data.id.value!);
      postList[currentPage] = reelData;
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  (
    double actualWidth,
    double actualHeight,
    double horizontalAdjustments,
    double verticalAdjustments
  ) getVideoWidthAndHeight(
    int videoWidth,
    int videoHeight,
    double bottomControllerHeight,
  ) {
    Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;

    double screenWidth = screenSize.width;
    double expectedHeight = screenSize.height - bottomControllerHeight;
    double finalHeight = expectedHeight.ceilToDouble();
    double leftRight = 0;
    double topBottom = 0;
    double finalWidth = screenWidth.ceilToDouble();
    if (videoWidth == 0 && videoHeight == 0) {
      return (finalWidth, finalHeight, leftRight, topBottom);
    }

    if (videoWidth < videoHeight) {
      double a = 9 / 16;
      double ar = videoWidth / videoHeight;

      if (ar >= a) {
        double ratio = expectedHeight / videoHeight;
        finalWidth = (ratio * videoWidth).ceilToDouble();
        if (finalWidth >= screenWidth) {
          leftRight = (finalWidth - screenWidth) / 2;
        }
      } else {
        double difference = a - ar;

        if (difference < 0.02) {
          double ratio = expectedHeight / videoHeight;
          finalWidth = (ratio * videoWidth).ceilToDouble();
          if (finalWidth >= screenWidth) {
            leftRight = (finalWidth - screenWidth) / 2;
          }
        } else {
          double ratio = screenWidth / videoWidth;
          finalHeight = (ratio * videoHeight).ceilToDouble();
          if (finalHeight >= expectedHeight) {
            topBottom = (finalHeight - expectedHeight) / 2;
          }
        }
      }
    } else {
      double ratio = screenWidth / videoWidth;
      finalHeight = (ratio * videoHeight).ceilToDouble();
    }

    return (finalWidth, finalHeight, leftRight, topBottom);
  }

  bool shouldPop() {
    if (selectedBottomIndex.value == 0) {
      return true;
    } else if (selectedBottomIndex.value == 2) {
      selectedBottomIndex.value = 0;
      onReturnNavigation();
    }
    return true;
  }

  synchronizeDeletedIds(List<int> ids) {
    onRefresh();
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != currentPage) return;
    if (currentVideoStream.value != item) {
      currentVideoStream.value = item;
    }
    if (currentVideoState.value != item.state.value) {
      currentVideoState.value = item.state.value;
    }
  }
}
