import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fconsole/widget/console.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/user.dart' as user_api;
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/im/bet_msg_filter/bet_msg_filter_manager.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/keyboard_height_mgr.dart';
import 'package:jxim_client/managers/kiwi_manage.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/login_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/navigator_mgr.dart';
import 'package:jxim_client/managers/offline_request_mgr.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/managers/schedule_mgr.dart';
import 'package:jxim_client/managers/share_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/managers/sys_oprate_mgr.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/managers/user_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/forceLogout.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/message/chat/custom_single_button.dart';
import 'package:openinstall_flutter_plugin/openinstall_flutter_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/views/component/floating/manager/floating_manager.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:path/path.dart';

class ObjectMgr extends EventDispatcher with WidgetsBindingObserver {
  static MediaQueryData? screenMQ;
  static EdgeInsets? viewPadding;

  // 事件
  /// 去登录
  static const String eventToLogin = "eventToLogin";
  static const String eventFlutterVerify = "eventFlutterVerify";
  static const String eventIOSLogin = "iosLogin";
  static const String eventAppLifeState = "eventAppLiftState"; // app唤醒状态
  static const String eventAppLifeMetrics = "eventAppLifeMetrics"; // app
  static const String eventServerChange = "eventServerChange"; // 服务器更改
  static const String eventForceLogoutChange =
      "eventForceLogoutChange"; // 封禁状态修改
  static const String eventAppUpdate = "eventAppUpdate"; // 版本更改
  static const String eventCloseAppSoftUpdate =
      "eventCloseAppSoftUpdate"; // 关闭版本更改
  static const String eventKiwiConnect = 'eventKiwiConnect'; // Kiwi连接成功

  // 数据库
  final DBInterface _localDB = DBManager();

  DBInterface get localDB => _localDB;

  //是否认证中
  String verifying = "";

  /// 本地数据表
  final SharedRemoteDB sharedRemoteDB = SharedRemoteDB();

  /// 本地存儲
  final LocalStorageMgr localStorageMgr = LocalStorageMgr();

  /// 断网管理器
  final OfflineRequestMgr offlineRequestMgr = OfflineRequestMgr();

  // IM
  final ChatMgr chatMgr = ChatMgr();

  final UserMgr userMgr = UserMgr();

  // 通话
  final CallMgr callMgr = CallMgr();

  /// 长连接管理器
  final SocketMgr socketMgr = SocketMgr();

  //我的群列表
  final MyGroupMgr myGroupMgr = MyGroupMgr();

  //系统行为通知
  final SysOprateMgr sysOprateMgr = SysOprateMgr();

  //心跳管理
  final ScheduleMgr scheduleMgr = ScheduleMgr();

  //跳转管理
  final NavigatorMgr navigatorMgr = NavigatorMgr();

  //登录管理
  final LoginMgr loginMgr = LoginMgr();

  // 语言管理器
  final LangMgr langMgr = LangMgr();

  // 贴纸管理器
  final StickerMgr stickerMgr = StickerMgr();

  final PushManager pushMgr = PushManager();

  /// 悬浮窗管理器初始化
  final FloatingManager floatingManager = FloatingManager();

  final MessageMgr messageManager = MessageMgr();

  final ShareMgr shareMgr = ShareMgr();

  final MgrTask taskMgr = MgrTask();

  final LogMgr logMgr = LogMgr();

  // 键盘高度管理
  final keyBoardHeightManager = KeyboardHeightManager();

  final appInitState = AppInitState.idle.obs;

  OpeninstallFlutterPlugin? openinstallFlutterPlugin;

  ObjectMgr() {
    Permissions.appName = Config().appName;
    PlatformUtils.appName = Config().appName;

    WidgetsBinding.instance.addObserver(this);
  }

