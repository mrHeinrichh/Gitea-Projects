import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/api/mini_api.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/mini/bean/mini_app_my_app.dart';
import 'package:jxim_client/network/dun_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/special_container/special_container_overlay.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:mini_app_service/mini_app_service.dart';
import 'package:path_provider/path_provider.dart';

class MiniAppMgr extends EventDispatcher {

  RxString h5Text = "".obs;

  RxBool isH5SpecialMiniAppLoadingDone = false.obs;
  RxList h5List = [].obs;
  RxString h5Color = "".obs;

  List<Apps> discoverApps = [];
  RxList<Apps> miniApps = RxList.empty(growable: true);
  bool callBeforeMiniAppStatusIsFull = false;
  int groupId = 15768;
  int host = 8888;

  bool isShowMiniApp = true;

  /// 小程序的url前缀
  String miniAppShareUrlPrefix = "miniapp://app?appid=";

  bool isSpecialHorizontalScreen = false;

  String currentOpenUid = "";
  String startUrl = "";
  final _currentApp = Rxn<Apps>();

  Apps? get currentApp => _currentApp.value;

  set currentApp(Apps? app) => _currentApp.value = app;

  final isAwesomeApp = false.obs;

  String basePath = "";

  bool? _isHasPermissions;

  bool get isHasPermissions {
    return _isHasPermissions ?? false;
  }

  set isHasPermissions(bool? value) {
    _isHasPermissions = value;
  }

  Future<Apps> login(String appId) async {
    Map<String, dynamic> dataBody = {
      "appid": appId,
      "channel_id": Config().orgChannel,
    };

    Apps data = await miniAppLogin(dataBody);
    return data;
  }

  Future<List<Apps>> findMini([String? name = '']) async {
    Map<String, dynamic> dataBody = {
      "name": name,
      "page": 1,
      "limit": 30,
      "channel_id": Config().orgChannel,
    };

    MiniAppItemBean data = await miniAppFind(dataBody);
    List<Apps> apps = data.apps ?? [];

    /// 如果不显示在搜索栏的小程序需要过滤掉
    List<Apps> list = [];
    for (Apps app in apps) {
      if (app.flag != null && app.flag! > 0) {
        if (app.flag! & 1 != 0) {
          list.add(app);
        }
      }
    }
    return list;
  }

  Future<Apps> getMini(String? appId) async {
    Map<String, dynamic> dataBody = {
      "appid": appId,
      "channel_id": Config().orgChannel,
    };

    Apps data = await miniAppGet(dataBody);
    return data;
  }

  loginSingleMiniApp(BuildContext context,
      {String? shareCode, required String appId}) async {
    if (!common.CoolDownManager.handler(key: "onMenuTap", duration: 500)) {
      return;
    }
    Apps miniApp = await login(appId);
    currentApp = miniApp;
    if ((miniApp.isCanOpenThisMiniApp) && !isHasPermissions) {
      showToast("敬请期待");
      return;
    }

    ///检查当前版本，如果低于在线版本，重新下载zip,如果相同则不需要
    int version = miniApp.version ?? 0;
    String url = miniApp.downloadUrl ?? "";
    currentOpenUid = miniApp.openuid ?? "";

    ///如果有隐藏符，则去掉隐藏符号
    String cleanedStr = url.replaceAll(RegExp(r'\u200B'), '');
    if (cleanedStr.startsWith("/")) {
      url = serversUriMgr.download1Uri.toString() + cleanedStr;
    } else {
      url = serversUriMgr.download1Uri.toString() + "/" + cleanedStr;
    }

    if (shareCode != null && shareCode.isNotEmpty) {
      startUrl = "http://localhost:$host/register?shareCode=$shareCode";
    } else {
      startUrl = "http://localhost:$host";
    }

    /// 下载和解压小程序
    if (url.isNotEmpty) {
      initMiniAppServer(url, version.toDouble(), "${miniApp.id}");
      SpecialContainerOverlay.showOverlayMax(type: SpecialContainerType.full);
    } else {
      showWarningToast(localized(miniAppTryLater));
    }
  }

  void initMiniAppServer(String url, double version, String appId) {
    NewMiniAppServerConfig config = NewMiniAppServerConfig.zip(
        appId, url, host, (version.toDouble()).toString());
    MiniAppManager.shared.addOrUpdateAppWithServerConfig(config).then((value) {
      MiniAppManager.shared.startAppServer(appId);
    });
  }

