import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/services/playback_state.dart';
import 'package:jxim_client/reel/services/preload_page_view.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/reel/services/video_player_mgr.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReelController extends GetxController
    with EventDispatcher, GetTickerProviderStateMixin {
  static const String eventPageChange = 'eventPageChange';
  static const String eventCacheVideoListUpdate = 'eventCacheVideoListUpdate';
  static const String eventPlayerInit = 'eventPlayerInit';

  static const String eventPlayStateChange = 'eventPlayStateChange';
  static const String eventVolumeStateChange = 'eventVolumeStateChange';

  // 视频分片缓存数量
  static const int cacheSegmentCount = 2;

  static const int FOLLOW_TAB = 1;
  static const int RECOMMEND_TAB = 2;

  final RxInt currentTab = 2.obs;

  // PageView 控制器
  int currentPage = 0;
  final PreloadPageController pageController = PreloadPageController();

  // 推荐列表
  RxList<ReelData> postList = <ReelData>[].obs;

  RxMap<String, Map<String, dynamic>> cacheVideoList =
      <String, Map<String, dynamic>>{}.obs;

  // 列表加载
  RxBool isLoading = true.obs;

  // 当前播放器的播放状态
  bool isPlaying = false;

  String get source => postList[currentPage].post!.files![0].path!;

  Video? get currentVideo => cacheVideoList[source]?['video'];

  TabController? tabController;
  RxInt selectedBottomIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    preloadPostList();

    tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void onClose() {
    clearAllVideoCache();
    WakelockPlus.disable();

    super.onClose();
  }

  void onBottomTap(int index) {
    if (index == 1) {
      doUploadPage();
    } else {
      selectedBottomIndex.value = index;
      tabController!.animateTo(index,
          duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
    }
  }

  void onPageChanged(int index) {
    currentPage = index;
    event(this, eventPageChange, data: index);

    processCacheVideo(index);

    if (index + 2 >= postList.length) {
      preloadPostList();
      return;
    }
  }

  Future<void> preloadPostList() async {
    await refreshReel();
    precachePostAsset();
    isLoading.value = false;
  }

  // 预加载视频资源
  void precachePostAsset() {
    if (postList.isEmpty || currentPage > postList.length) return;

    // 检查当前视频
    if (!checkVideoCacheExist(currentPage)) {
      final ReelData reel = postList[currentPage];
      final String source = reel.post!.files![0].path!;
      initPlayer(source);
      preloadThumbnail(reel.post!.thumbnail!);
    }

    // 检查下2个视频
    if (currentPage + 1 < postList.length &&
        !checkVideoCacheExist(currentPage + 1)) {
      final ReelData reel = postList[currentPage + 1];
      final String source = reel.post!.files![0].path!;
      initPlayer(source);
      preloadThumbnail(reel.post!.thumbnail!);
    }

    if (currentPage + 2 < postList.length &&
        !checkVideoCacheExist(currentPage + 2)) {
      final ReelData reel = postList[currentPage + 2];
      final String source = reel.post!.files![0].path!;
      initPlayer(source);
      preloadThumbnail(reel.post!.thumbnail!);
    }
  }

  Future<void> onRefresh() async {
    postList.clear();
    await refreshReel();
    precachePostAsset();
  }

  Future<void> refreshReel() async {
    try {
      final List<ReelData> posts = await getSuggestedPosts();
      postList.addAll(posts);
    } catch (e) {
      e.printError();
    }
  }

  /// ================================ 工具函数 =================================

  void preloadThumbnail(String source) async {
    try {
      await cacheMediaMgr.downloadMedia(
        source,
        mini: Config().dynamicMin,
      );
    } catch (e) {
      pdebug('Download thumbnail failed: $e');
    }
  }

  void initPlayer(String source) async {
    final String url = source;

    Video? vDetail;

    if (url.contains('.m3u8')) {
      final localPath = await cacheMediaMgr.downloadMedia(url);
      if (localPath != null) {
        final tsDirLastIdx = url.lastIndexOf('/');
        final tsDir = url.substring(0, tsDirLastIdx);
        Map<double, Map<String, dynamic>> tsMap =
            await cacheMediaMgr.extractTsUrls(tsDir, localPath);

        List values = tsMap.values.toList();

        List<Future> tsFutures = [];

        for (int i = 0; i < values.length; i++) {
          if (i >= 2) {
            break;
          }

          tsFutures.add(cacheMediaMgr.downloadMedia(
            values[i]['url'],
            timeoutSeconds: 30,
          ));
        }

        if (tsFutures.isNotEmpty) {
          await Future.wait(tsFutures);
        }

        vDetail = Video(
          File(localPath),
          mixWithOthers: false,
          autoInitialize: true,
        );

        if (cacheVideoList.containsKey(url)) {
          cacheVideoList[url]!['video'] = vDetail;
        } else {
          cacheVideoList[url] = {'video': vDetail};
        }

        cacheVideoList[url]!['tsMap'] = tsMap;
      }

      event(this, eventCacheVideoListUpdate);
      return;
    }

    vDetail = Video(
      url,
      mixWithOthers: false,
    );

    if (cacheVideoList.containsKey(url)) {
      cacheVideoList[url]!['video'] = vDetail;
    } else {
      cacheVideoList[url] = {'video': vDetail};
    }

    event(this, eventCacheVideoListUpdate);
  }

  // 清理视频缓存
  // I: 使用前确保 cacheVideoList里拥有该资源
  void clearVideoCache(String source) async {
    final Video? vDetail = cacheVideoList[source]!['video'];

    if (vDetail == null) return;

    if ((vDetail.vlcPlayerController != null &&
            vDetail.vlcPlayerController!.value.isInitialized) ||
        (vDetail.videoCtr != null && vDetail.videoCtr!.value.isInitialized)) {
      vDetail.off(Video.EVENT_UPDATEPOS);
      vDetail.off(Video.EVENT_PLAYSTATE_CHANGE);
      vDetail.dispose();
    }
    await cacheVideoList.remove(source);
  }

  void clearAllVideoCache() async {
    List<String> keyList = cacheVideoList.keys.toList();
    keyList.forEach(clearVideoCache);
  }

  // 处理视频缓存
  void processCacheVideo(int index) {
    if (index < 0 || index >= postList.length) return;

    for (int i = 0; i < postList.length; i++) {
      ReelData reel = postList[i];
      final String source = reel.post!.files![0].path!;

      if (cacheVideoList.containsKey(source) &&
          (i < index - cacheSegmentCount || i > index + cacheSegmentCount)) {
        clearVideoCache(source);
      }

      if (!cacheVideoList.containsKey(source) &&
          i >= index - cacheSegmentCount &&
          i <= index + cacheSegmentCount) {
        initPlayer(source);
        preloadThumbnail(reel.post!.thumbnail!);
      }
    }
  }

  // 检查视频缓存是否存在
  bool checkVideoCacheExist(int index) {
    if (index < 0 || index >= postList.length) return false;

    final String source = postList[index].post!.files![0].path!;
    return cacheVideoList.containsKey(source);
  }

  /// ================================ 视频交互 =================================

  void onVideoTap() async {
    if (currentVideo == null) return;

    if ((currentVideo!.vlcPlayerController != null &&
            !currentVideo!.vlcPlayerController!.value.isInitialized) ||
        (currentVideo!.videoCtr != null &&
            !currentVideo!.videoCtr!.value.isInitialized)) {
      event(
        this,
        eventPlayStateChange,
        data: <String, dynamic>{
          'source': source,
          'state': isPlaying ? PlaybackState.pause : PlaybackState.play,
        },
      );
      isPlaying = !isPlaying;
      return;
    }

    if ((currentVideo!.vlcPlayerController?.value.isPlaying ?? false) ||
        (currentVideo!.videoCtr?.value.isPlaying ?? false)) {
      event(
        this,
        eventPlayStateChange,
        data: <String, dynamic>{
          'source': source,
          'state': PlaybackState.pause,
        },
      );
      isPlaying = false;
    } else {
      event(
        this,
        eventPlayStateChange,
        data: <String, dynamic>{
          'source': source,
          'state': PlaybackState.play,
        },
      );
      isPlaying = true;
    }
  }

  void onVideoLongPress() {
    if (currentVideo == null ||
        (currentVideo!.vlcPlayerController != null &&
            !currentVideo!.vlcPlayerController!.value.isInitialized) ||
        (currentVideo!.videoCtr != null &&
            !currentVideo!.videoCtr!.value.isInitialized)) return;

    if (currentVideo!.vlcPlayerController!.value.isPlaying ||
        currentVideo!.videoCtr!.value.isPlaying) {
      currentVideo!.setPlaybackSpeed(2.0);
    }
  }

  void onVideoLongPressEnd(_) {
    final ReelData reel = postList[currentPage];
    final String source = reel.post!.files![0].path!;
    final Video? vDetail = cacheVideoList[source]!['video'];

    if (vDetail == null ||
        (vDetail.vlcPlayerController != null &&
            !vDetail.vlcPlayerController!.value.isInitialized) ||
        (vDetail.videoCtr != null && !vDetail.videoCtr!.value.isInitialized))
      return;

    vDetail.setPlaybackSpeed(1.0);
  }

  void onClickTitleTab(int i) {
    switch (i) {
      case FOLLOW_TAB:
        currentTab.value = FOLLOW_TAB;

        break;
      case RECOMMEND_TAB:
        currentTab.value = RECOMMEND_TAB;
        break;
    }
  }

  doForward(ReelData reel) async {
    try {
      final ReelData reelData = await getReelDetail(reel.post!.id!);
      showChatListSheet(reelData);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  void showChatListSheet(ReelData reel) {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ForwardContainer(reel: reel);
      },
    );
  }

  doUploadPage() {
    if (Get.isRegistered<UploadReelController>()) {
      final uploadReelController = Get.find<UploadReelController>();
      if (uploadReelController.isVideoProcessing) {
        Toast.showToast("请等待上一次视频上传完后在试");
        return;
      }
    }

    currentVideo?.pause();
    Get.toNamed(RouteName.uploadReel);
  }

  void onSearchTap() {
    currentVideo?.pause();
    Get.toNamed(RouteName.reelSearch);
  }

  Future<void> onLikedClick(int? postId, bool like) async {
    int isLike = like ? 1 : 0;
    bool res = await likePost(postId!, isLike);

    if (res) {
      if (like) {
        Toast.showToast("Like successfully");
      } else {
        Toast.showToast("unlike successfully");
      }
    }
  }

  Future<void> onSavedClick(int? postId, bool save) async {
    int isSave = save ? 1 : 0;
    bool res = await savePost(postId!, isSave);

    if (res) {
      if (save) {
        Toast.showToast("Save successfully");
      } else {
        Toast.showToast("unsave successfully");
      }
    }
  }
}
