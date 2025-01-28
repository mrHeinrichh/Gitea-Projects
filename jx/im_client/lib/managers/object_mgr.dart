import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_chat_category.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/call_log_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/db_mgr.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/favourite_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/keyboard_height_mgr.dart';
import 'package:jxim_client/managers/kiwi_manage.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/login_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/mini_app_mgr.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/navigator_mgr.dart';
import 'package:jxim_client/managers/network_mgr.dart';
import 'package:jxim_client/managers/offline_request_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/managers/open_install_mgr.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/managers/schedule_mgr.dart';
import 'package:jxim_client/managers/share_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/sound_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/managers/sys_oprate_mgr.dart';
import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/managers/tencent_video_mgr.dart';
import 'package:jxim_client/managers/user_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/local_http_server.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/force_logout.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/reel/reel_page/reel_cache_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/special_container/special_container_overlay.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/floating/manager/floating_manager.dart';
import 'package:jxim_client/views/message/chat/custom_single_button.dart';

// 对象管理器，全局对象根
final objectMgr = ObjectMgr();

class ObjectMgr extends BaseMgr with WidgetsBindingObserver {
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

  // 在线管理器
  final OnlineMgr onlineMgr = OnlineMgr();


  //小程序
  final MiniAppMgr miniAppMgr = MiniAppMgr();

  final UserMgr userMgr = UserMgr();

  // 通话
  final CallMgr callMgr = CallMgr();

  // 通话记录
  final CallLogMgr callLogMgr = CallLogMgr();

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

  // 声音管理器
  final SoundMgr soundMgr = SoundMgr();

  // 贴纸管理器
  final StickerMgr stickerMgr = StickerMgr();

  final PushManager pushMgr = PushManager();

  /// 悬浮窗管理器初始化
  final FloatingManager floatingManager = FloatingManager();

  MessageMgr messageManager = MessageMgr();

  final ShareMgr shareMgr = ShareMgr();

  final MgrTask taskMgr = MgrTask();

  final LogMgr logMgr = LogMgr();

  // 键盘高度管理
  final keyBoardHeightManager = KeyboardHeightManager();

  // 朋友圈管理器
  final MomentMgr momentMgr = MomentMgr();

  final TagsMgr tagsMgr = TagsMgr();

// 收藏管理器
  final FavouriteMgr favouriteMgr = FavouriteMgr();

  //视频号管理器
  final ReelCacheMgr reelCacheMgr = ReelCacheMgr();

  //新视频播放器管理
  final TencentVideoMgr tencentVideoMgr = TencentVideoMgr();

  final RetryMgr retryMgr = RetryMgr();

  final EncryptionMgr encryptionMgr = EncryptionMgr();

  final appInitState = AppInitState.connecting.obs;

  RequestFunctionMap? requestFunctionMap;

  ObjectMgr() {
    Permissions.appName = Config().appName;
    PlatformUtils.appName = Config().appName;

    WidgetsBinding.instance.addObserver(this);
  }

  // 初始化
  Future<void> init() async {
    objectMgr.logMgr.init();
    downloadMgrV2.init();
    connectivityMgr.initConnectivityMgr();
    offEventListeners();
    CustomRequest.event.on(CustomRequest.eventNotLogin, _onEventNotLogin);
    socketMgr.off(SocketMgr.updateBlock);
    socketMgr.on(SocketMgr.updateBlock, _onUpdateBlock);
    socketMgr.on(SocketMgr.eventSocketClose, _onSocketClose);
    objectMgr.once(ObjectMgr.eventKiwiConnect, _onKiwiConnect);

    if (Config().cleanLocalStorage) {
      localStorageMgr.cleanAll();
    }

    await chatMgr.registerOnce();

    onlineMgr.register();
    userMgr.registerOnce();
    callMgr.registerOnce();
    myGroupMgr.register();
    sysOprateMgr.register();
    tagsMgr.registerOnce();
    retryMgr.registerOnce();
    messageManager.registerConsumeMsgFunc(chatMgr.processRemoteMessage);
    messageManager.registerOnLoadStatusChangeFunc(
      chatMgr.loadMessageStatusChange,
    );

    requestFunctionMap ??= RequestFunctionMap();
  }

