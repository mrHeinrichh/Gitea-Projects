import 'dart:convert';
import 'package:im_common/im_common.dart' as common;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/share_home_extension.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/mini/components/local_mini_app_widget.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:mini_app_service/mini_app_service.dart';

extension MiniAppExtension on LocalMiniAppWidgetState {
  void onMiniAppEResult(Map<String, dynamic> methodParam) {
    objectMgr.miniAppMgr.isH5SpecialMiniAppLoadingDone.value = true;
    objectMgr.miniAppMgr.h5Text.value = methodParam["text"];
    objectMgr.miniAppMgr.h5List.value = methodParam["result"];
    objectMgr.miniAppMgr.h5Color.value = methodParam["color"];
  }

  void init(Apps app) async {
    onMIniAppCall(app);
    MiniAppManager.shared.onLoadStopCallBack ??=
        (String appId, String route, String url) {
      //检测url变化
    };
  }

  void onMIniAppCall(Apps app) {
    MiniAppManager.shared.onMiniAppCall =
        (String appId, String route, String jsonStr) async {
      /// 接收来自和的回调
      Map<String, dynamic> map = jsonDecode(jsonStr);
      String methodName = map["methodName"] ?? "";
      Map<String, dynamic> methodParam = map["methodParam"] ?? {};
      if (methodName == "onHomeBack") {
        Get.back();
      } else if (methodName == "onSharedLink") {
        onShareLink(methodParam, true, app);
      } else if (methodName == "chat_login" || map["func"] == "chat_login") {
        ///发送openUid 给 H5
        Map<String, dynamic> importMap = {
          "func": map["func"],
          "chat_token": widget.openUid,
          "methodName": map["func"],
          "methodParam": {"chat_token": widget.openUid}
        };
        MiniAppManager.shared
            .callHouseKeeperMiniApp("${widget.app.id}", json.encode(importMap));
      } else if (methodName == "onInitAppConfig") {
        initAppConfig();
      } else if (methodName == "onVersion") {
        Map<String, dynamic> map = {
          "methodName": methodName,
          "methodParam": {
            "version": methodParam["version"],
          }
        };
        MiniAppManager.shared.callMiniApp("${widget.app.id}", json.encode(map));
        imBottomToast(
          navigatorKey.currentContext!,
          title: "version:${methodParam["version"]}",
        );
      } else if (methodName == "onExitApp") {
        objectMgr.miniAppMgr.onExitApp();
      } else if (methodName == "onRdResult") {
        onMiniAppEResult(methodParam);
      }
    };
  }

  void initAppConfig() {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    Map<String, dynamic> importMap = {
      "methodName": "onInitAppConfig",
      "methodParam": {
        "httpBaseURL": common.CommonConstants.baseGameUrl,
        "wsBaseURL": serversUriMgr.socketUri.toString(),
        "token": objectMgr.loginMgr.account?.token,
        "channelId": Config().orgChannel,
        "language": objectMgr.langMgr.currLocale.languageCode,
        "platform": appVersionUtils.getDownloadPlatform() ?? '',
        "currentAppVersion": appVersionUtils.currentAppVersion,
        "topPadding": topPadding,
        "bottomPadding": bottomPadding,
      }
    };
    MiniAppManager.shared
        .callMiniApp("${widget.app.id}", json.encode(importMap));
  }

  // 链接分享
  Future<void> onShareLink(
      Map<String, dynamic> methodParam, bool isNeedAppId, Apps app) async {
    try {
      if (!common.CoolDownManager.handler(
          key: "shareBottomSheet", duration: 500)) {
        return;
      }
      HomeController controller;
      if (!Get.isRegistered<HomeController>()) {
        controller = Get.put(HomeController());
      } else {
        controller = Get.find<HomeController>();
      }
      ShareImage data = ShareImage.fromJson({});
      String url = methodParam['url'];
      if (isNeedAppId) {
        url += "&appid=${widget.app.id}";
      }
      data.dataList = [];
      String title = getTitle(methodParam["title"], app,isNeedAppId);
      ShareItem item = ShareItem.fromJson({
        "mini_app_link": url,
        'mini_app_title':title,
        "mini_app_avatar": app.icon,
        "mini_app_picture": app.picture,
        "mini_app_picture_gaussian": app.pictureGaussian,
        "mini_app_name": app.name,
      });
      data.dataList.add(item);
      await controller.onForwardMessageOnMiniApp(
          shareImage: data, isHousekeeperShare: true);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // 收藏 / 取消收藏
  void toggleFavorite(Apps app) {
    toggleDebounce.call(() async {
      await objectMgr.miniAppMgr.addFavorite(app);
      imBottomToast(
        Get.context!,
        title: localized(addToFav),
        icon: ImBottomNotifType.success,
        margin: const EdgeInsets.only(bottom: 15, left: 12, right: 12),
      );
    });
  }

  String getTitle(String?title, Apps app, bool isFromInH5Share) {
    if(isFromInH5Share){
      if(title !=null && title.isNotEmpty){
        return title;
      }
    }
    return localized(miniAppInvitationToUseApp, params: ['${app.name}']);
  }
}
