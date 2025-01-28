import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/pull_down_search_applet.dart';
import 'package:jxim_client/home/chat/pages/pull_down_search_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class PullDownAppletController extends GetxController {
  final allRecentApps = <Apps>[].obs;
  final recentApps = <Apps>[].obs;
  // final myAllApps = <Apps>[].obs;
  final myApps = <Apps>[].obs;
  RxMap<int, double> itemOpacityList = <int, double>{}.obs;
  Rx<bool> isMoreApps = false.obs;
  Rx<bool> dragFromRecent = false.obs;
  Rx<MiniAppRecentBtnType> recentMorePageAddDelToggleHover = MiniAppRecentBtnType.idle.obs;
  Rx<String> currentDragInstanceId = ''.obs;
  Rx<int?> currentDragIndex = Rx<int?>(null);

  @override
  void onReady() {
    super.onReady();
    getMyApps();
  }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  Future<void> getMyApps() async {
    final dbRecentMiniApps =
        await objectMgr.miniAppMgr.getMiniAppsFromDB(MiniAppType.recent);
    if (dbRecentMiniApps.isNotEmpty) {
      dbRecentMiniApps.sort((a, b) {
        // 如果 time 可能为 null，使用 ?? 运算符提供默认值
        return (b.last_login_at ?? 0).compareTo(a.last_login_at ?? 0);
      });
      // recentApps.value = dbRecentMiniApps.take(4).toList();
    }
    final dbFavoriteMiniApps =
        await objectMgr.miniAppMgr.getMiniAppsFromDB(MiniAppType.favorite);
    if (dbFavoriteMiniApps.isNotEmpty) {
      dbFavoriteMiniApps.sort((a, b) {
        // 如果 time 可能为 null，使用 ?? 运算符提供默认值
        return (b.last_login_at ?? 0).compareTo(a.last_login_at ?? 0);
      });
      // myApps.value = dbFavoriteMiniApps;
    }
    final miniAppMyApp = await objectMgr.miniAppMgr.fetchMyApps();
    List<Apps> allRecenApptList = miniAppMyApp.recentList ?? [];

    /// 排序
    allRecenApptList.sort((a, b) {
      // 如果 time 可能为 null，使用 ?? 运算符提供默认值
      return (b.last_login_at ?? 0).compareTo(a.last_login_at ?? 0);
    });
    allRecentApps.value = allRecenApptList;
    recentApps.value = allRecentApps.take(4).toList();

    // myAllApps.value = miniAppMyApp.favoriteList ?? [];
    myApps.value = miniAppMyApp.favoriteList ?? [];
    for (int i = 0; i < myApps.length; i++) {
      itemOpacityList[i] = 1.0; // 默认值设置为 1.0
    }
    if (recentApps.isNotEmpty) {
      objectMgr.miniAppMgr.saveMiniAppsToDB(recentApps, MiniAppType.recent);
    }
    if (myApps.isNotEmpty) {
      objectMgr.miniAppMgr.saveMiniAppsToDB(myApps, MiniAppType.favorite);
    }

    setIsMoreApps(isMoreApps.value);
  }

  void setIsMoreApps(bool isMore) {
    isMoreApps.value = isMore;
    // isMoreApps.value ? recentApps.value = allRecentApps : recentApps.value = allRecentApps.take(4).toList();
  }

  Future<void> goPullDownSearch() async {
    final result = await Get.to<Map<String, bool>>(
      const PullDownSearchApplet(),
      binding: BindingsBuilder(() {
        Get.put(PullDownSearchController());
      }),
    );
    if (result?['refresh'] == true) {
      getMyApps();
    }
  }

  void joinMiniApp(Apps app, BuildContext context) {
    objectMgr.miniAppMgr.joinMiniApp(app, context);
  }

  void removeFavorite(Apps app) {
    objectMgr.miniAppMgr.removeFavorite(app).then(
      (res) {
        imBottomToast(
          Get.context!,
          margin: EdgeInsets.only(
              bottom: Platform.isIOS
                  ? ChatListController.appletAppBarHeight - 20
                  : ChatListController.appletAppBarHeight + 12,
              left: 12,
              right: 12),
          icon: ImBottomNotifType.success,
          title: localized(miniAppDeleted), // 已取消收藏
        );
        getMyApps();
      },
    );
  }

  void removeRecent(Apps app) {
    objectMgr.miniAppMgr.removeRecent(app).then(
          (res) {
        imBottomToast(
          Get.context!,
          margin: EdgeInsets.only(
              bottom: Platform.isIOS
                  ? ChatListController.appletAppBarHeight - 20
                  : ChatListController.appletAppBarHeight + 12,
              left: 12,
              right: 12),
          icon: ImBottomNotifType.success,
          title: localized(miniAppDeleted), // 已取消收藏
        );
        getMyApps();
      },
    );
  }


  void recentAddToFavourite(Apps app) async {
    await objectMgr.miniAppMgr.addFavorite(app);
    getMyApps();

    imBottomToast(
      Get.context!,
      margin: EdgeInsets.only(
          bottom: Platform.isIOS
              ? ChatListController.appletAppBarHeight - 20
              : ChatListController.appletAppBarHeight + 12,
          // bottom: scStatus.value == SpecialContainerStatus.min.index
          //     ? kTitleHeight + ScreenUtil().statusBarHeight - 4 + 15
          //     : kTitleHeight + ScreenUtil().statusBarHeight + 15,
          left: 12,
          right: 12),
      title: localized(addToFav),
      icon: ImBottomNotifType.success,
    );
  }
}
