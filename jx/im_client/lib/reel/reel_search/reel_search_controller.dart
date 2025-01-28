import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/components/search_tile.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/reel/reel_search/reel_media_view.dart';
import 'package:jxim_client/reel/reel_search/result_item.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelSearchController extends GetxController {
  final searchScrollerKey = "searchScroller";
  final tagScrollerKey = "tagScroller";
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  RxString searchKeyword = "".obs;
  RxBool isSearching = true.obs;

  RxList<String> historyList = <String>[].obs;
  RxList<String> suggestSearchList = <String>[].obs;

  RxBool isLoading = false.obs;
  RxList<String> tagList = <String>[].obs;
  RxList<String> completerList = <String>[].obs;
  RxList<ReelPost> resultList = <ReelPost>[].obs;
  final Map<int, ResultItem> _resultItems = {};
  RxBool scrollStarted = false.obs;
  RxBool showAllHistory = false.obs;

  final AutoScrollController resultController = AutoScrollController();
  final endScrollDebouncer = Debounce(const Duration(milliseconds: 250));
  final viewUpdateDebouncer = Debounce(const Duration(milliseconds: 500));
  final RxBool isMute = true.obs;

  late TencentVideoStreamMgr videoStreamMgr;
  late StreamSubscription videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  Rect? resultTagRect;

  StreamController<ScrollNotification> streamController =
      StreamController<ScrollNotification>();

  @override
  void onInit() {
    super.onInit();

    videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
    videoStreamSubscription =
        videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);

    getSearchHistory();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      asyncInit();
    });

    resultController.addListener(resultScrollListener);
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);
  }

  asyncInit() async {
    getSuggestSearch();
    getSuggestTag();
  }

  @override
  void onClose() {
    resultController.removeListener(resultScrollListener);
    completerList.clear();
    resultList.clear();
    streamController.close();
    focusNode.dispose();

    videoStreamSubscription.cancel();
    objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr);

    super.onClose();
  }

  bool willPop() {
    onBackClick();
    return false;
  }

  bool _endOfScroll = false;

  void resultScrollListener() {
    if (_endOfScroll) return;
    if (resultController.position.pixels + 800 >=
            resultController.position.maxScrollExtent &&
        !isLoading.value) {
      getSearchPost(searchKeyword.value, offset: resultList.length);
    }
  }

  Rxn<int> currentIndex = Rxn<int>();

  void isInView(int index) {}

  void isNotInView(int index) {
    if (index == currentIndex.value) {
      _pauseNearestController();
    }
  }

  void onEnterReelDetail(
    BuildContext context,
    ReelPost reelPost,
    int currentSecond,
    int index,
  ) {
    endScrollDebouncer.dispose();
    viewUpdateDebouncer.dispose();
    if (currentVideoStream.value != null) {
      currentVideoStream.value!.controller.previousState =
          currentVideoStream.value!.state.value;
    }
    videoStreamMgr.enteringBusinessPausePhase = true;
    focusNode.unfocus();
    Navigator.of(context).push(
      TransparentRoute(
        builder: (BuildContext context) {
          return ReelMediaView(
            assetList: resultList,
            startingIndex: index,
            searchController: this,
            startingStream: currentVideoStream.value,
            onPageChange: _onPageChanged,
            onReturn: (videoStream) {
              videoStreamMgr.enteringBusinessPausePhase = false;
              if (videoStream.state.value == TencentVideoState.PLAYING) {
                play();
              } else {
                pause();
              }
            },
          );
        },
        settings: const RouteSettings(
          name: RouteName.reelPreview,
        ),
      ),
    );
  }

  Future<List<ReelPost>> _onPageChanged(int index) async {
    List<ReelPost> newData = [];
    if (index + 5 < resultList.length) {
      return newData;
    }

    List<ReelPost> items =
        await getSearchPost(searchKeyword.value, offset: resultList.length);
    return items;
  }

  void getSearchHistory() {
    final list =
        objectMgr.localStorageMgr.read(LocalStorageMgr.REEL_SEARCH_HISTORY);
    if (list != null) {
      historyList.addAll(list.cast<String>());
    }
  }

  Future<void> getSuggestSearch() async {
    try {
      final list = await suggestedSearches();
      suggestSearchList.value = list;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
  }

  Future<void> getSearchCompletion(String text) async {
    if (text.isEmpty) {
      completerList.clear();
      return;
    }
    try {
      final list = await searchCompletion(text);
      completerList.value = list;
    } on AppException {
      completerList.clear();
    }
  }

  Future<void> getSuggestTag() async {
    TagData res = await suggestedTag();
    if (res.tags != null && res.tags!.isNotEmpty) {
      tagList.addAll(res.tags!);
    }
    tagList.insert(0, localized(all));
  }

  onTagResultBackClick({
    ReelTagBackFromEnum? tagBackFrom = ReelTagBackFromEnum.reelItem,
  }) {
    Get.back();
    final ReelController controller = Get.find<ReelController>();
    tagBackFrom == ReelTagBackFromEnum.reelPreview
        ? controller.onReturnReelPreview()
        : controller.onReturnNavigation();
    completerList.clear();
    scrollStarted.value = false;
    _pauseAndRemoveNearestController();
    currentIndex.value = null;
    isMute.value = true;
    searchController.clear();
    resultList.clear();
    _resultItems.clear();
    isSearching.value = true;
    update();
  }

  void onBackClick() {
    if (isSearching.value) {
      Get.back();
      final ReelController controller = Get.find<ReelController>();
      controller.onReturnNavigation();
    } else {
      _pauseAndRemoveNearestController();
      completerList.clear();
      scrollStarted.value = false;
      currentIndex.value = 0;
      isMute.value = true;
      searchController.clear();
      resultList.clear();
      _resultItems.clear();
      isSearching.value = true;
      update();
    }
  }

  void onTapFullHistory() {
    if (!showAllHistory.value) {
      showAllHistory.value = !showAllHistory.value;
    } else {
      clearAllHistory();
    }
  }

  void onSearch(String value, {isSave = true, FocusNode? focusNode}) {
    if (!isSearching.value &&
        resultList.isNotEmpty &&
        value == searchController.text) return;
    _endOfScroll = false;
    searchController.text = value;
    searchKeyword.value = (notBlank(value)) ? value : "";
    if (notBlank(value)) {
      if (!historyList.contains(value) && isSave) {
        historyList.insert(0, value);
      } else if (historyList.contains(value) && isSave) {
        historyList.remove(value);
        historyList.insert(0, value);
      }
    }
    if (isSave) {
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.REEL_SEARCH_HISTORY, historyList);
    }

    isSearching.value = false;
    update();
    resultList.clear();
    _pauseAndRemoveNearestController();
    currentIndex.value = null;

    _resultItems.clear();
    scrollStarted.value = false;

    getSearchPost(value);
  }

  void clearAllHistory() {
    historyList.clear();
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.REEL_SEARCH_HISTORY, historyList);
  }

  void clearHistory(String item) {
    if (historyList.isNotEmpty) {
      if (historyList.contains(item)) {
        historyList.remove(item);
      }
    }
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.REEL_SEARCH_HISTORY, historyList);
  }

  void clearInput() {
    searchController.clear();
    isSearching.value = true;
    update();
  }

  void _preloadThumbnails(List<ReelPost> reels) async {
    for (var element in reels) {
      try {
        downloadMgrV2.download(
          element.thumbnail.value!,
          mini: Config().messageMin,
        );
        // downloadMgr.downloadFile(
        //   element.thumbnail.value!,
        //   mini: Config().messageMin,
        // );
      } catch (e) {
        pdebug('Download thumbnail failed: $e');
      }
    }
  }

  Future<List<ReelPost>> getSearchPost(String value, {int? offset}) async {
    isLoading.value = true;
    List<ReelPost> list = [];
    try {
      list = await ReelPostMgr.instance
          .getSearchPost(value, offset: resultList.length);
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _preloadThumbnails(list);
      });

      isLoading.value = false;
      resultList.addAll(list);
      if (offset == null && list.isNotEmpty) {
        currentIndex.value = 0;
        _initializeNearestController();
      }
      _endOfScroll = list.isEmpty || resultList.length % 10 != 0;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      isLoading.value = false;
    }

    return list;
  }

  void toggleMute() {
    if (currentVideoStream.value == null) return;

    isMute.value = !isMute.value;
    isMute.value
        ? currentVideoStream.value?.controller.mute()
        : currentVideoStream.value?.controller.unMute();
  }

  void togglePlay(int index) {
    if (currentVideoStream.value == null) return;

    currentVideoStream.value?.controller.togglePlayState();
  }

  void play() {
    currentVideoStream.value?.controller.play();
  }

  void pause() {
    currentVideoStream.value?.controller.pause();
  }

  _pauseAndRemoveNearestController() {
    videoStreamMgr.removeAllControllers();
    currentVideoStream.value = null;
  }

  _pauseNearestController() {
    videoStreamMgr.stopAllControllers();
    currentIndex.value = null;
  }

  _initializeNearestController() {
    if (currentVideoStream.value != null &&
        currentIndex.value == currentVideoStream.value?.pageIndex) {
      play();
      return;
    }
    if (resultList.isEmpty || (currentIndex.value ?? 0) >= resultList.length) {
      return;
    }

    _pauseAndRemoveNearestController();
    ReelPost data = resultList[currentIndex.value ?? 0];

    TencentVideoConfig config = TencentVideoConfig(
      url: data.file.value!.path.value!,
      width: data.file.value!.width.value!,
      height: data.file.value!.height.value!,
      thumbnail: data.thumbnail.value!,
      thumbnailGausPath: data.gausPath.value,
      hasBottomSafeArea: false,
      hasTopSafeArea: false,
      autoplay: true,
      isLoop: true,
      initialMute: isMute.value,
    );

    currentVideoStream.value =
        videoStreamMgr.addController(config, index: currentIndex.value!);
  }

  _startNearestController() {
    var s = VisibilityDetectorController.instance
        .widgetBoundsFor(ValueKey(searchScrollerKey));
    var r = resultTagRect;
    double videoHeight = 220;

    if (s != null) {
      double currentPosition = resultController.position.pixels;
      double heightOfScroll = s.bottom - s.top;

      Rect scrollViewRect = Rect.fromLTRB(
        s.left,
        currentPosition,
        s.right,
        heightOfScroll + currentPosition,
      );

      double offsetHeight = (r != null ? r.bottom - r.top : 0) + s.top;

      for (int i = 0; i < resultList.length; i++) {
        Rect? r = VisibilityDetectorController.instance
            .widgetBoundsFor(ValueKey(i.toString()));

        if (r != null) {
          double contentHeight = r.bottom - r.top - videoHeight;

          Rect adjustedRect = Rect.fromLTRB(
            r.left,
            r.top - offsetHeight + currentPosition + contentHeight,
            r.right,
            r.bottom - offsetHeight + currentPosition - contentHeight - 44,
          );

          if (_containsRect(scrollViewRect, adjustedRect)) {
            currentIndex.value = i;
            break;
          }
        }
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeNearestController();
    });
  }

  bool _containsRect(Rect outer, Rect inner) {
    if (inner.right <= outer.right &&
        inner.left >= outer.left &&
        inner.top >= outer.top &&
        inner.bottom <= outer.bottom) {
      return true;
    } else {
      return false;
    }
  }

  void onEndScroll() {
    pdebug("end scroll triggered - ${currentIndex.value}");

    endScrollDebouncer.call(() {
      VisibilityDetectorController.instance.notifyNow();
    });
    viewUpdateDebouncer.call(() {
      scrollStarted.value = false;
      _startNearestController();
    });
  }

  updateProfile(int userId, String profilePic, String name) {
    resultList
        .where((p0) => p0.creator.value?.id.value == userId)
        .toList()
        .forEach((element) {
      element.creator.value?.profilePic.value = profilePic;
      element.creator.value?.name.value = name;
    });
  }

  void onStartScroll() {
    scrollStarted.value = true;
  }

  void onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      onEndScroll();
    } else if (notification is ScrollEndNotification) {
      onEndScroll();
    } else if (notification is ScrollStartNotification) {
      onStartScroll();
    }
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (isLoading.value) return;
    if (currentVideoStream.value != item) {
      currentVideoStream.value = item;
    }
    if (currentVideoState.value != item.state.value) {
      currentVideoState.value = item.state.value;
    }
  }

  Widget getSearchContent({Function(String)? onTapTile, Color? background}) {
    return Container(
      color: background ?? Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            //歷史紀錄
            Visibility(
              visible: historyList.isNotEmpty && completerList.isEmpty,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: colorBackground6),
                  ),
                ),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ...List.generate(
                                showAllHistory.value
                                    ? historyList.length
                                    : (historyList.length > 4
                                        ? 4
                                        : historyList.length), (index) {
                              String title = historyList[index];
                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => onTapTile != null
                                    ? onTapTile(title)
                                    : onSearch(title),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: SearchTile(
                                    title: title,
                                    onClose: () => clearHistory(title),
                                    leftIcon: 'reel_resent_search_icon',
                                    rightIcon: 'reel_search_close_icon',
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: historyList.length > 4,
                        child: OpacityEffect(
                          child: GestureDetector(
                            onTap: () => onTapFullHistory(),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                showAllHistory.value
                                    ? localized(reelClearAllSearchRecord)
                                    : localized(reelAllSearchRecord),
                                style: jxTextStyle.textStyle17(
                                  color: colorTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //猜你想搜
            Visibility(
              visible: completerList.isEmpty,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: <Widget>[
                        Text(
                          localized(reelGuessSearch),
                          style: jxTextStyle.textStyleBold17(
                            fontWeight: MFontWeight.bold6.value,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => getSuggestSearch(),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: SvgPicture.asset(
                                  'assets/svgs/refresh_icon.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    colorTextSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              Text(
                                localized(reelSearchRecordRefresh),
                                style: jxTextStyle.textStyleBold17(
                                  color: colorTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      mainAxisExtent: 20,
                    ),
                    padding: const EdgeInsets.only(bottom: 25),
                    shrinkWrap: true,
                    itemCount: suggestSearchList.length,
                    itemBuilder: (context, index) {
                      final item = suggestSearchList[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onTapTile != null
                            ? onTapTile(item)
                            : onSearch(item),
                        child: Text(
                          item,
                          style: jxTextStyle.textStyle17(
                            color: index == 0 ? colorRed : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            //
            Visibility(
              visible: completerList.isNotEmpty,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    completerList.length,
                    (index) {
                      String title = completerList[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onTapTile != null
                            ? onTapTile(title)
                            : onSearch(title),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SearchTile(
                            title: title,
                            onClose: () {},
                            leftIcon: 'reel_search_icon',
                            rightIcon: 'reel_search_suggestion_icon',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
