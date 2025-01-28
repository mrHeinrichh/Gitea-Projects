import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/api/mini_api.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class PullDownSearchController extends GetxController {
  final MAX_SEARCH_RECORD = 5;
  final searchApps = <Apps>[].obs;
  final searchRecord = <String>[].obs;
  final exploreApps = <Apps>[].obs;
  final searchInputController = TextEditingController();
  final focusNode = FocusNode();
  final searchDebounce = Debounce(const Duration(milliseconds: 600));
  final toggleDebounce = Debounce(const Duration(milliseconds: 200));
  final isTyping = false.obs;
  final isSearching = false.obs;

  bool isPhysicalBack = true;

  // final isMoreSearchRecordVisible = false.obs;
  bool isRefreshParent = false;

  String get tableName => LocalStorageMgr.RECENT_MINI_APP_SEARCH_KEYWORDS;

  @override
  void onInit() {
    super.onInit();
    getSearchRecord();
    getExploreApps();
    searchInputController.addListener(inputListener);
  }

  @override
  void onClose() {
    super.onClose();
    /// 这里的onClose有3种情况：1.点击了小程序；2.点击了搜索的取消；3.安卓的物理按键，这里需要针对安卓物理按键的返回做处理
    if (isPhysicalBack && isRefreshParent) {
      PullDownAppletController miniAppController = Get.find<PullDownAppletController>();
      miniAppController.getMyApps();
    }
    searchInputController.removeListener(inputListener);
    searchInputController.dispose();
    focusNode.dispose();
  }

  void inputListener() {
    isTyping.value = searchInputController.text.isNotEmpty;
  }

  void getSearchRecord() {
    final list =
    objectMgr.localStorageMgr.getLocalTable(tableName)?.cast<String>();
    searchRecord.value = list ?? <String>[];
  }

  void getExploreApps() async {
    final dbMiniApps =
    await objectMgr.miniAppMgr.getMiniAppsFromDB(MiniAppType.explore);
    if (dbMiniApps.isNotEmpty) {
      exploreApps.value = dbMiniApps;
    }
    exploreApps.value = await getSearchRecommend();
    if (exploreApps.isNotEmpty) {
      objectMgr.miniAppMgr.saveMiniAppsToDB(exploreApps, MiniAppType.explore);
    }
  }

  void onSearch() {
    if (searchInputController.text.isEmpty) return;
    isSearching.value = true;
    searchApps.clear();
    searchDebounce.call(() {
      objectMgr.miniAppMgr.findMini(searchInputController.text).then((apps) {
        isSearching.value = false;
        searchApps.value = apps;
        insertOneSearchRecord(searchInputController.text);
      });
    });
  }

  Future<List<Apps>> getSearchRecommend([String? name = '']) async {
    List<Apps> list = await recommendMiniAppList();
    return list;
  }

  void onShortcutSearch(String keyword) {
    searchInputController.text = keyword;
    isSearching.value = true;
    searchApps.clear();
    searchDebounce.call(() {
      objectMgr.miniAppMgr.findMini(keyword).then((apps) {
        isSearching.value = false;
        searchApps.value = apps;
      });
    });
  }

  // void showMoreSearchRecord() {
  //   isMoreSearchRecordVisible.value = true;
  // }

  void clearInputText() {
    searchInputController.clear();
  }

  void onCancelClick() {
    getBack(isRefreshParent);
    clearInputText();
  }

  void onClearClick() {
    clearInputText();
  }

  void insertOneSearchRecord(String keyword) {
    if (keyword.isEmpty) return;
    final reg = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9]+$');
    List? list = objectMgr.localStorageMgr.getLocalTable(tableName);
    list = list ?? [];
    if (!list.contains(keyword)) {
      if (reg.hasMatch(keyword)) {
        list.insert(0, keyword);
      }
    }
    if (list.length > MAX_SEARCH_RECORD) {
      list.removeLast();
    }
    objectMgr.localStorageMgr.putLocalTable(
      tableName,
      jsonEncode(list),
    );
    getSearchRecord();
  }

  void deleteOneSearchRecord(String keyword) {
    final list = objectMgr.localStorageMgr.getLocalTable(tableName);
    list?.remove(keyword);
    objectMgr.localStorageMgr.putLocalTable(
      tableName,
      jsonEncode(list),
    );
    getSearchRecord();
  }

  void deleteAllSearchRecord() {
    objectMgr.localStorageMgr.putLocalTable(
      tableName,
      jsonEncode([]),
    );
    getSearchRecord();
  }

  void toggleFavorite(Apps app, RxList<Apps> originList) {
    bool isCollect = app.favoriteAt != 0;

    toggleDebounce.call(() async {
      for (int i = 0; i < originList.length; i++) {
        final el = originList[i];
        if (el.id == app.id) {
          originList[i] = el.copyWith(favoriteAt: !isCollect ? 1 : 0);
          break;
        }
      }
      originList.refresh();
      if (!isCollect) {
        await objectMgr.miniAppMgr.addFavorite(app);
      } else {
        await objectMgr.miniAppMgr.removeFavorite(app);
      }
      isRefreshParent = true;
      imBottomToast(
        Get.context!,
        icon: ImBottomNotifType.success,
        title: !isCollect ? localized(addToFav) : localized(ReelUnsaved),
      );
    });
    focusNode.unfocus();
  }

  void joinMiniApp(Apps app, BuildContext context) {
    objectMgr.miniAppMgr.joinMiniApp(app, context);
    focusNode.unfocus();
    getBack(false);
  }

  void getBack(bool refresh) {
    isPhysicalBack = false;
    Get.back(result: {'refresh': refresh});
  }
}
