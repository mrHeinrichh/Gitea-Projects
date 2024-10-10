import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agora/agora_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/api/message_push.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/push_online_notification_content_factory.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart' as message;
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/object/wallet/transaction_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:jxim_client/views/wallet/transaction_details_view.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';

class PushManager with WidgetsBindingObserver {
  static const _channelName = 'jxim/notification';
  static const _methodChannel = MethodChannel(_channelName);
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
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
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
  bool localNotificationClicking = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    this.state = state;

    if (state == AppLifecycleState.resumed) {
      cancelAllNotification();
    } else {
      // app 退到背景時，設定未讀消息數量
      _methodChannel.invokeMethod(
        'updateBadgeNumber',
        objectMgr.chatMgr.totalUnreadCount.value,
      );
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
    final SettingServices settingServices = SettingServices();

    final data = await settingServices.getNotificationSetting();

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
  void ifMinimizedCallView(String sender, Chat? chat) {
    bool inCallView = Get.isRegistered<AgoraCallController>() &&
        objectMgr.callMgr.getCurrentState() != CallState.Idle;
    pdebug(
      "ifMinimizedCallView=====> sender:$sender, inCall:$inCallView, isMin:${objectMgr.callMgr.isMinimized.value}",
    );
    if (inCallView) {
      if (!objectMgr.callMgr.isMinimized.value) {
        Get.find<AgoraCallController>().onBackBtnClicked();
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
          await objectMgr.chatMgr.loadMessageFromChat(chat);
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
          ifMinimizedCallView("notificationRouting2", null);
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
          sharedDataManager.gotoWalletHistoryPage(navigatorKey.currentContext!);
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          Get.to(
            () => TransactionDetailsView(
              transaction: transaction,
              isAfterWithdraw: false,
            ),
          );
        });

        Get.find<HomeController>().onPageChange(3);
        ifMinimizedCallView("notificationRouting4", null);
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
          voipDeviceToken: pushDeviceInfo['voipToken'] ?? "",
        );
        flutterLocalNotificationsPlugin.cancelAll();
      }
    }
  }

  void onClickLocalNotification() {
    didReceiveLocalNotificationStream.stream.listen((String? payload) async {
      localNotificationClicking = true;
      Debounce(const Duration(milliseconds: 300)).call(() {
        localNotificationClicking = false;
      });

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
            navigatorKey.currentState?.context,
            action: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              goToPage(data);
            },
          );
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
          Routes.toChat(chat: chat);
        } else {
          if (!Get.currentRoute.contains("${chat.chat_id}")) {
            Get.until(
              (route) =>
                  Get.currentRoute == RouteName.home ||
                  Get.currentRoute.contains("${chat.chat_id}"),
            );
            Routes.toChat(chat: chat);
            ifMinimizedCallView("goToPage", chat);
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
          sharedDataManager.gotoWalletHistoryPage(navigatorKey.currentContext!);
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          Get.to(
            () => TransactionDetailsView(
              transaction: transaction,
              isAfterWithdraw: false,
            ),
          );
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

  NotificationDetails getNotificationDetails(
    NotificationMode notificationMode,
  ) {
    switch (notificationMode) {
      case NotificationMode.soundVibrate:
        SoundData? soundData = objectMgr.soundMgr.notificationSound;
        List<String>? pathList = soundData?.filePath?.split('/');
        String? path = pathList?.last.split('.').first;

        return NotificationDetails(
          android: AndroidNotificationDetails(
            'DEFAULT_NOTIFICATION${soundData?.id}',
            'Default Notification',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound("noti_$path"),
            // playSound: true,
          ),
          iOS: const DarwinNotificationDetails(),
        );
      case NotificationMode.sound:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'SOUND_NOTIFICATION',
            'Sound Notification',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        );
      case NotificationMode.vibrate:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'VIBRATE_NOTIFICATION',
            'In Sound Notification',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(sound: 'empty.mp3'),
        );
      case NotificationMode.silent:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'SILENCE_NOTIFICATION',
            'In Sound Notification',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: false,
          ),
        );

      default:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'IN_DEFAULT_NOTIFICATION',
            'In Default Notification',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        );
    }
  }

  callNotificationDetails(String chatId, String chatName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        "IN_DEFAULT_CALL",
        "In Default Call",
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        sound: const RawResourceAndroidNotificationSound('call'),
        vibrationPattern: Int64List.fromList(callVibration),
      ),
    );
  }

  // Future showNotification(int notificationType,
  //     {int id = 0,
  //       String title = '',
  //       String? body,
  //       String? payLoad,
  //       bool isCallMessage = false}) async {
  //   ///暂时移除 macOs 的推送
  //
  //   if (title == "") {
  //     title = Config().appName;
  //   }
  //
  //   if (Platform.isAndroid) {
  //     if (state == AppLifecycleState.paused) {
  //       return;
  //     }
  //   } else if (Platform.isIOS) {
  //     if (!(await getAppState())) {
  //       return;
  //     }
  //   }
  //
  //   bool isNotMute = true;
  //   NotificationMode currentMode = NotificationMode.soundVibrate;
  //   // call notification will ignore mute settings
  //   if (!isCallMessage) {
  //     switch (notificationType) {
  //       case 1:
  //         isNotMute = privateChatMute.value;
  //         if (!privateChatPreviewNotification.value) {
  //           body = localized(chatPreview);
  //         }
  //         currentMode = privateChatNotificationType;
  //         break;
  //       case 2:
  //         isNotMute = groupChatMute.value;
  //         if (!groupChatPreviewNotification.value) {
  //           body = localized(chatPreview);
  //         }
  //         currentMode = groupChatNotificationType;
  //         break;
  //       case 3:
  //         isNotMute = friendMute.value;
  //         if (!friendPreviewNotification.value) {
  //           body = localized(friendPreview);
  //         }
  //         currentMode = friendNotificationType;
  //         break;
  //       case 4:
  //         isNotMute = walletMute.value;
  //         if (!walletPreviewNotification.value) {
  //           body = localized(walletPreview);
  //         }
  //         currentMode = walletNotificationType;
  //         break;
  //       case 999:
  //         isNotMute = true;
  //         break;
  //       default:
  //         break;
  //     }
  //   }
  //
  //   if (isOnlyVibrate) {
  //     currentMode = NotificationMode.vibrate;
  //   }
  //
  //   if (isNotMute) {
  //     flutterLocalNotificationsPlugin.show(
  //       id,
  //       title,
  //       body,
  //       getNotificationDetails(currentMode),
  //       payload: payLoad,
  //     );
  //   }
  // }

  /// 从socket来的在线消息，走这个方法进行推送
  Future showNotification(
    int notificationType, {
    int id = 0,
    String title = '',
    String? body,
    String? payLoad,
    bool isCallMessage = false,
    Chat? chat,
    message.Message? lastMessage,
  }) async {
    if (chat == null || lastMessage == null) {
      // 领取完红包后的推送，好友申请的在线推送，都暂时先屏蔽掉
      // 因为这里判断了chat 和 lastMessage 不为 null ，所以目前后面的 null值判断会报黄，没关系的，不用理会，万一后续要加上其他类型的推送，代码逻辑基本不用动的
      return;
    }
    if (lastMessage.typ == message.messageTypeImage ||
        lastMessage.typ == message.messageTypeVideo ||
        lastMessage.typ == message.messageTypeNewAlbum ||
        lastMessage.typ == message.messageTypeFace ||
        lastMessage.typ == message.messageTypeGif ||
        lastMessage.typ == message.messageCancelCall ||
        lastMessage.typ == message.messageTypeFile ||
        lastMessage.typ == message.messageTypeLocation ||
        lastMessage.typ == message.messageTypeRecommendFriend ||
        lastMessage.typ == message.messageTypeVoice ||
        lastMessage.typ == message.messageTypeReel ||
        lastMessage.typ == message.messageTypeExpiryTimeUpdate ||
        lastMessage.typ == message.messageTypeExpiredSoon ||
        lastMessage.typ == message.messageTypeText ||
        lastMessage.typ == message.messageTypeGroupChangeInfo ||
        lastMessage.typ == message.messageTypeAutoDeleteInterval ||
        lastMessage.typ == message.messageTypeNote ||
        lastMessage.typ == message.messageTypeChatHistory ||
        lastMessage.typ == message.messageTypeMarkdown) {
      // 目前只有这些信息支持
    } else {
      return;
    }
    // 等待接听 和 接听中 是不能推送的
    if (objectMgr.callMgr.currentState.value == CallState.Waiting) {
      return;
    }
    if (title == "") {
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
      if (Platform.isMacOS) {
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

      if (Platform.isAndroid) {
        SoundData? soundData = objectMgr.soundMgr.notificationSound;
        List<String>? pathList = soundData?.filePath?.split('/');
        String? path = pathList?.last.split('.').first;

        final isInCall = objectMgr.callMgr.currentState.value != CallState.Idle;
        pdebug("isInCall=====> $isInCall");
        flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'IN_DEFAULT_NOTIFICATION',
              'In Default Notification',
              importance: Importance.low, // 低优先级，降低弹窗出现的可能性
              priority: Priority.low, // 低优先级，减少系统突出显示通知的概率
              sound: isInCall
                  ? null
                  : RawResourceAndroidNotificationSound("noti_$path"),
            ),
          ),
          payload: payLoad,
        );
      }

      // 只有错误的信息 才需要判断是否要展示
      if (lastMessage.sendState == message.MESSAGE_SEND_FAIL &&
          haveBeenNotified(lastMessage)) {
        return;
      }

      /// 这块是发出声响的 在Incall的状态下是不能有响声的
      if (!objectMgr.loginMgr.isDesktop &&
          objectMgr.callMgr.currentState.value == CallState.Idle) {
        final ringerStatus = await SoundMode.ringerModeStatus;
        final isMute = [RingerModeStatus.silent, RingerModeStatus.vibrate]
            .contains(ringerStatus);
        if (!isCallMessage &&
            !isMute &&
            (currentMode == NotificationMode.sound ||
                currentMode == NotificationMode.soundVibrate)) {
          int notificationType = SoundTrackType.SoundTypeNotification.value;
          SoundData? soundData = objectMgr.soundMgr.notificationSound;
          if (chat.isGroup) {
            notificationType = SoundTrackType.SoundTypeGroupNotification.value;
            soundData = objectMgr.soundMgr.groupNotificationSound;
          }
          if (soundData?.filePath != null) {
            objectMgr.soundMgr.playSound(notificationType);
          }
        }
      }

      // 真正的推送弹框
      InAppNotification.show(
        duration: const Duration(seconds: 8),
        child: GestureDetector(
          onTap: () {
            if (Get.context != null) {
              InAppNotification.dismiss(context: navigatorKey.currentContext!);
            }

            // 有通话时需要变成小窗
            ifMinimizedCallView("InAppNotification", chat);

            Routes.toChat(chat: chat);
          },
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 5),
            margin: const EdgeInsets.only(left: 10, right: 10),
            width: 1.sw,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: colorWhite,
              boxShadow: [
                BoxShadow(
                  color: colorTextPrimary.withOpacity(0.2), // 阴影颜色
                  spreadRadius: 0, // 阴影扩散的范围
                  blurRadius: 32, // 阴影模糊的范围
                  offset: const Offset(0, 0), // 阴影偏移量，x轴和y轴方向
                ),
              ],
            ),
            child: buildOnlineNotificationContent(
              chat,
              lastMessage,
              title,
              body ?? "",
              notificationType,
              payLoad ?? "",
            ),
          ),
        ),
        context: navigatorKey.currentContext!,
      );

      // 震动的
      if (currentMode == NotificationMode.soundVibrate ||
          currentMode == NotificationMode.vibrate) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate();
        }
      }

      // 标记这条信息通知过
      saveNotifiedMessage(lastMessage);
    }
  }

  Widget buildOnlineNotificationContent(
    Chat? chat,
    message.Message? lastMessage,
    String title,
    String body,
    int notificationType,
    String payLoad,
  ) {
    const double iconSize = 53;
    String name = ChatCellContentFactory.getUserNickName(
      lastMessage?.chat_id,
      lastMessage?.send_id,
    );
    if (lastMessage != null &&
        chat != null &&
        (lastMessage.typ == message.messageTypeImage ||
            lastMessage.typ == message.messageTypeVideo ||
            lastMessage.typ == message.messageTypeNewAlbum ||
            lastMessage.typ == message.messageTypeFace ||
            lastMessage.typ == message.messageTypeGif ||
            lastMessage.typ == message.messageCancelCall ||
            lastMessage.typ == message.messageTypeFile ||
            lastMessage.typ == message.messageTypeLocation ||
            lastMessage.typ == message.messageTypeRecommendFriend ||
            lastMessage.typ == message.messageTypeVoice ||
            lastMessage.typ == message.messageTypeReel ||
            lastMessage.typ == message.messageTypeExpiryTimeUpdate ||
            lastMessage.typ == message.messageTypeExpiredSoon ||
            lastMessage.typ == message.messageTypeNote ||
            lastMessage.typ == message.messageTypeChatHistory ||
            lastMessage.typ == message.messageTypeMarkdown)) {
      var description = descriptiveText(lastMessage).isNotEmpty
          ? descriptiveText(lastMessage)
          : body;
      // 图片 相册 视频 GIFT 贴纸 取消电话 文件 位置 推荐好友 声音 内容
      return Row(
        children: [
          // 头像
          NotificationCellContentFactory.createAvatar(chat, iconSize),
          // 间隔
          const SizedBox(
            width: 10,
          ),
          // title 和 subtitle
          SizedBox(
            width: 1.sw - iconSize * 2 - 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // title
                NotificationCellContentFactory.createTitle(chat, title, name),
                // subtitle
                NotificationCellContentFactory.createSubtitle(description),
              ],
            ),
          ),
          // 后面的预览图片 和 头像大小一样的
          (lastMessage.typ == message.messageTypeImage ||
                      lastMessage.typ == message.messageTypeVideo ||
                      lastMessage.typ == message.messageTypeNewAlbum ||
                      lastMessage.typ == message.messageTypeGif ||
                      lastMessage.typ == message.messageTypeFace ||
                      lastMessage.typ == message.messageTypeReel) &&
                  lastMessage.sendState != message.MESSAGE_SEND_FAIL
              ? NotificationCellContentFactory.createComponent(
                  chat: chat,
                  lastMessage: lastMessage,
                  mediaContentSize: iconSize,
                  messageSendState: 1,
                )
              : const SizedBox(width: 0.1),
        ],
      );
    } else {
      // 文字的内容 notificationType=2 notificationType=3 notificationType=4
      return Row(
        children: [
          // 头像
          NotificationCellContentFactory.createAvatar(chat, iconSize),
          // 间隔
          const SizedBox(
            width: 10,
          ),
          // title 和 subtitle
          SizedBox(
            width: 1.sw - iconSize - 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // title
                NotificationCellContentFactory.createTitle(chat, title, name),
                //subtitle
                (chat != null && lastMessage != null)
                    ? NotificationCellContentFactory.createComponent(
                        chat: chat,
                        lastMessage: lastMessage,
                        mediaContentSize: iconSize,
                        messageSendState: 1,
                      )
                    : NotificationCellContentFactory.createSubtitle(
                        body,
                        maxLine: notificationType == 4 ? 2 : 1,
                      ),
              ],
            ),
          ),
        ],
      );
    }
  }

  String descriptiveText(message.Message lastMessage) {
    if (lastMessage.typ == message.messageTypeImage) {
      return lastMessage.sendState == message.MESSAGE_SEND_FAIL
          ? localized(sendingPhotosFailure)
          : localized(chatPhoto);
    } else if (lastMessage.typ == message.messageTypeVideo ||
        lastMessage.typ == message.messageTypeReel) {
      return lastMessage.sendState == message.MESSAGE_SEND_FAIL
          ? localized(sendingVideoFailure)
          : localized(videosMessage);
    } else if (lastMessage.typ == message.messageTypeNewAlbum) {
      return lastMessage.sendState == message.MESSAGE_SEND_FAIL
          ? localized(sendingAlbumFailure)
          : localized(permissionGallery);
    } else if (lastMessage.typ == message.messageTypeFace) {
      return localized(chatTagSticker);
    } else if (lastMessage.typ == message.messageTypeGif) {
      return 'GIF';
    } else if (lastMessage.typ == message.messageTypeVoice) {
      return localized(voiceMsg);
    } else if (lastMessage.typ == message.messageTypeFile) {
      Map contentMap = json.decode(lastMessage.content);
      return contentMap['file_name'] ?? '文件';
    } else if (lastMessage.typ == message.messageTypeLocation) {
      return localized(pushNotificationOnlineLocation);
    } else if (lastMessage.typ == message.messageTypeRecommendFriend) {
      return localized(pushNotificationOnlineContact);
    } else if (lastMessage.typ == message.messageCancelCall) {
      return localized(missedPhone);
    } else if (lastMessage.typ == message.messageTypeNote) {
      return localized(noteEditTitle);
    } else if (lastMessage.typ == message.messageTypeChatHistory) {
      return localized(chatHistory);
    } else if (lastMessage.typ == message.messageTypeMarkdown) {
      final MessageMarkdown m =
          lastMessage.decodeContent(cl: MessageMarkdown.creator);
      return "${localized(publishTag)} ${m.title}";
    } else {
      return "";
    }
  }

  void saveNotifiedMessage(message.Message message) {
    objectMgr.localStorageMgr.write(
      '${message.chat_id}_${message.send_id}_${message.create_time}',
      '1',
    );
  }

  bool haveBeenNotified(message.Message message) {
    return objectMgr.localStorageMgr.read<String>(
          '${message.chat_id}_${message.send_id}_${message.create_time}',
        ) ==
        '1';
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

    callNotificationId = chat.id.toString();
    if (!objectMgr.callMgr.isCallCompleted(rtcChannelId)) {
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
        voipDeviceToken: pushDeviceInfo['voipToken'] ?? "",
        platform: int.parse(pushDeviceInfo['platform'] ?? ""),
        source: int.parse(pushDeviceInfo['source']),
      );
      await objectMgr.localStorageMgr
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

  _updateBadgeNumber(Object sender, Object type, Object? block) async {
    if (objectMgr.loginMgr.isDesktop) {
      updateBadge(objectMgr.chatMgr.totalUnreadCount.value);
    }
    if (Platform.isAndroid) {
      // 由於該套件會佔用badge number，因此直接設為0，解除佔用綁定
      FlutterAppBadger.updateBadgeCount(0);
    }

    if (Platform.isIOS) {
      await _methodChannel.invokeMethod(
        'updateBadgeNumber',
        objectMgr.chatMgr.totalUnreadCount.value,
      );
    }
  }

  void updateBadge(int unreadCount) {
    const MethodChannel methodChannel = MethodChannel('desktopNotification');
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

  void cancelExcludeIncomingCall() async {
    for (final activeNotification
        in await flutterLocalNotificationsPlugin.getActiveNotifications()) {
      if (activeNotification.body == localized(incomingCall)) {
        continue;
      }
      flutterLocalNotificationsPlugin.cancel(activeNotification.id ?? 0);
    }
  }

  void cancelRemoteIncomingCall() async {
    for (final activeNotification
        in await flutterLocalNotificationsPlugin.getActiveNotifications()) {
      if (activeNotification.body == localized(incomingCall)) {
        flutterLocalNotificationsPlugin.cancel(activeNotification.id ?? 0);
      }
    }
  }

  void cancelAllNotification() async {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void logout() {
    if (objectMgr.loginMgr.isMobile) {
      if (pushDeviceInfo['registrationId'] != null &&
          pushDeviceInfo['registrationId'] != "") {
        pushServices.unRegisterPushDevice(
          registrationId: pushDeviceInfo['registrationId'].toString(),
          voipDeviceToken: pushDeviceInfo['voipToken'] ?? "",
        );
      }

      cancelAllNotification();
    } else {
      updateBadge(0);
      objectMgr.chatMgr.off(ChatMgr.eventUnreadTotalCount, _updateBadgeNumber);
    }
    WidgetsBinding.instance.removeObserver(this);
  }
}