  void onLaunchLinkOpen(String text, BuildContext context) async {
    Uri uri = Uri.parse(text);
    String? appId = uri.queryParameters['appid'];
    String? shareCode = uri.queryParameters['shareCode'];
    loginSingleMiniApp(context, appId: appId ?? "0", shareCode: shareCode);
  }

  Future<void> joinMiniAppOrder(
      BuildContext context, String link, int friendId) async {
    Uri uri = Uri.parse(link);
    String pathAndQuery = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    if (!common.CoolDownManager.handler(key: "onMenuTap", duration: 500)) {
      return;
    }
    Apps appItem = await miniAppFriendIdLogin(friendId: friendId);
    if (appItem == null) {
      showWarningToast(localized(miniAppWasNotFound));
      return;
    }
    if ((appItem.isCanOpenThisMiniApp) && !isHasPermissions) {
      showToast("敬请期待");
      return;
    }
    Apps apps = await login(appItem.id ?? "");

    ///检查当前版本，如果低于在线版本，重新下载zip,如果相同则不需要
    int version = apps.version ?? 0;
    String url = apps.downloadUrl ?? "";
    currentOpenUid = apps.openuid ?? "";
    currentApp = apps;

    ///如果有隐藏符，则去掉隐藏符号
    String cleanedStr = url.replaceAll(RegExp(r'\u200B'), '');
    if (cleanedStr.startsWith("/")) {
      url = serversUriMgr.download1Uri.toString() + cleanedStr;
    } else {
      url = serversUriMgr.download1Uri.toString() + "/" + cleanedStr;
    }

    startUrl = "http://localhost:$host$pathAndQuery";

    /// 下载和解压小程序
    if (url.isNotEmpty) {
      initMiniAppServer(url, version.toDouble(), "${apps.id}");
      SpecialContainerOverlay.showOverlayMax(type: SpecialContainerType.full);
    } else {
      showWarningToast(localized(miniAppTryLater));
    }
  }

  ///  小程序统一入口 点击事件
  Future<void> joinMiniApp(Apps app, BuildContext context) async {
    if (currentApp != null) {
      await MiniAppManager.shared.stopAppServer("${currentApp?.id}");
    }
    if ((app.isCanOpenThisMiniApp) && !isHasPermissions) {
      showToast("敬请期待");
      return;
    }
    Apps bean = await login(app.id ?? "");
    int version = bean.version ?? 0;
    String url = bean.downloadUrl ?? "";
    currentOpenUid = bean.openuid ?? "";
    String cleanedStr = url.replaceAll(RegExp(r'\u200B'), '');
    if (cleanedStr.isEmpty) {
      showWarningToast("小程序下载路径为空，请联系管理员");
      return;
    }
    if (cleanedStr.startsWith("/")) {
      url = serversUriMgr.download1Uri.toString() + cleanedStr;
    } else {
      url = serversUriMgr.download1Uri.toString() + "/" + cleanedStr;
    }
    currentApp = bean;
    if (app.screen == MiniAppScreenType.horizontal.value) {
      isSpecialHorizontalScreen = true;
      startUrl = await getMiniAppToken("${app.id}");
      if (startUrl == null || startUrl.isEmpty) {
        return;
      }
      specialMiniAppJoin();
      MiniAppManager.shared.didCloseWebPage = (String appId, String route) {
        SpecialContainerOverlay.minOverlay();
        return;
      };
    } else {
      isSpecialHorizontalScreen = false;
      startUrl = "http://localhost:$host";
    }
    if (url.isNotEmpty) {
      SpecialContainerOverlay.closeOverlay();
      initMiniAppServer(url, version.toDouble(), "${app.id}");
      if (app.screen == MiniAppScreenType.special.value) {
        if(basePath.trim().isEmpty){
          basePath =await getAppDirectory();
        }
        isAwesomeApp.value = true;
      } else {
        isAwesomeApp.value = false;
      }
      closeApplet();
      SpecialContainerOverlay.showOverlayMax(type: SpecialContainerType.full);
      insertSingleMiniAppsToDB(app, MiniAppType.recent);
    } else {
      showWarningToast(localized(miniAppTryLater));
    }
  }

