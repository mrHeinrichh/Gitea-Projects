import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/setting/dekstop/desktop_setting_view.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sys_oprate_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/call_log/call_log_view.dart';
import 'package:jxim_client/views/component/app_version_alert.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/home/game_home_controller.dart';
import 'package:jxim_client/views/download_version_progress_dialog.dart';

import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/contact/contact_view.dart';
import 'package:jxim_client/views_desktop/contact/desktop_contact_view.dart';
import 'package:jxim_client/home/chat/pages/chat_view.dart';
import 'package:jxim_client/home/chat/desktop/desktop_chat_view.dart';

class HomeController extends GameHomeController
    with WidgetsBindingObserver, GetTickerProviderStateMixin {
  double _maxChatCellHeight = objectMgr.loginMgr.isDesktop ? 85 : 76;
  bool _eventTriggered = false; //防止事件重复发送 ios 不用处理
  /// VARIABLES

  TabController? tabController;

  final BuildContext context = Routes.navigatorKey.currentContext!;

  /// 当前页数
  final pageIndex = 0.obs;

  /// 返回次数
  int clickCount = 0;

  /// 返回时的时间
  int clickTime = 0;

  /// 有版本更新
  RxBool isShowSoftUpdate = false.obs;
  RxBool isRecommendUninstall = false.obs;
  RxBool isShowRedDot = false.obs;
  final apkDownloadProgress = 0.0.obs;
  final fileSize = 0.obs;
  final totalFileSize = 0.obs;
  final countdown = 10.obs;
  late Timer timer; // Timer object

  final user = Rxn<User>();

  final List<Widget> pageWidget = <Widget>[
    getChatView(),
    getDiscoveryView(),
    getContactView(),
    getSettingView(),
  ];

  /// 好友请求数量
  RxInt requestCount = 0.obs;
  RxInt missedCallCount = 0.obs;

  bool isAlertDialogOpen = false;

  /// METHODS
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(
      animationDuration: const Duration(milliseconds: 0),
      length: pageWidget.length,
      vsync: this,
    );
    user.value = objectMgr.userMgr.mainUser;
    WidgetsBinding.instance.addObserver(this);

    /// 封号弹窗
    objectMgr.sysOprateMgr
        .on(SysOprateMgr.eventForceLogout, _forceLogoutWindow);
    objectMgr.on(ObjectMgr.eventToLogin, _onEventToLogin);
    objectMgr.on(ObjectMgr.eventAppUpdate, _onAppVersionUpdate);
    objectMgr.on(ObjectMgr.eventCloseAppSoftUpdate, _closeAppSoftUpdate);

    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);

    _initData();

    /// 清除搜索的flag
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ChatListController chatController = Get.find<ChatListController>();
      CallLogController logController = Get.find<CallLogController>();
      ContactController contactController = Get.find<ContactController>();
      SettingController settingController = Get.find<SettingController>();

      tabController!.addListener(() {
        if (!tabController!.indexIsChanging) {
          chatController.clearSearching();
          contactController.clearSearching();
          settingController.clearSearching();

          if (tabController!.index == 1) {
            logController.getLocalCallLog(needRead: true);
          } else if (tabController!.index == 2) {
            contactController.getSortType();
          } else if (tabController!.index == 3) {
            settingController.checkVersionUpdate();
          }
        }
      });

      ever(
          contactController.newFriendReqList,
          (_) => requestCount.value = contactController.newFriendReqList.entries
              .where((entry) => entry.value == 0)
              .length);
    });

    avatarHelper.genCustomAvatar = ({
      Key? key,
      required int uid,
      required double size,
      bool isGroup = false,
      int? headMin,
      Function()? onTap,
      Function()? onLongPress,
      double? fontSize,
      bool isFullPage = false,
      bool isShowInitial = false,
      bool withEditEmptyPhoto = false,
      bool shouldAnimate = true,
    }) {
      return CustomAvatar(uid: uid, size: size,isGroup: isGroup);
    };
  }

  addMissedCallUnread(int count) {
    if (tabController!.index != 1) {
      missedCallCount.value++;
    }
  }

  _initData() async {
    await objectMgr.initMainUser(objectMgr.userMgr.mainUser);

    ///判断上一页是否是启动页，如果是无需初始化网络操作
    if (Get.previousRoute != RouteName.boarding &&
        Get.previousRoute != RouteName.desktopLoginQR &&
        Get.previousRoute != RouteName.registerProfile) {
      await objectMgr.initKiwi();
    } else {
      await objectMgr.initMainUserAfterNetwork();
      objectMgr.onAppDataReload();
    }

    //設置語音群聊的裝置id
    // await objectMgr.loginMgr.getOSType();
    // String deviceId = await objectMgr.loginMgr.deviceId;
    // audioManager.setDeviceId(deviceId);
    // todo 暂时注释掉这行代码，因为会导致接听铃声断断续续的问题
    // await SoundMode.ringerModeStatus;
  }

  @override
  void onReady() {
    super.onReady();
    if (objectMgr.loginMgr.isDesktop) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        objectMgr.initCompleted();
      });
    }
    Future.delayed(const Duration(milliseconds: 1000), () {
      initImAndLeague();
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    double height = MediaQuery.of(context).viewInsets.bottom;
    if (height == 0 && Platform.isAndroid) {
      if (!_eventTriggered) {
        objectMgr.chatMgr
            .event(objectMgr.chatMgr, ChatMgr.cancelKeyboardEvent, data: 0);
        _eventTriggered = true;
      }
    } else {
      _eventTriggered = false;
    }
  }

  @override
  void onClose() {
    objectMgr.sysOprateMgr
        .off(SysOprateMgr.eventForceLogout, _forceLogoutWindow);
    objectMgr.off(ObjectMgr.eventToLogin, _onEventToLogin);
    objectMgr.off(ObjectMgr.eventAppUpdate, _onAppVersionUpdate);
    objectMgr.off(ObjectMgr.eventCloseAppSoftUpdate, _closeAppSoftUpdate);

    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    WidgetsBinding.instance.removeObserver(this);

    super.onClose();
  }

  /// 监控回调函数
  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      final user = data;
      if (objectMgr.userMgr.isMe(user.uid)) {
        this.user.value = user;
        update(['bottomNav']);
      }
    }
  }

  void _onAppVersionUpdate(Object sender, Object type, Object? data) {
/*    if (data is EventAppVersion) {
      if (data.updateType == AppVersionUpdateType.minVersion.value) {
        showUpdateAlert(Get.context!, isForce: true);
      } else if (data.updateType == AppVersionUpdateType.version.value) {
        showSoftUpdateNotification(data);
      }
    }*/
  }

  void _closeAppSoftUpdate(Object sender, Object type, Object? data) {
    if (data is bool) {
      isShowRedDot.value = data;
    }
  }

  void _forceLogoutWindow(Object sender, Object type, Object? data) {
    if (data == null) return;
    Map<String, dynamic> response = jsonDecode(data.toString());
    objectMgr.logout();
    objectMgr.isForceLogout = true;
    objectMgr.forceShowToast(response);
  }

  void _onEventToLogin(Object sender, Object type, Object? data) {
    Get.until(
      (route) =>
          Get.currentRoute ==
          (objectMgr.loginMgr.isDesktop
              ? RouteName.desktopBoarding
              : RouteName.boarding),
    );
  }

  void onPageChange(int index) {
    if (pageIndex == index) return;
    if (objectMgr.loginMgr.isDesktop) {
      switch (index) {
        case 0:
          Get.find<ChatListController>().desktopSelectedChatID.value = 01010;

          if (pageIndex == 2) {
            Get.offAllNamed("SSS", id: 2);
            Get.toNamed(RouteName.desktopChatEmptyView, id: 2);
          }
          break;
        case 2:
          Get.find<ContactController>().selectedUserUID.value = 101010;

          if (pageIndex == 0) {
            Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
          }
          break;
        case 3:
          if (pageIndex == 0) {
            Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
          } else if (pageIndex == 2) {
            Get.offAllNamed("SSS", id: 2);
            Get.toNamed(RouteName.desktopChatEmptyView, id: 2);
          }
          Get.find<SettingController>().selectedIndex.value = 101010;
          break;
      }
    }

    pageIndex.value = index;
    tabController!.animateTo(index,
        duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
    update(['bottomNav'].toList());
  }

  void onDoubleTap(int index) {
    ChatListController chatController = Get.find<ChatListController>();
    int currChatIndex =
        (chatController.scrollController.offset / _maxChatCellHeight.toDouble())
            .ceil();
    if (currChatIndex > chatController.chatList.length ||
        chatController.scrollController.position ==
            chatController.scrollController.position.maxScrollExtent) {
      currChatIndex = 0;
    }

    bool isFind = false;
    int hideChatCount = 0;
    int findChatIndex = 0;
    for (findChatIndex = currChatIndex + hideChatCount;
        findChatIndex < chatController.chatList.length;
        findChatIndex++) {
      Chat chat = chatController.chatList[findChatIndex];
      if (chat.unread_count > 0) {
        isFind = true;
        break;
      }
    }

    if (isFind) {
      chatController.scrollController.animateTo(
          _maxChatCellHeight * (findChatIndex - hideChatCount) + kToolbarHeight,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 200));
    } else {
      chatController.scrollController.animateTo(kToolbarHeight,
          curve: Curves.linear, duration: const Duration(milliseconds: 200));
    }
  }

  /// ================================ App更新逻辑 ===============================
  void showSoftUpdateNotification(EventAppVersion data) {
    if (data.isShow) {
      bool? appUpdateNotification = objectMgr.localStorageMgr
          .read(LocalStorageMgr.APP_UPDATE_NOTIFICATION);

      /// 检查用户是否手动关闭版本更新提示
      if (appUpdateNotification == null || appUpdateNotification == true) {
        isShowSoftUpdate.value = true;
        isRecommendUninstall.value = data.isShowUninstall!;
      }
    } else {
      /// 如果data.isShow == false，此版本已经是最新版本(此情况通常发生在revert版本)
      isShowSoftUpdate.value = false;
    }
  }

  Future<void> showUpdateAlert(BuildContext context,
      {bool isForce = false}) async {
    if (appVersionUtils.enableDialog) {
      appVersionUtils.enableDialog = false;
      try {
        final PlatformDetail? data =
            await appVersionUtils.getAppVersionByRemote();

        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AppVersionAlert(
              isForce: isForce,
              version: data?.version ?? "0.0.0",
              description: data?.description ?? "",
              installCallback: () => showDownloadVersionProgress(context, data),
              downloadPackageCallback: () => redirectToWebDownload(data?.url),
            );
          },
        ).whenComplete(() => appVersionUtils.enableDialog = true);
      } catch (e) {
        appVersionUtils.enableDialog = true;
      }
    }
  }

  void showDownloadVersionProgress(BuildContext context, PlatformDetail? data) {
    if (!Platform.isIOS) {
      if (data != null) {
        startTimer();
        doDownload(context, data);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return DownloadVersionProgressDialog(
              downloadPackageCallback: () => redirectToWebDownload(data.url),
            );
          },
        ).whenComplete(() {
          timer.cancel();
          countdown.value = 10;
        });
      }
    } else {
      redirectToWebDownload(data?.url);
    }
  }

  void doDownload(BuildContext context, PlatformDetail data) async {
    if (apkDownloadProgress.value == 0) {
      appVersionUtils.openDownloadLink(context, data, didDownloaded: () {
        apkDownloadProgress.value = 0;
        appVersionUtils.enableDialog = true;
      });
    }
  }

  void doCancel() {
    if (appVersionUtils.cancelToken != null) {
      appVersionUtils.cancelToken?.cancel();
      appVersionUtils.enableDialog = true;

      apkDownloadProgress.value = 0;
      fileSize.value = 0;
      totalFileSize.value = 0;

      //清楚没下载好的文件
      File file = File(appVersionUtils.apkSavePath ?? "");
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    appVersionUtils.cancelProgressNotification();
    Get.back();
  }

  void disableSoftUpdateNotification() {
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.APP_UPDATE_NOTIFICATION, false);
    isShowSoftUpdate.value = false;
    isRecommendUninstall.value = false;
    objectMgr.event(objectMgr, ObjectMgr.eventCloseAppSoftUpdate, data: true);
  }

  void redirectToWebDownload(String? url) {
    if (notBlank(url)) {
      linkToWebView(url ?? "", useInternalWebView: false);
    } else {
      Toast.showToast(localized(toastLinkInvalid));
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel(); // Stop the timer when countdown reaches 0
      }
    });
  }

  bool showVersionBar() {
    return pageIndex == 0 && isShowSoftUpdate.value;
  }
}

Widget getChatView() {
  if (objectMgr.loginMgr.isDesktop) {
    return const DesktopChatView();
  } else {
    return const ChatView();
  }
}

Widget getCallLogView() {
  if (objectMgr.loginMgr.isDesktop) {
    return const SizedBox();
  } else {
    return const CallLogView();
  }
}

Widget getContactView() {
  if (objectMgr.loginMgr.isDesktop) {
    return const DesktopContactView();
  } else {
    return const ContactView();
  }
}

getSettingView() {
  if (objectMgr.loginMgr.isDesktop) {
    return const DesktopSettingView();
  } else {
    return SettingView();
  }
}