  // 初始化
  Future<void> init() async {
    logMgr.init();

    connectivityMgr.initConnectivityMgr();
    offEventListeners();
    Request.event.on(Request.eventNotLogin, _onEventNotLogin);
    socketMgr.off(SocketMgr.updateBlock);
    socketMgr.off(SocketMgr.eventSocketOpen);
    socketMgr.on(SocketMgr.updateBlock, _onUpdateBlock);
    socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
    socketMgr.on(SocketMgr.eventSocketClose, _onSocketClose);
    objectMgr.once(ObjectMgr.eventKiwiConnect, _onKiwiConnect);

    if (Config().cleanLocalStorage) {
      localStorageMgr.cleanAll();
    }

    await chatMgr.register();
    betMsgFilterMgr.init();

    userMgr.register();
    callMgr.register();
    taskMgr.register();
    myGroupMgr.register();
    sysOprateMgr.register();
    scheduleMgr.register();
    shareMgr.register();
    messageManager.RegisterConsumeMsgFunc(chatMgr.processRemoteMessage);
    messageManager.RegisterOnLoadStatusChangeFunc(
        chatMgr.loadMessageStatusChange);
  }

  prepareDBData(User user) async {
    //启动的时候，就初始化kiwi
    kiwiMgr.initKiwi();
    await _localDB.init(user.id, Config().cleanSqflite);
    await Future.wait([chatMgr.init(), userMgr.init()]);
    scheduleMgr.register();
    scheduleMgr.init();
  }

  // 初始化主用户2
  Future<void> initMainUser(User user) async {
    Toast.hide();
    Request.token = this.loginMgr.account!.token;
    localStorageMgr.initUser(user.id);

    offlineRequestMgr.init();

    userMgr.onUserChanged([user], notify: true);
    taskMgr.init();
    //初始化我的群列表
    myGroupMgr.init();

    // 获取最爱贴纸
    stickerMgr.init();

    shareMgr.init();

    // 开发者模式
    getDeveloperMode();

    //重置弹窗
    userMgr.hasPopDialog = false;
  }