  void closeApplet() {
    if (Get.currentRoute == RouteName.home) {
      final chatListController = Get.find<ChatListController>();
      if (chatListController.isShowingApplet.value) {
        chatListController.backToMainPageByAnimation();
        Get.delete<PullDownAppletController>();
      }
    }
  }

  Future<bool> addFavorite(Apps app) async {
    Map<String, dynamic> dataBody = {
      "appid": app.id,
      "channel_id": Config().orgChannel,
    };

    insertSingleMiniAppsToDB(app, MiniAppType.favorite);
    bool data = await miniAppAddFavorite(dataBody);
    return data;
  }

  Future<bool> removeFavorite(Apps app) async {
    Map<String, dynamic> dataBody = {
      "appid": app.id,
      "channel_id": Config().orgChannel,
    };

    objectMgr.localDB.removeFavoriteMiniApp(app.id!);
    bool data = await miniAppRemoveFavorite(dataBody);
    return data;
  }

  Future<bool> removeRecent(Apps app) async {
    Map<String, dynamic> dataBody = {
      "appid": app.id,
      "channel_id": Config().orgChannel,
    };

    objectMgr.localDB.removeRecentMiniApp(app.id!);
    bool data = await miniAppRemoveRecent(dataBody);
    return data;
  }

  /// 我的小程序
  Future<MiniAppMyApp> fetchMyApps() async {
    Map<String, dynamic> dataBody = {
      "channel_id": Config().orgChannel,
    };

    MiniAppMyApp data = await miniAppMy(dataBody);
    return data;
  }

  // 存储小程序到本地DB
  Future<void> saveMiniAppsToDB(
      List<Apps> appList, MiniAppType saveType) async {
    if (saveType == MiniAppType.explore) {
      await objectMgr.localDB.clearExploreMiniAppTable();
      for (var element in appList) {
        objectMgr.localDB.insertExploreMiniApp(element.toJson());
      }
    } else if (saveType == MiniAppType.recent) {
      await objectMgr.localDB.clearRecentMiniAppTable();
      for (var element in appList) {
        objectMgr.localDB.insertRecentMiniApp(element.toJson());
      }
    } else if (saveType == MiniAppType.discover) {
      await objectMgr.localDB.clearDiscoverMiniAppTable();
      for (var element in appList) {
        objectMgr.localDB.insertDiscoverMiniApp(element.toJson());
      }
    } else {
      await objectMgr.localDB.clearFavoriteMiniAppTable();
      for (var element in appList) {
        objectMgr.localDB.insertFavoriteMiniApp(element.toJson());
      }
    }
  }

  // 获取本地DB的小程序
  Future<List<Apps>> getMiniAppsFromDB(MiniAppType saveType) async {
    if (saveType == MiniAppType.explore) {
      final data = await objectMgr.localDB.loadExploreMiniApps();
      return data?.map((e) => Apps.fromJson(e)).toList() ?? [];
    } else if (saveType == MiniAppType.recent) {
      final data = await objectMgr.localDB.loadRecentMiniApps();
      return data?.map((e) => Apps.fromJson(e)).toList() ?? [];
    } else if (saveType == MiniAppType.discover) {
      final data = await objectMgr.localDB.loadDiscoverMiniApps();
      return data?.map((e) => Apps.fromJson(e)).toList() ?? [];
    } else {
      final data = await objectMgr.localDB.loadFavoriteMiniApps();
      return data?.map((e) => Apps.fromJson(e)).toList() ?? [];
    }
  }

  // 在本地DB最近使用或者收藏小程序插入一条数据
  Future<void> insertSingleMiniAppsToDB(Apps app, MiniAppType saveType) async {
    if (saveType == MiniAppType.recent) {
      objectMgr.localDB.insertRecentMiniApp(app.toJson());
    } else {
      objectMgr.localDB.insertFavoriteMiniApp(app.toJson());
    }
  }