  prepareDBData(User user) async {
    //启动的时候，就初始化kiwi
    kiwiMgr.initKiwi();
    await _localDB.init(user.id, Config().cleanSqflite);
    await Future.wait([chatMgr.initialize(), userMgr.initialize()]);
    scheduleMgr.init();
    callLogMgr.initialize();
    requestQueue.restoreQueue();
  }

  // 初始化主用户2
  Future<void> initMainUser(User user) async {
    Toast.hide();
    CustomRequest.token = loginMgr.account!.token;

    localStorageMgr.initUser(user.id);
    encryptionMgr.initialize();

    offlineRequestMgr.initialize();

    userMgr.onUserChanged([user], notify: true);
    chatMgr.openChatDraft();

    taskMgr.initialize();
    //初始化我的群列表
    myGroupMgr.init();

    shareMgr.initialize();

    //重置弹窗
    userMgr.hasPopDialog = false;

    momentMgr.initialize();
    tencentVideoMgr.initialize();
    tagsMgr.initialize();
    favouriteMgr.initialize();
    soundMgr.init();
    retryMgr.initialize();
    updateAudioSettings();
  }

  updateAudioSettings() async {
    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions:
          AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
    ));
  }

  Future<void> initMainUserAfterNetwork() async {
    pushMgr.init();
    // 获取最爱贴纸
    stickerMgr.initialize();
    // 通话
    callMgr.initialize();
    // 获取最新translation
    langMgr.initialize();
    //视频号cache的数据
    // reelCacheMgr.init();

    // 从服务器获取键盘高度
    objectMgr.keyBoardHeightManager.init();
    objectMgr.encryptionMgr.readRemoteEncryptionEnabled();

    await heartbeat(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  void _onEventNotLogin(Object sender, Object type, Object? data) {
    pdebug(
      '===========================_onEventNotLogin.logout=================',
    );
    // Request.flag = Request.flag + 1;
    // logout();
  }

  void _onSocketClose(Object sender, Object type, Object? block) async {}

  void _onKiwiConnect(Object sender, Object type, _) async {
    onNetworkOn();
    if (loginMgr.isLogin) {
      scheduleMgr.heartBeatTask.resetDelayCount(fource: true);
      initMainUserAfterNetwork();
    } else {
      objectMgr.pushMgr.reset();
    }
    // Kiwi链接回调和有实际网络有一定的延迟，有几率导致openinstall连接网络失败
    Future.delayed(
      const Duration(milliseconds: 100),
      () => initPlatformState(),
    );
  }

  Future<void> initPlatformState() async {
    handleFriendLink();
  }

  void handleFriendLink() {
    if (Platform.isAndroid || Platform.isIOS) {
      openInstallMgr.init();

      final isInstalled =
          objectMgr.localStorageMgr.globalRead(LocalStorageMgr.INSTALL_DATE) !=
              null;
      if (!isInstalled) {
        // 首次安装app
        // 从好友链接过来安装app后加好友的逻辑
        openInstallMgr.handleInstallFriendAndGroupLink();
        objectMgr.localStorageMgr.globalWrite(
          LocalStorageMgr.INSTALL_DATE,
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }
      // 已安装app
      // 从好友链接过来唤醒后加好友的逻辑
      openInstallMgr.handleWakeupFriendAndGroupLink();
    }
  }

  Future<AppInitState> onNetworkOff() async {
    if (await networkMgr.checkNetWork()) {
      appInitState.value = AppInitState.no_connect;
    } else {
      appInitState.value = AppInitState.no_network;
    }
    return appInitState.value;
  }

  Future<void> initKiwi() async {
    try {
      if (appInitState.value == AppInitState.no_network) {
        if (await networkMgr.checkNetWork() == true) {
          appInitState.value = AppInitState.connecting;
        }
      }
      kiwiMgr.initKiwi();
    } catch (e) {
      onNetworkOff();
      pdebug("【Dun Failed】: ${e.toString()}");
    }
  }

  Future<void> addCheckKiwiTask() async {
    bool isConnected = await serversUriMgr.checkIsConnected();
    if (!isConnected) {
      scheduleMgr.checkKiwiTask.restart();
    }
  }

  void onKiwiInit() {
    socketMgr.reConnectTime = 0;
    event(this, eventKiwiConnect);
  }

  Future<void> onNetworkOn() async {
    int diffReConnect =
        DateTime.now().millisecondsSinceEpoch - socketMgr.reConnectTime;
    if (diffReConnect >= 2000) {
      socketMgr.reConnectTime = DateTime.now().millisecondsSinceEpoch;
      await onAppDataReload();
    }
  }

  /// app 唤醒&网络连接时的初始化
  onAppDataReload() async {
    if (loginMgr.isLogin &&
        (notBlank(loginMgr.account?.user?.nickname) ||
            notBlank(loginMgr.account?.user?.username))) {
      pdebug("onAppDataReload-socketInit");
      await serversUriMgr.onNetworkOn();
      final isSocketOpen = socketMgr.socket?.open ?? false;
      if (!isSocketOpen || !socketMgr.isConnect) {
        appInitState.value = AppInitState.connecting;
        socketMgr.init(loginMgr.account!.token);
      }

      callLogMgr.recover();
      userMgr.recover();
      chatMgr.recover();
      callMgr.recover();
      offlineRequestMgr.recover();
      momentMgr.recover();
      favouriteMgr.recover();
      if (Get.isRegistered<RedPacketController>()) {
        Get.find<RedPacketController>().initPage();
      }
      if (serversUriMgr.isKiWiConnected) pushMgr.bindingDeviceWithAccount();
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
      if (block.ctl == OnlineMgr.socketFriendOnline) {
        final uid = block.data[0]['uid'];
        final lastOnline = block.data[0]['last_online'];

        if (lastOnline > 0) {
          objectMgr.onlineMgr.updateOnlineTime(uid, lastOnline);
        }

        User? user = objectMgr.userMgr.getUserById(uid);
        user?.lastOnline = lastOnline;
        if (user != null) {
          objectMgr.onlineMgr.event(
            onlineMgr,
            OnlineMgr.eventLastSeenStatus,
            data: [user],
          );
        }
      }

      if (block.ctl == objectMgr.userMgr.socketFriendSecret) {
        objectMgr.userMgr.event(
          objectMgr.userMgr,
          UserMgr.eventFriendSecret,
          data: block.data,
        );
      }

      if (block.ctl == 'custom') {
        final CustomData data = CustomData.fromJson(block.data[0]);
        if (data.message['key'] == StoreData.messageSoundData.key) {
          objectMgr.userMgr
              .event(objectMgr.userMgr, UserMgr.eventMessageSound, data: data);
        }

        if (data.message['key'] == DBChatCategory.tableName) {
          final String categoryValue = data.message['value'] ?? '';
          if (categoryValue.isEmpty) return;

          final decodedValue = jsonDecode(categoryValue);
          if (decodedValue is List<dynamic>) {
            final castedValue = decodedValue
                .map<ChatCategory>((e) => ChatCategory()..init(e))
                .toList();
            chatMgr.replaceChatCategory(
              castedValue,
              updateRemote: false,
            );
          }
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
        titleColor: colorTextPrimary,
        sure: localized(popupConfirm),
        sureFonSize: 16.sp,
        sureColor: colorWhite,
        windowWidth: 263.w,
        onSure: () {
          BotToast.removeAll('forceLogout');
          isForceLogout = false;
          objectMgr.loginMgr.isShowLogin = true;
        },
      ),
    );
  }

  AppLifecycleState? appLifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    pdebug(
      "++++++++++++++++++WidgetsBindingObserver.didChangeAppLifecycleState: $state",
    );
    appLifecycleState = state;
    _doChangeAppLiftState();
  }

  //app前后台状态切换
  void _doChangeAppLiftState() {
    socketMgr.didChangeAppLifecycleState(appLifecycleState!);
    callMgr.didChangeAppLifecycleState(appLifecycleState!);
    scheduleMgr.didChangeAppLifecycleState(appLifecycleState!);
    if (appLifecycleState == AppLifecycleState.resumed) {
      navigatorMgr.closeAllScreen();
      //判断一下是否是从杀掉时打开app的
      if (notBlank(Get.currentRoute)) {
        chatMgr.handleShareData();
        //onAppDataReload();
      }

      heartbeat(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
    event(this, ObjectMgr.eventAppLifeState, data: appLifecycleState);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    event(this, ObjectMgr.eventAppLifeMetrics);
  }

  offEventListeners() {
    CustomRequest.event.off(CustomRequest.eventNotLogin);
    socketMgr.off(SocketMgr.updateBlock, _onUpdateBlock);
    socketMgr.off(SocketMgr.eventSocketClose, _onSocketClose);
  }

  Future<void> logout(
      {bool tologin = true, String? logoutCode, String? token}) async {
    pdebug('===========================ObjectMgr.logout=================');
    objectMgr.miniAppMgr.logout();
    socketMgr.logout();
    try {
      final bool logoutSuccessful = await userLogout(token: token);
      if (logoutSuccessful) {
        if (logoutCode == 'RESET_E2EE') {
          await objectMgr.encryptionMgr.kickLogoutRemoveCache();
        }
      } else {
        pdebug("Logout fail - api not successful");
      }
    } on AppException catch (e) {
      pdebug("Logout error - ${e.getMessage()}");
      rethrow;
    } finally {
      SpecialContainerOverlay.closeOverlay();
      logoutClearData(tologin);
    }
    pdebug('++++++++logout');
  }

  void logoutClearData(bool toLogin) {
    offEventListeners();
    CustomRequest.flag1 = 1;
    callLogMgr.cleanup();
    callMgr.cleanup();
    myGroupMgr.logout();
    offlineRequestMgr.cleanup();
    stickerMgr.cleanup();
    sharedRemoteDB.clear();
    sysOprateMgr.logout();
    scheduleMgr.clear();
    pushMgr.logout();
    shareMgr.cleanup();
    userMgr.cleanup();
    localHttpServer.close();
    momentMgr.cleanup();
    tencentVideoMgr.cleanup();
    VolumePlayerService.sharedInstance.resetState();
    onlineMgr.logout();
    chatMgr.cleanup();
    loginMgr.logout();
    favouriteMgr.cleanup();
    encryptionMgr.cleanup();
    langMgr.cleanup();
    localDB.destroy();
    if (toLogin) {
      Get.offNamedUntil(
        objectMgr.loginMgr.isDesktop
            ? RouteName.desktopBoarding
            : RouteName.boarding,
        (route) => false,
      );
      event(this, eventToLogin);
    }

    clear();
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

  Future<void> checkAppVersion({HeartBeatAppVersion? data}) async {
    if (!Config().enableVersionUpdate) return;
    String currentVersion = await PlatformUtils.getAppVersion();
    HeartBeatAppVersion appVersion = await appVersionUtils.getLocalAppDetail();

    String version = data?.version ?? appVersion.version;
    String minVersion = data?.minVersion ?? appVersion.minVersion;
    String uninstallVersion =
        data?.uninstallVersion ?? appVersion.uninstallVersion;
    String localCurrentVersion =
        objectMgr.localStorageMgr.read(LocalStorageMgr.CURRENT_APP_VERSION) ??
            '0.0.0';
    String hash = data?.hash ?? appVersion.hash;

    // String currentVersion = "1.0.0";
    // String version = "1.0.1";
    // String minVersion = "1.0.1";
    // String uninstallVersion = "1.0.0";
    // String localLatestVersion = "1.0.0";

    appVersionUtils.heartBeatAppVersion = HeartBeatAppVersion(
      version: version,
      minVersion: minVersion,
      uninstallVersion: uninstallVersion,
      hash: hash,
    );

    localStorageMgr.write(
      LocalStorageMgr.APP_VERSION_DETAIL,
      jsonEncode(appVersionUtils.heartBeatAppVersion?.toJson()),
    );

    /// 如果当前版本号不是之前储存的版本号，需要清空CLOSE_APP_VERSION
    if (localCurrentVersion != currentVersion) {
      localStorageMgr.write(
          LocalStorageMgr.CURRENT_APP_VERSION, currentVersion);
      localStorageMgr.write(LocalStorageMgr.CLOSE_APP_VERSION, '');
    }

    final comparisonVersion = currentVersion.compareVersion(version);
    final comparisonMin = currentVersion.compareVersion(minVersion);
    final comparisonUninstall = currentVersion.compareVersion(uninstallVersion);

    /// comparison < 0 : currentVersion is less than version
    /// comparison > 0 : currentVersion is greater than version
    /// comparison == 0 : currentVersion is same as version

    bool uninstallStatus = (comparisonUninstall < 0) ? true : false;

    /// 延迟两秒，等待homeController完成初始化
    await Future.delayed(const Duration(seconds: 2));

    if (comparisonMin < 0) {
      event(
        this,
        eventAppUpdate,
        data: EventAppVersion(
          updateType: AppVersionUpdateType.minVersion,
          isShowUninstall: uninstallStatus,
        ),
      );
    } else if (comparisonVersion < 0) {
      /// 此判断作用：
      /// [情况1]
      /// 1.用户可能关闭了 1.1.1 软更新通知
      /// 2.当版本更新至 1.1.2，软更新通知通知无法通知用户
      /// 3.所以由此判断，再次通知用户更新的版本更新

      /// [情况2]
      /// 1.当前版本为1.1.0，用户关闭了通知
      /// 2.当版本更新至 1.1.2，用户安装了1.1.1的版本
      /// 3.所以由此判断，再次通知用户更新的版本更新

      event(
        this,
        eventAppUpdate,
        data: EventAppVersion(
          updateType: AppVersionUpdateType.version,
          isShowUninstall: uninstallStatus,
        ),
      );
    } else if (comparisonVersion == 0 || comparisonVersion > 0) {
      /// revert version condition
      event(
        this,
        eventAppUpdate,
        data: EventAppVersion(
          updateType: AppVersionUpdateType.revertVersion,
        ),
      );
    }
  }

  void initCompleted() {
    const MethodChannel methodChannel = MethodChannel('desktopUtilsChannel');
    methodChannel.invokeMethod('initCompleted');
  }

  /// 桌面端清空数据
  void clearData() async {
    try {
      pdebug('===========================ObjectMgr.logout=================');
      // 监听登录状态
      offEventListeners();

      CustomRequest.flag1 = 1;
      callMgr.cleanup();
      socketMgr.logout();
      myGroupMgr.logout();
      offlineRequestMgr.cleanup();
      stickerMgr.cleanup();
      sharedRemoteDB.clear();
      sysOprateMgr.logout();
      scheduleMgr.clear();
      pushMgr.logout();
      chatMgr.cleanup();
      momentMgr.cleanup();
      reelCacheMgr.cleanup();
      favouriteMgr.cleanup();
      encryptionMgr.cleanup();
      VolumePlayerService.sharedInstance.resetState();

      callLogMgr.cleanup();
      shareMgr.cleanup();
      userMgr.cleanup();
      localHttpServer.close();
      langMgr.cleanup();
      await localDB.destroy(); // 清除DB内存
      sharedRemoteDB.removeDB(objectMgr.userMgr.mainUser.uid); //清空DB文件

      loginMgr.logout();
      localStorageMgr.cleanAll();
      AppPath.clearAllPath();

      if (objectMgr.loginMgr.isDesktop) {
        desktopDownloadMgr.clear();
        Get.offNamedUntil(
          RouteName.desktopBoarding,
          (route) => false,
        );
      }
      await objectMgr.init(); //重新初始化
    } on AppException {
      // Toast.showToast('Error log out: $e');
      pdebug("ClearData failed: ${localized(noNetworkPleaseTryAgainLater)}");
    } catch (e) {
      pdebug("ClearData failed: ${e.toString()}");
    }
  }

  @override
  Future<void> cleanup() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}

enum AppInitState {
  idle,
  no_network,
  no_connect,
  kiwi_failed,
  connecting,
  fetching,
  done
}

extension AppInitStateName on AppInitState {
  String get toName {
    switch (this) {
      case AppInitState.no_network:
        return localized(homeTitleNotNetwork);

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
        return Config().appName;

      /// 聊天
    }
  }
}
