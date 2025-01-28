import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agora/agora_plugin.dart';
import 'package:cbb_video_player/cbb_video_event_dispatcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/object/wallet/transaction_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:vibration/vibration.dart';

import 'package:jxim_client/api/message_push.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/setting/Notification/notification_controller.dart';
import 'package:jxim_client/views/agora/call_float.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:jxim_client/views/wallet/transaction_details_view.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

class PushManager with WidgetsBindingObserver {
  static const _channelName = 'jxim/notification';
  static var _methodChannel = const MethodChannel(_channelName);
  static const callVibration = [
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000
  ];

  final PushNotificationServices pushServices = PushNotificationServices();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AppLifecycleState state = AppLifecycleState.resumed;

  final StreamController<String?> didReceiveLocalNotificationStream =
      StreamController<String?>.broadcast();

  Map pushDeviceInfo = {};

  final privateChatMute = true.obs;
  final groupChatMute = true.obs;
  final walletMute = true.obs;
  final friendMute = true.obs;

  final privateChatPreviewNotification = false.obs;
  final groupChatPreviewNotification = false.obs;
  final walletPreviewNotification = false.obs;
  final friendPreviewNotification = false.obs;

  NotificationMode privateChatNotificationType = NotificationMode.soundVibrate;
  NotificationMode groupChatNotificationType = NotificationMode.soundVibrate;
  NotificationMode walletNotificationType = NotificationMode.soundVibrate;
  NotificationMode friendNotificationType = NotificationMode.soundVibrate;

  String callNotificationId = '';

  Map? initMessage;
  bool isAppInForeground = false;
  bool isOnlyVibrate = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    this.state = state;