  void onRestore() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  setOrientation() async {
    // 设置支持的屏幕方向
    if (Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
      ]);
      // await AutoOrientation.landscapeRightMode();
    }
    if (Platform.isAndroid) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
    }

    // 进入页面时隐藏系统状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  Future<String> getMiniAppToken(String appId) async {
    MiniAppConstants.specialHorizontalScreenAppId = appId;
    Map<String, dynamic> map = {
      'gid': groupId,
    };
    ResponseData res = await postMiniAppToken(map);
    if (res.code != 0) {
      showToast(res.message);
      return "";
    }
    var data = res.data;
    String token = data['token'];
    String serviceUrl = data['service_url'];
    Uri remoteUri = Uri.parse(serviceUrl);
    Uri ret = await dunMgr.serverToLocal(remoteUri) ?? remoteUri;
    String sessionKey = Uri.encodeQueryComponent(token);
    String url =
        "http://localhost:$host/?serviceurl=localhost:${ret.port}&sessionkey=$sessionKey&p=classic&assert_host=${serversUriMgr.download2Uri?.origin}&gameid=mpniuniu";
    debugPrint("========= $url");
    return url;
  }

  Future<void> miniAppExit() async {
    await postSpecialMiniAppExit({
      "gid": groupId,
      "currency": "USDT",
    });
  }

  Future<void> specialMiniAppJoin() async {
    await postSpecialMiniAppJoin({
      "gid": groupId,
      "currency": "USDT",
    });
  }

  void checkChats(List<Chat> chats) {
    if (_isHasPermissions == null) {
      for (Chat chat in chats) {
        if (chat.isGroup && chat.id == groupId) {
          if (objectMgr.myGroupMgr.isGroupValid(chat.chat_id)) {
            _isHasPermissions = true;
          }
          break;
        }
      }
    }
  }

  Future<void> onBottomMiniAppClick() async {
    if (currentApp?.screen == MiniAppScreenType.horizontal.value) {
      setOrientation();
      await Future.delayed(const Duration(milliseconds: 700), () {});
    }
    return Future(() => null);
  }

  void restoreMiniAppViewStatus() {
    if (callBeforeMiniAppStatusIsFull) {
      SpecialContainerOverlay.showOverlayMax(type: SpecialContainerType.full);
      callBeforeMiniAppStatusIsFull = false;
    }
  }

  void saveCurrentMiniAppViewStatus() {
    callBeforeMiniAppStatusIsFull =
        scStatus.value == SpecialContainerStatus.max.index;
  }

  void logout() {
    _isHasPermissions = null;
  }

  void closeMiniApp() {
    Map<String, dynamic> exitMap = {
      "methodName": "onExitApp",
      "methodParam": {}
    };
    MiniAppManager.shared
        .callMiniApp("${currentApp?.id}", json.encode(exitMap));
    onExitApp();
  }

  void onExitApp() {
    scStatus.value = SpecialContainerStatus.none.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SpecialContainerOverlay.closeOverlay();
      objectMgr.miniAppMgr.isH5SpecialMiniAppLoadingDone.value =false;
    });
  }

  void init() {
    MiniAppManager.shared.init();
    Future.delayed(const Duration(milliseconds: 1000), () async {
      discoverApps = await getMiniAppsFromDB(MiniAppType.discover);
      objectMgr.miniAppMgr.miniApps.value = discoverApps;
    });
  }

  Future<void> getDiscoverMiniAppList() async {
    List<Apps> list = [];
    List<Apps> apps = await objectMgr.miniAppMgr.findMini();
    for (Apps app in apps) {
      if (app.flag != null && app.flag! > 0) {
        if (app.flag! & 2 != 0) {
          if (app.isCanOpenThisMiniApp) {
            if (objectMgr.miniAppMgr.isHasPermissions) {
              list.add(app);
            }
          } else {
            list.add(app);
          }
        }
      }
    }
    objectMgr.miniAppMgr.miniApps.value = list;
    bool areEqual = Set.from(list).containsAll(discoverApps) &&
        Set.from(discoverApps).containsAll(list);
    if (!areEqual) {
      objectMgr.miniAppMgr.saveMiniAppsToDB(list, MiniAppType.discover);
      discoverApps = list;
    }
  }

  Future<void> useFriendIdLoginMiniApp(BuildContext context,
      {required int friendId}) async {
    Apps appItem = await miniAppFriendIdLogin(friendId: friendId);
    joinMiniApp(appItem, context);
  }


  /// 获取目录
  Future<String> getAppDirectory() async {
    try {
      Directory appDir = await getApplicationSupportDirectory();
      return appDir.path;
    } catch (e) {
      return "";
    }
  }

 Future<String> getDescription(int friendId) async {
   Apps appItem = await miniAppFriendIdLogin(friendId: friendId);
    return appItem.description??"--";
  }
}
