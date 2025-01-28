import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/reel/services/playback_state.dart';
import 'package:jxim_client/reel/reel_search/reel_preview.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/src/visibility_detector.dart';

import '../../api/reel.dart';
import '../../main.dart';
import '../../managers/local_storage_mgr.dart';
import '../../object/reel.dart';

class ReelSearchController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  RxString searchKeyword = "".obs;
  RxBool isSearching = true.obs;

  RxList<String> historyList = <String>[].obs;
  RxList<String> suggestSearchList = <String>[].obs;

  bool isLoading = false;
  RxList<String> tagList = <String>[].obs;
  RxList<ReelData> resultList = <ReelData>[].obs;

  final AutoScrollController resultController = AutoScrollController();

  // 列表GlobalKey
  // key: post -> id
  // value: GlobalKey
  final Map<int, GlobalKey> resultKey = <int, GlobalKey>{};

  @override
  void onInit() {
    super.onInit();
    getSearchHistory();
    getSuggestSearch();
    getSuggestTag();

    resultController.addListener(resultScrollListener);
  }

  @override
  void onClose() {
    resultController.removeListener(resultScrollListener);

    super.onClose();
  }

  void resultScrollListener() {
    if (resultController.position.pixels + 800 >=
            resultController.position.maxScrollExtent &&
        !isLoading) {
      getSearchPost(searchKeyword.value);
    }
  }

  void checkVisibility(
    VisibilityInfo info,
    Post post,
    int index,
  ) {
    videoHandle(false, post.files![0].path);
    // if (info.visibleFraction < 1) {
    //   return;
    // }
    //
    // videoHandle(true, post.files![0].path);
    // return;
  }

  void videoHandle(
    bool isPlay,
    String? path, {
    bool isMute = true,
    bool pauseAll = false,
  }) {
    final ReelController? controller = Get.find<ReelController>();
    if (controller == null) return;

    if (pauseAll) {
      controller.event(
        controller,
        ReelController.eventPlayStateChange,
        data: <String, dynamic>{'state': PlaybackState.stop},
      );
      return;
    }

    final data = <String, dynamic>{
      'source': path,
      'mute': isMute,
    };

    if (isPlay) {
      data['state'] = PlaybackState.play;
    } else {
      data['state'] = PlaybackState.pause;
    }
    controller.event(
      controller,
      ReelController.eventPlayStateChange,
      data: data,
    );
  }

  void toggleVolume(ReelData reelPost) {
    final ReelController? controller = Get.find<ReelController>();
    if (controller == null) return;

    final data = <String, dynamic>{
      'source': reelPost.post!.files![0].path,
    };

    controller.event(
      controller,
      ReelController.eventVolumeStateChange,
      data: data,
    );
  }

  void onEnterReelDetail(
      BuildContext context, ReelData reelPost, int currentSecond) {
    videoHandle(false, null, pauseAll: true);
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) {
            return ReelPreview(
              source: reelPost.post!.files!.first.path!,
              thumbnail: reelPost.post!.thumbnail!,
              currentSecond: currentSecond,
            );
          },
          settings: const RouteSettings(
            name: RouteName.reelPreview,
          )),
    );
  }

  void getSearchHistory() {
    final list =
        objectMgr.localStorageMgr.read(LocalStorageMgr.REEL_SEARCH_HISTORY);
    if (list != null) {
      historyList.addAll(list.cast<String>());
    }
  }

  Future<void> getSuggestSearch() async {
    final list = await suggestedSearches();
    suggestSearchList.value = list;
  }

  Future<void> getSuggestTag() async {
    TagData res = await suggestedTag();
    if (res.tags != null && res.tags!.isNotEmpty) {
      tagList.addAll(res.tags!);
    }
    tagList.insert(0, localized(all));
  }

  void onBackClick() {
    if (isSearching.value) {
      Get.back();
    } else {
      searchController.clear();
      resultList.clear();
      tagList.clear();
      isSearching.value = true;
    }
  }

  void onSearch(String value, {isSave = true}) {
    searchController.text = value;
    searchKeyword.value = (notBlank(value)) ? value : localized(all);
    if (notBlank(value)) {
      if (!historyList.contains(value) && isSave) {
        historyList.insert(0, value);
      }

      if (historyList.length > 5) {
        historyList.removeLast();
      }
    }
    if (isSave) {
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.REEL_SEARCH_HISTORY, historyList);
    }

    isSearching.value = false;

    getSearchPost(value);
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
  }

  Future<void> getSearchPost(String value) async {
    isLoading = true;
    final list = await searchPost(
      value,
      offset: resultList.length,
    );

    isLoading = false;
    resultList.addAll(list);
  }

  GlobalKey getResultItemKey(int postId) {
    resultKey[postId] = GlobalKey();
    return resultKey[postId]!;
  }
}