    if (state == AppLifecycleState.resumed) {
      cancelAllNotification();
    }
  }

  @pragma('vm:entry-point')
  void init() {
    objectMgr.chatMgr.on(ChatMgr.eventUnreadTotalCount, _updateBadgeNumber);

    initGlobalNotificationSetting();
    WidgetsBinding.instance.addObserver(this);
  }

  @pragma('vm:entry-point')
  void initChannel() {
    _methodChannel.setMethodCallHandler(handleNativeCallback);
  }

  Future<void> setup() async {
    onClickLocalNotification();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('drawable/splash_logo');

    const DarwinInitializationSettings iosInitializationSetting =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSetting,
      macOS: iosInitializationSetting,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            didReceiveLocalNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            break;
        }
      },
    );
  }

  Future<void> initGlobalNotificationSetting() async {
    final SettingServices _settingServices = SettingServices();

    final data = await _settingServices.getNotificationSetting();

    privateChatMute.value = data.privateChatMute;
    groupChatMute.value = data.groupChatMute;
    walletMute.value = data.walletMute;
    friendMute.value = data.friendMute;

    privateChatPreviewNotification.value = data.privateChatPreviewNotification;
    groupChatPreviewNotification.value = data.groupChatPreviewNotification;
    walletPreviewNotification.value = data.walletPreviewNotification;
    friendPreviewNotification.value = data.friendPreviewNotification;

    privateChatNotificationType = data.privateChatNotificationType;
    groupChatNotificationType = data.groupChatNotificationType;
    walletNotificationType = data.walletNotificationType;
    friendNotificationType = data.friendNotificationType;
  }

  Future<void> handleNativeCallback(MethodCall call) async {
    if (call.method == 'registerJPush') {
      final data = await call.arguments;
      pushDeviceInfo = data;
    } else if (call.method == 'notificationRouting') {
      //后台点击触发

      final data = await call.arguments;
      notificationRouting(data);
      //判断是否有通话
    } else if (call.method == 'initMessage') {
      // 初始化点击的触发
      final data = await call.arguments;
      initMessage = data;
    }
  }

  //点击通知后如果正在童话页面，就先跳到对应的页面后最小化通话页面
  void ifMinimizedCallView() {
    if (Get.isRegistered<AgoraCallController>() &&
        !objectMgr.callMgr.isMinimized.value) {
      if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
        CallFloat().onMinimizeWindow();
      } else {
        CallFloat().closeAllFloat();
      }
    }
  }

  Future<void> notificationRouting(Map data) async {
    switch (data['notification_type']) {
      case 1:
        final chatList = await objectMgr.chatMgr.loadAllLocalChats();
        final Chat? chat = chatList
            .firstWhereOrNull((element) => element.chat_id == data['chat_id']);

        if (chat != null) {
          objectMgr.chatMgr.loadMessageFromChat(chat);
          if (!Get.currentRoute.contains("${chat.chat_id}")) {
            try {
              Get.until((route) =>
                  Get.currentRoute == RouteName.home ||
                  Get.currentRoute.contains("${chat.chat_id}"));
              Routes.toChat(chat: chat, fromNotification: true);
              Get.find<HomeController>().onPageChange(0);
              ifMinimizedCallView();
            } catch (e) {
              pdebug('Get the Chat and rounting error $e');
            }
          }
        }

        await Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isRegistered<ChatListController>()) {
            Get.find<ChatListController>().clearSearching();
          }
        });
        break;
      case 2:
        if (Get.currentRoute != RouteName.friendRequestView) {
          if (Get.isRegistered<QRCodeScannerController>()) {
            Get.find<QRCodeScannerController>().isBackToScanner = false;
            Get.find<QRCodeScannerController>().mobileScannerController = null;
          }
          Get.until((route) => Get.currentRoute == RouteName.home);
          Get.toNamed(RouteName.friendRequestView);
          Get.find<HomeController>().onPageChange(2);
          ifMinimizedCallView();
        }
        break;
      case 4:
        final WalletServices walletServices = WalletServices();
        final transactionID = data['transaction_id'];
        final TransactionModel transaction = await walletServices
            .getTransactionDetail(transactionID: transactionID);

        Get.until((route) => Get.currentRoute == RouteName.home);
        Get.toNamed(RouteName.walletView);
        Future.delayed(const Duration(milliseconds: 300), () {
          // Get.toNamed(RouteName.transactionHistoryView);
          sharedDataManager
              .gotoWalletHistoryPage(Routes.navigatorKey.currentContext!);
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          Get.to(() => TransactionDetailsView(
                transaction: transaction,
                isAfterWithdraw: false,
              ));
        });

        Get.find<HomeController>().onPageChange(3);
        ifMinimizedCallView();
        break;
      case 5:
        // Get.until((route) => Get.currentRoute == RouteName.home);
        // Get.find<HomeController>().onPageChange(1);
        break;
      case 6:
        // Get.until((route) => Get.currentRoute == RouteName.home);
        // Get.find<HomeController>().onPageChange(1);
        break;
    }

    initMessage = null;
  }

  // static const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'call_channel', 'call Channel',
  //     importance: Importance.high,
  //     sound: RawResourceAndroidNotificationSound('call'),
  //     playSound: true);

  reset() async {
    if (pushDeviceInfo['registrationId'] != "" &&
        pushDeviceInfo['registrationId'] != null) {
      if (objectMgr.loginMgr.isMobile && !objectMgr.loginMgr.isLogin) {
        pdebug('Unregister Push Notification Services');
        pushServices.unRegisterPushDevice(
            registrationId: pushDeviceInfo['registrationId'].toString(),
            voip_device_token: pushDeviceInfo['voipToken'] ?? "");
        flutterLocalNotificationsPlugin.cancelAll();
      }
    }
  }

  void onClickLocalNotification() {
    didReceiveLocalNotificationStream.stream.listen((String? payload) async {
      if (payload != null) {
        stopVibrate();
        final data = jsonDecode(payload);

        //判斷有無在群組
        if (agoraHelper.isInGroupChatView) {
          //標記為切換聊天室
          agoraHelper.isSwitchChatRoom = true;
        }
        //檢查當前有無開啟語音群聊
        if (agoraHelper.isJoinAudioRoom) {
          if (data['typ'] == 1) {
            final Chat chat = Chat()..init(data['chat']);
            if (chat.chat_id == audioManager.currentChatroomInfo?.groupId) {
              //如果這個聊天室跟當前加入群聊的聊天室相同就不做動作
              return;
            }
          }
          agoraHelper.gameManagerGetCheckCloseDialog(
              Routes.navigatorKey.currentState?.context, action: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            goToPage(data);
          });
        } else {
          goToPage(data);
        }
      }
    });
  }

  void goToPage(data) async {
    switch (data['typ']) {
      case 1:
        final Chat chat = Chat()..init(data['chat']);
        if (objectMgr.loginMgr.isDesktop) {
          Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
          Routes.toChatDesktop(chat: chat);
        } else {
          if (!Get.currentRoute.contains("${chat.chat_id}")) {
            Get.until((route) =>
                Get.currentRoute == RouteName.home ||
                Get.currentRoute.contains("${chat.chat_id}"));
            Routes.toChat(chat: chat);
          }

          await Future.delayed(const Duration(milliseconds: 100), () {
            if (Get.isRegistered<ChatListController>()) {
              Get.find<ChatListController>().clearSearching();
            }
          });
        }
        break;
      case 2:
        if (objectMgr.loginMgr.isDesktop) {
          return;
        }
        if (Get.currentRoute != RouteName.friendRequestView) {
          Get.until((route) => Get.currentRoute == RouteName.home);
          Get.toNamed(RouteName.friendRequestView);
          Get.find<HomeController>().onPageChange(2);
        }
        break;
      case 4:
        if (objectMgr.loginMgr.isDesktop) {
          return;
        }
        final WalletServices walletServices = WalletServices();
        final transactionID = data['transaction_id'];
        final TransactionModel transaction = await walletServices
            .getTransactionDetail(transactionID: transactionID);
        Get.until((route) => Get.currentRoute == RouteName.home);
        Get.toNamed(RouteName.walletView);
        Future.delayed(const Duration(milliseconds: 300), () {
          // Get.toNamed(RouteName.transactionHistoryView);
          sharedDataManager
              .gotoWalletHistoryPage(Routes.navigatorKey.currentContext!);
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          Get.to(() => TransactionDetailsView(
                transaction: transaction,
                isAfterWithdraw: false,
              ));
        });

        Get.find<HomeController>().onPageChange(3);
        break;
      case 5:
        if (objectMgr.loginMgr.isDesktop) {
          return;
        }
        if (callNotificationId == data['id']) {
          cancelLocalNotification();
        }
        break;
      case 6:
        Get.until((route) => Get.currentRoute == RouteName.home);
        Get.find<HomeController>().onPageChange(1);
        break;
    }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
          'IN_DEFAULT_NOTIFICATION',
          'In Default Notification',
          importance: Importance.max,
        ),
        iOS: DarwinNotificationDetails());
  }

  NotificationDetails getNotificationDetails(
      NotificationMode notificationMode) {
    switch (notificationMode) {
      case NotificationMode.soundVibrate:
        return const NotificationDetails(
            android: AndroidNotificationDetails(
              'DEFAULT_NOTIFICATION',
              'Default Notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails());
      case NotificationMode.sound:
        return const NotificationDetails(
            android: AndroidNotificationDetails(
              'SOUND_NOTIFICATION',
              'Sound Notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails());
      case NotificationMode.vibrate:
        return const NotificationDetails(
            android: AndroidNotificationDetails(
              'VIBRATE_NOTIFICATION',
              'In Sound Notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails(sound: 'empty.mp3'));
      case NotificationMode.silent:
        return const NotificationDetails(
            android: AndroidNotificationDetails(
              'SILENCE_NOTIFICATION',
              'In Sound Notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails(
              presentSound: false,
            ));

      default:
        return const NotificationDetails(
            android: AndroidNotificationDetails(
              'IN_DEFAULT_NOTIFICATION',
              'In Default Notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails());
    }
  }

  callNotificationDetails(String chatId, String chatName) {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            "IN_DEFAULT_CALL", "In Default Call",
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            sound: const RawResourceAndroidNotificationSound('call'),
            vibrationPattern: Int64List.fromList(callVibration)),
        iOS: const DarwinNotificationDetails(
            sound: 'call.caf', presentBanner: false));
  }

  Future showNotification(int notificationType,
      {int id = 0,
        String title = '',
        String? body,
        String? payLoad,
        bool isCallMessage = false}) async {
    ///暂时移除 macOs 的推送

    if(title == "") {
      title = Config().appName;
    }

    if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        return;
      }
    } else if (Platform.isIOS) {
      if (!(await getAppState())) {
        return;
      }
    }

    bool isNotMute = true;
    NotificationMode currentMode = NotificationMode.soundVibrate;
    // call notification will ignore mute settings
    if (!isCallMessage) {
      switch (notificationType) {
        case 1:
          isNotMute = privateChatMute.value;
          if (!privateChatPreviewNotification.value) {
            body = localized(chatPreview);
          }
          currentMode = privateChatNotificationType;
          break;
        case 2:
          isNotMute = groupChatMute.value;
          if (!groupChatPreviewNotification.value) {
            body = localized(chatPreview);
          }
          currentMode = groupChatNotificationType;
          break;
        case 3:
          isNotMute = friendMute.value;
          if (!friendPreviewNotification.value) {
            body = localized(friendPreview);
          }
          currentMode = friendNotificationType;

          break;
        case 4:
          isNotMute = walletMute.value;
          if (!walletPreviewNotification.value) {
            body = localized(walletPreview);
          }
          currentMode = walletNotificationType;
          break;
        case 999:
          isNotMute = true;
          break;
        default:
          break;
      }
    }
    if (isOnlyVibrate) {
      currentMode = NotificationMode.vibrate;
    }

    if (isNotMute) {
      flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        getNotificationDetails(currentMode),
        payload: payLoad,
      );
    }
  }

  showIncomingCallNotification(Chat chat, String rtcChannelId) async {
    if (!(await getAppState())) {
      return;
    }
    pdebug('InApp notification is call');
    String name = '';
    isOnlyVibrate = true;
    if (chat.isGroup) {
      name = chat.name;
    } else {
      User? user = objectMgr.userMgr.getUserById(chat.friend_id);
      name = objectMgr.userMgr.getUserTitle(user);
      if (name.isEmpty) {
        name = chat.name;
      }
    }

    CBBVideoEvents.instance.onMute();
    callNotificationId = chat.id.toString();
    flutterLocalNotificationsPlugin.show(
      chat.id,
      name,
      localized(incomingCall),
      callNotificationDetails(chat.id.toString(), name),
      payload: jsonEncode({
        "id": chat.id.toString(),
        "chat": chat,
        "rtcChannelId": rtcChannelId,
        "typ": 5,
      }),
    );
  }

  void updateMute(int? type, bool result) {
    switch (type) {
      case 1:
        privateChatMute.value = result;
        break;
      case 2:
        groupChatMute.value = result;
        break;
      case 3:
        friendMute.value = result;
        break;
      case 4:
        walletMute.value = result;
        break;
      default:
        break;
    }
  }

  void updatePreview(int? type, bool result) {
    switch (type) {
      case 1:
        privateChatPreviewNotification.value = result;
        break;
      case 2:
        groupChatPreviewNotification.value = result;
        break;
      case 3:
        friendPreviewNotification.value = result;
        break;
      case 4:
        walletPreviewNotification.value = result;
        break;
      default:
        break;
    }
  }

  void updateMode(int type, NotificationMode result) {
    switch (type) {
      case 1:
        privateChatNotificationType = result;
        break;
      case 2:
        groupChatNotificationType = result;
        break;
      case 3:
        walletNotificationType = result;
        break;
      case 4:
        friendNotificationType = result;
        break;
      default:
        break;
    }
  }

  Future<void> bindingDeviceWithAccount() async {
    if (objectMgr.loginMgr.isMobile) {
      if (pushDeviceInfo['registrationId'] == "" ||
          pushDeviceInfo['registrationId'] == null) {
        final data = objectMgr.localStorageMgr.read(LocalStorageMgr.PUSH_INFO);
        if (data != null) {
          pushDeviceInfo = jsonDecode(data);
        }
      }
      if (pushDeviceInfo.isEmpty) {
        return;
      }

      if (pushDeviceInfo.containsKey('platform') &&
          pushDeviceInfo['platform'] == "2") {
        pushServices.enablePushKit();
      }
      pdebug("Push Info : $pushDeviceInfo");
      pushServices.registerPushDevice(
        registrationId: pushDeviceInfo['registrationId'].toString(),
        voip_device_token: pushDeviceInfo['voipToken'] ?? "",
        platform: int.parse(pushDeviceInfo['platform'] ?? ""),
        source: int.parse(pushDeviceInfo['source']),
      );
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.PUSH_INFO, jsonEncode(pushDeviceInfo));
    }

    // 鉴于此功能很好用到，又没有查出什么原因，目前暂时先注释掉，之后在打开
    // objectMgr.callMgr.checkIsEnableVoip();
  }

  void stopVibrate() async {
    if (!objectMgr.loginMgr.isDesktop) {
      Vibration.cancel();
      _methodChannel.invokeMethod('stopVibrate');
    }
  }

  void stopCall() async {
    _methodChannel.invokeMethod('stopCall');
  }

  static void cancelVibrate() async {
    if (!objectMgr.loginMgr.isDesktop) {
      Vibration.cancel();
    }
  }

  static void isOpen() async {
    await _methodChannel.invokeMethod('isOpen', {'isOpen': "true"});
  }

  Future<bool> getAppState() async {
    final data = await _methodChannel.invokeMethod('getAppState');
    return data;
  }

  Future<String> getIOSLaunchMode() async {
    final mode = await _methodChannel.invokeMethod('getLaunchType');
    return mode;
  }

  bool getChatMuteStatus(bool isSingle) {
    if (isSingle) {
      return privateChatMute.value;
    } else {
      return groupChatMute.value;
    }
  }

  _updateBadgeNumber(Object sender, Object type, Object? block) {
    if (objectMgr.loginMgr.isDesktop) {
      updateBadge(objectMgr.chatMgr.totalUnreadCount.value);
    }
  }

  void updateBadge(int unreadCount) {
    final MethodChannel methodChannel =
        const MethodChannel('desktopNotification');
    methodChannel.invokeMethod(
      'updateBadge',
      {'badgeNumber': unreadCount},
    );
  }

  // Workable in Android only
  void clearNotification() async =>
      await _methodChannel.invokeMethod("clearNotification");

  void cancelLocalNotification() async {
    if (callNotificationId != '') {
      flutterLocalNotificationsPlugin.cancel(int.parse(callNotificationId));
    }
  }

  void logout() {
    if (objectMgr.loginMgr.isMobile) {
      if (pushDeviceInfo['registrationId'] != null &&
          pushDeviceInfo['registrationId'] != "") {
        pushServices.unRegisterPushDevice(
          registrationId: pushDeviceInfo['registrationId'].toString(),
          voip_device_token: pushDeviceInfo['voipToken'] ?? "",
        );
      }

      flutterLocalNotificationsPlugin.cancelAll();
    } else {
      updateBadge(0);
      objectMgr.chatMgr.off(ChatMgr.eventUnreadTotalCount, _updateBadgeNumber);
    }
  }

  void cancelAllNotification() {
    flutterLocalNotificationsPlugin.cancelAll();
  }
}