  Future<void> initMainUserAfterNetwork() async {
    pushMgr.init();
    // 通话
    callMgr.init();
    // 获取最新translation
    langMgr.getRemoteTranslation();

    // 从服务器获取键盘高度
    objectMgr.keyBoardHeightManager.init();

    await heartbeat(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  void _onEventNotLogin(Object sender, Object type, Object? data) {
    mypdebug(
        '===========================_onEventNotLogin.logout=================');
    // Request.flag = Request.flag + 1;
    // logout();
  }

  void _onSocketOpen(Object sender, Object type, Object? block) {
    user_api.jximLogin(objectMgr.loginMgr.account!.token);
  }

  void _onSocketClose(Object sender, Object type, Object? block) {}

  void _onKiwiConnect(Object sender, Object type, _) async {
    onNetworkOn();
    if (loginMgr.isLogin) {
      scheduleMgr.heartBeat.execute();
      initMainUserAfterNetwork();
    } else {
      objectMgr.pushMgr.reset();
    }
    // Kiwi链接回调和有实际网络有一定的延迟，有几率导致openinstall连接网络失败
    Future.delayed(
        const Duration(milliseconds: 100), () => initPlatformState());
  }

  Future<void> initPlatformState() async {
    openinstallFlutterPlugin = OpeninstallFlutterPlugin();
    openinstallFlutterPlugin?.init(wakeupHandler);
  }

  void getInstallInfo() {
    openinstallFlutterPlugin?.install(installHandler);
  }

  Future wakeupHandler(Map<String, Object> data) async {
    pdebug(
        "wakeupHandler===========> wakeup result : channel=${data['channelCode']}, data=${data['bindData']}");
  }

  Future installHandler(Map<String, Object> data) async {
    if (notBlank(data['bindData'])) {
      final inviterData =
          jsonDecode(data['bindData'].toString()) as Map<String, dynamic>;
      if (inviterData != null) {
        loginMgr.inviterSecret = inviterData["secret"];
      }
    }
    pdebug("installHandler=========> install result: $data");
  }

  void onNetworkOff() async {
    appInitState.value = AppInitState.no_connect;
    // socketMgr.logout();
  }

  Future<void> initKiwi() async {
    try {
      appInitState.value = AppInitState.connecting;
      kiwiMgr.initKiwi();
    } catch (e) {
      appInitState.value = AppInitState.no_connect;
      pdebug("【Dun Failed】: ${e.toString()}");
    }
    if (serversUriMgr.isKiWiConnected) {
      if (appInitState.value != AppInitState.fetching) {
        appInitState.value = AppInitState.done;
      }
    }
  }

  Future<void> addCheckKiwiTask() async {
    bool isConnected = await serversUriMgr.checkIsConnected();
    if (!isConnected) {
      scheduleMgr.addTask(scheduleMgr.checkKiwiTask);
    }
  }

  void onKiwiInit() {
    event(this, eventKiwiConnect);
  }

  void onNetworkOn() async {
    await onAppDataReload();
  }

  /// app 唤醒&网络连接时的初始化
  onAppDataReload() async {
    if (loginMgr.isLogin) {
      pdebug("onAppDataReload-socketInit");
      await serversUriMgr.onNetworkOn();
      final isSocketOpen = socketMgr.socket?.open ?? false;
      if (!isSocketOpen || !socketMgr.isConnect) {
        appInitState.value = AppInitState.connecting;
        socketMgr.init(this.loginMgr.account!.token);
      }

      userMgr.reloadData();
      chatMgr.reloadData();
      callMgr.reloadData();
      offlineRequestMgr.reloadData();
      if (Get.isRegistered<RedPacketController>()) {
        Get.find<RedPacketController>().initPage();
      }

      pushMgr.bindingDeviceWithAccount();
    }
  }

  /// 发生对象更新
  Future<void> _onUpdateBlock(Object sender, Object type, Object? block) async {
    if (block is UpdateBlockBean) {
      if (block.ctl == DBUser.tableName &&
          block.opt == blockOptUpdate &&
          objectMgr.userMgr.isMe(block.data['id'])) {
        // 如果是主玩家更新
        objectMgr.userMgr.mainUser.updateValue(block.data);
        return;

      }

      //重复登入
      if (block.ctl == objectMgr.userMgr.socketContentAuth) {
        userMgr.doUserLogout(block);
        return;
      }

      //联系人模块更新
      if (block.ctl == objectMgr.userMgr.socketContentFriend ||
          block.ctl == objectMgr.userMgr.socketContentRequest) {
        userMgr.doUserChange(block);
        return;
      }

      //通话记录更新
      if (block.ctl == callMgr.socketCallLog) {
        callMgr.doCallChange(block);
      }

      // 通话的通知设置更新
      if (block.ctl == callMgr.socketCallNotification) {
        callMgr.doCallNotificationChange(block);
        objectMgr.loginMgr.event(
          objectMgr.loginMgr,
          LoginMgr.eventLinkDevice,
          data: true,
        );
      }

      if (block.ctl == DBChat.tableName) {
        chatMgr.doChatChange(block);
        return;
      }

      if (block.ctl == DBGroup.tableName) {
        myGroupMgr.doGroupChange(block);
        return;
      }

      if (block.ctl == 'notification') {
        final content = block.data[0]['contents'];
        final payload = {
          'typ': 4,
          'notification_type': 4,
          'transaction_id': content['transaction_id'],
        };
        if (!Get.currentRoute.contains('wallet')) {
          objectMgr.pushMgr.showNotification(
            4,
            title: block.data[0]['title'],
            body: block.data[0]['message'],
            payLoad: jsonEncode(payload),
          );
        }
      }

      /// 朋友在线通知
      if (block.ctl == objectMgr.userMgr.socketFriendOnline) {
        final uid = block.data[0]['uid'];
        final lastOnline = block.data[0]['last_online'];

        Map<int, bool> list;
        if (objectMgr.userMgr.friendOnline.isEmpty) {
          list = {uid: FormatTime.isOnline(lastOnline)};
        } else {
          list = objectMgr.userMgr.friendOnline.map((key, value) {
            if (key == uid) {
              return MapEntry(key, FormatTime.isOnline(lastOnline));
            } else {
              return MapEntry(key, value);
            }
          });
        }
        objectMgr.userMgr.friendOnline.value = list;

        User? user = objectMgr.userMgr.getUserById(uid);
        user?.lastOnline = lastOnline;
        if (user != null) {
          objectMgr.chatMgr.event(
              objectMgr.chatMgr, ChatMgr.eventLastSeenStatus,
              data: [user]);
        }
      }

      if (block.ctl == objectMgr.userMgr.socketFriendSecret) {
        objectMgr.userMgr.event(objectMgr.userMgr, UserMgr.eventFriendSecret,
            data: block.data);
      }

      if (block.ctl == 'custom') {
        final CustomData data = CustomData.fromJson(block.data[0]);
        if (data.message['key'] == StoreData.messageSoundData.key) {
          objectMgr.userMgr
              .event(objectMgr.userMgr, UserMgr.eventMessageSound, data: data);
        }
      }
    }
  }

  //判断账号是否是封禁状态
  bool _isForceLogout = false;

  bool get isForceLogout => _isForceLogout;

  set isForceLogout(bool value) {
    _isForceLogout = value;
    event(this, eventForceLogoutChange);
  }

  //封禁弹框
  forceShowToast(var res) {
    BotToast.cleanAll();
    ForceLogout forceLogout = ForceLogout();
    forceLogout.applyJson(res);
    Routes.showNavigatorCall(
      groupKey: 'forceLogout',
      container: CustomSingleButton(
        title: localized(banTitle),
        subText: forceLogout.banAccountTime == -1
            ? '${localized(banBanForever1)}${forceLogout.reason}${localized(banBanForever2)}'
            : '${localized(banBanWarning1)}${forceLogout.reason}${localized(banBanWarning2)}\n${localized(banBanWarning3)}\n${localized(banBanTime)}${FormatTime.getChinaDayTime(forceLogout.banAccountTime) + FormatTime.getAllTime(forceLogout.banAccountTime)}',
        titleFonSize: 16.sp,
        titleColor: color1A1A1A,
        sure: localized(popupConfirm),
        sureFonSize: 16.sp,
        sureColor: colorFFFFFF,
        windowWidth: 263.w,
        onSure: () {
          BotToast.removeAll('forceLogout');
          isForceLogout = false;
          objectMgr.loginMgr.isShowLogin = true;
        },
      ),
    );
  }

  AppLifecycleState? appLifecycleState = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    mypdebug(
        "++++++++++++++++++WidgetsBindingObserver.didChangeAppLifecycleState: state_" +
            state.name);
    appLifecycleState = state;
    _doChangeAppLiftState();
    super.didChangeAppLifecycleState(state);
  }

  //app前后台状态切换
  void _doChangeAppLiftState() {
    var state = appLifecycleState;
    mypdebug(
        "++++++++++++++++++WidgetsBindingObserver._doChangeAppLiftState: state_" +
            (state != null ? state.name : ""));

    socketMgr.didChangeAppLifecycleState(state!);
    callMgr.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      navigatorMgr.closeAllScreen();
      //判断一下是否是从杀掉时打开app的
      if (notBlank(Get.currentRoute)) {
        chatMgr.handleShareData();
        //onAppDataReload();
      }

      heartbeat(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
    event(this, ObjectMgr.eventAppLifeState, data: state);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    event(this, ObjectMgr.eventAppLifeMetrics);
  }

  offEventListeners() {
    Request.event.off(Request.eventNotLogin);
    socketMgr.off(SocketMgr.updateBlock, _onUpdateBlock);
    socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
    socketMgr.off(SocketMgr.eventSocketClose, _onSocketClose);
  }

  Future<void> logout({bool tologin = true}) async {
    mypdebug('===========================ObjectMgr.logout=================');
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      showWarningToast(localized(connectionFailedPleaseCheckTheNetwork),
          bottomMargin: 88.w);
    } else {
      socketMgr.logout();
      try {
        final bool logoutSuccessful = await userLogout();
        if (logoutSuccessful) {
          logoutClearData(tologin);
        } else {
          Toast.showToast(localized(errorLogOutTryAgain));
        }
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
      }
      mypdebug('++++++++logout');
    }
  }

  void logoutClearData(bool toLogin) {
    offEventListeners();
    Request.flag1 = 1;
    callMgr.logout();
    myGroupMgr.logout();
    offlineRequestMgr.logout();
    stickerMgr.logout();
    sharedRemoteDB.clear();
    sysOprateMgr.logout();
    scheduleMgr.logout();
    pushMgr.logout();
    shareMgr.logout();
    userMgr.logout();
    VolumePlayerService.sharedInstance.resetState();

    chatMgr.logout();
    loginMgr.logout();

    if (toLogin) {
      Get.offNamedUntil(
          objectMgr.loginMgr.isDesktop
              ? RouteName.desktopBoarding
              : RouteName.boarding,
          (route) => false);
      event(this, eventToLogin);
    }

    if (objectMgr.loginMgr.isDesktop) {
      objectMgr.init();
    }
  }

  //////////////////////检查更新////////////////////////
  static const String eventNewVersion = "eventNewVersion"; // 是否有新版本
  static const String eventApkDownloading = "eventApkDownloading"; // 是否有新版本
  static const String eventApkDownProgress = "eventApkDownProgress"; // 新版本下载进度
  static const String eventLowMinVersion = "eventLowMinVersion"; // 是否低于最低版本

  bool _hasNewVersion = false;

  // 是否有新版本
  bool get hasNewVersion => _hasNewVersion;

  set hasNewVersion(bool v) {
    _hasNewVersion = v;
    event(this, eventNewVersion);
  }

  bool _lowMinVersion = false;

  // 是否有新版本
  bool get lowMinVersion => _lowMinVersion;

  set lowMinVersion(bool v) {
    _lowMinVersion = v;
    event(this, eventLowMinVersion);
  }

  int _newVersionDownProgress = 0;

  int get newVersionDownProgress => _newVersionDownProgress;

  set newVersionDownProgress(int v) {
    _newVersionDownProgress = v;
    event(this, eventApkDownProgress);
  }

// 校验版本是否有更新
// Future<bool> checkAppVersion(Map<String, dynamic> launchJson) async {
//   var isTestFlight = remoteNotifiMgr.isTestFlight;
//   bool isOlder = false;
//   isOlder = await FlutterAppUpdate.checkAppVersion(
//       value: launchJson, iosAppid: Conf.iosAppid, testFlight: isTestFlight);
//   hasNewVersion = isOlder;
//   return _hasNewVersion;
// }

  Future<void> checkAppVersion(HeartBeatAppVersion data) async {
    if (!Config().enableVersionUpdate) return;

    String currentVersion = await PlatformUtils.getAppVersion();
    String version = data.version;
    String minVersion = data.minVersion;
    String uninstallVersion = data.uninstallVersion;
    String localLatestVersion =
        objectMgr.localStorageMgr.read(LocalStorageMgr.LATEST_APP_VERSION) ??
            '0.0.0';

    // String currentVersion = "1.0.0";
    // String version = "1.0.1";
    // String minVersion = "1.0.1";
    // String uninstallVersion = "1.0.0";
    // String localLatestVersion = "1.0.0";

    final comparisonVersion = currentVersion.compareVersion(version);
    final comparisonMin = currentVersion.compareVersion(minVersion);
    final comparisonUninstall = currentVersion.compareVersion(uninstallVersion);
    final comparisonLocalVersion = localLatestVersion.compareVersion(version);

    /// 此判断作用：
    /// 1.用户可能关闭了 1.1.1 软更新通知
    /// 2.当版本更新至 1.1.2，软更新通知通知无法通知用户
    /// 3.所以由此判断，再次通知用户更新的版本更新
    if (comparisonLocalVersion < 0) {
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.APP_UPDATE_NOTIFICATION, true);
      event(this, eventCloseAppSoftUpdate, data: false);
    }

    /// comparison < 0 : currentVersion is less than version
    /// comparison > 0 : currentVersion is greater than version
    /// comparison == 0 : currentVersion is same as version

    bool uninstallStatus = (comparisonUninstall < 0) ? true : false;

    /// 延迟两秒，等待homeController完成初始化
    if (comparisonMin < 0) {
      Future.delayed(const Duration(seconds: 2), () {
        event(this, eventAppUpdate,
            data: EventAppVersion(
              updateType: AppVersionUpdateType.minVersion.value,
              isShowUninstall: uninstallStatus,
              isShow: true,
            ));
      });
    } else if (comparisonVersion < 0) {
      Future.delayed(const Duration(seconds: 2), () {
        event(this, eventAppUpdate,
            data: EventAppVersion(
              updateType: AppVersionUpdateType.version.value,
              isShowUninstall: uninstallStatus,
              isShow: true,
            ));
      });
    } else if (comparisonVersion == 0 || comparisonVersion > 0) {
      /// revert version condition
      Future.delayed(const Duration(seconds: 2), () {
        event(this, eventAppUpdate,
            data: EventAppVersion(
              isShow: false,
            ));
      });
    }

    /// save to local storage
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.MIN_APP_VERSION, minVersion);
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.LATEST_APP_VERSION, version);
  }

  void getDeveloperMode() {
    bool? status =
        objectMgr.localStorageMgr.read(LocalStorageMgr.DEVELOPER_MODE);
    if (status == true && Config().isDebug) {
      showConsole();
      messageManager.changeLog(true);
    } else {
      messageManager.changeLog(false);
    }
  }

  void initCompleted() {
    final MethodChannel methodChannel =
        const MethodChannel('desktopUtilsChannel');
    methodChannel.invokeMethod('initCompleted');
  }

  void clearData() async {
    try {
      final User user = await objectMgr.userMgr.mainUser;
      mypdebug('===========================ObjectMgr.logout=================');
      // 监听登录状态
      offEventListeners();

      Request.flag1 = 1;
      callMgr.logout();
      socketMgr.logout();
      myGroupMgr.logout();
      offlineRequestMgr.logout();
      stickerMgr.logout();
      sharedRemoteDB.clear();
      sysOprateMgr.logout();
      scheduleMgr.logout();
      pushMgr.logout();
      chatMgr.logout();

      VolumePlayerService.sharedInstance.resetState();

      sharedRemoteDB.removeDB(objectMgr.userMgr.mainUser.uid);

      loginMgr.logout();
      localStorageMgr.cleanAll();

      Get.offNamedUntil(RouteName.desktopBoarding, (route) => false);
      objectMgr.init();
      var databasesPath = "";
      if (Platform.isMacOS) {
        final path = await getApplicationSupportDirectory();
        databasesPath = path.path.toString();
      }
      var dbName = "data_v014_" + user.id.toString() + '.db';
      var dbPath = join(databasesPath, dbName);
      File(dbPath).deleteSync();
      final document = await getApplicationDocumentsDirectory();
      File("${document.path.toString()}/download").deleteSync(recursive: true);
    } on AppException {
      // Toast.showToast('Error log out: $e');
      pdebug("ClearData failed: ${localized(noNetworkPleaseTryAgainLater)}");
    }
  }
}

enum AppInitState { idle, no_connect, kiwi_failed, connecting, fetching, done }

extension AppInitStateName on AppInitState {
  String get toName {
    switch (this) {
      case AppInitState.no_connect:
        return localized(homeTitleNotConnected);

      /// 聊天（未连接）
      case AppInitState.connecting:
        return localized(chatConnecting);

      /// 连接中...
      case AppInitState.fetching:
        return localized(chatReceiving);

      /// 收取中...
      default:
        return localized(homeChat);

      /// 聊天
    }
  }
}
