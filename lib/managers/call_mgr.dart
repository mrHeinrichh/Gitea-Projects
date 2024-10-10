import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/api/message_push.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/call_info.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/battery_helper.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/agora/agora_call_answer.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/call_float.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/data/db_call_log.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/device_list_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/views/agora/video_dimensions_model.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';

enum CallState { Idle, Init, Requesting, Waiting, Ringing, Connecting, InCall }

enum CallEvent {
  CallStart(0) /*拨打*/,
  CallInited(1) /*初始化完成*/,
  CallInitFailed(2) /*初始化失败*/,
  Requested(3) /*连接完成*/,
  RequestFailed(4) /*连接失败*/,
  CallCancel(5) /*取消拨打*/,
  CallTimeOut(6) /*拨打超时*/,
  CallBusy(7) /*忙音*/,
  CallOptAccepted(8) /*对方接听*/,
  CallOptReject(9) /*对方拒接*/,
  CallOptEnd(10) /*对方挂断*/,
  CallOptBusy(11) /*对方忙线*/,
  CallOptCancel(12) /*对方取消拨打*/,
  CallInComing(13) /*收到来电*/,
  CallReject(14) /*拒接*/,
  CallAccepted(15) /*接听*/,
  CallEnd(16) /*挂断*/,
  CallOtherDeviceReject(17) /*其他设备拒接*/,
  CallOtherDeviceAccepted(18) /*其他设备接听*/,
  CallLogout(19) /*退出登陆事件*/,
  CallKitErr(20) /*callkit错误事件*/,
  CallRinging(21) /*正在响铃*/,
  CallNoPermisson(22) /*没有权限，初始化失败*/,
  CallNetException(23) /*网络波动导致异常中断*/,
  CallException(24) /*通话异常*/,
  CallVideoTencentEnd(25) /*仅播放中看需不需要回复*/,
  CallConnected(26) /*连接完成*/;

  const CallEvent(this.event);

  final int event;
}

enum ServerCallState {
  waiting(0),
  ended(1),
  optEnded(2),
  rejected(3),
  optRejected(4),
  cancelled(5),
  optCancelled(6),
  busy(7),
  optBusy(8),
  noRsp(9),
  optNoRsp(10),
  answer(11),
  ringing(12),
  missedCall(13),
  optMissedCall(14);

  const ServerCallState(this.status);

  final int status;
}

// 扬声器自定义枚举
enum SoundType {
  reciever(1), // 听筒
  speaker(2), // 播放器
  bluetooth(3); // 蓝牙

  const SoundType(this.code);
  final int code;

  String get value => switch (this) {
        SoundType.reciever => Platform.isIOS ? 'reciever' : 'earpiece',
        SoundType.speaker => "speaker",
        SoundType.bluetooth => "bluetooth",
      };
}

class CallMgr with EventDispatcher implements MgrInterface {
  RtcEngine? engine;
  late SharedRemoteDB _sharedDB;
  static const _rtcChannel = 'jxim/rtc';
  final timeout = 60;
  final String socketCallLog = "video_call";
  final String socketCallNotification = "notification_setting";
  static const eventCallStateChanged = "eventCallStateChanged";
  static const eventIncomingCall = "eventIncomingCall";
  static const eventTopFloating = "eventTopFloating";
  static const String eventBluetoothChanged = 'eventBluetoothChanged';
  static const _methodChannel = MethodChannel(_rtcChannel);
  Timer? _callTimeOut;
  Timer? _inCallTimer;
  int _startInitTime = 0;
  int _startInCallTime = 0;
  int _friendOpenStreamTime = 0;
  int _closeCallTime = 0;
  final currentState = CallState.Idle.obs;
  bool isInviter = false;
  bool voipEnabled = true;

  int _currentDeviceUdid = 0;
  String? _rtcToken;
  String _rtcEncryptKey = "";
  String rtcChannelId = "";
  bool isVoiceCall = false;
  bool _friendMuteSwitch = true;
  int resolution = 15;
  int fps = 30;

  /*对方摄像头是否打开*/
  Call? callItem;
  Chat? _chat;
  User? opponent;
  BuildContext? context;
  AppLifecycleState? _appLifecycleState;
  bool isLogout = false;
  bool isCallKit = false;
  bool mustPermissionDialogOpened = false; // 语音和视频权限必须有开起
  bool optPermissionExist = false; // 安卓浮窗权限必须有开起
  bool isInitLandscape = false;

  //  UI 相关
  AgoraCallController? agoraViewController;
  final firstLocalVideoFrameDone = false.obs;
  final selfCameraOn = false.obs; //控制自己摄像头
  final isSpeaker = false.obs;
  final isBluetooth = false.obs;
  final soundType = SoundType.reciever.obs;
  final isMute = false.obs;
  final shouldShowNativeVideo = false.obs;
  final friendCameraOn = false.obs; //控制对方摄像头
  final isFrontCamera = false.obs;
  final floatWindowIsMe = false.obs;
  final networkStatus = ''.obs;
  int selfNetworkQuality = 4;
  int friendNetworkQuality = 4;
  final isMinimized = false.obs;
  bool selfNetOk = true;
  bool friendNetOk = true;
  int surfaceViewId = 0;

  Map<String, dynamic> keepState = {};
  List<String> completedCalls = [];

  late CallTopFloat _callTopFloating;
  double topFloatingOffsetY = 0.0;

  // 视频拨打中
  bool get isDailingVdoCall {
    return !isVoiceCall;
  }

  String _logId = "";
  @override
  Future<void> register() async {
    _sharedDB = objectMgr.sharedRemoteDB;
  }

  @override
  Future<void> init() async {
    _methodChannel.setMethodCallHandler(nativeCallback);

    //SocketOpen已经触发，进行事件补偿
    if (objectMgr.socketMgr.isAlreadyPubSocketOpen) {
      _onSocketOpen(null, null, null);
    }
    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);

    //之后要删掉，为了获取deviceID打印log用的
    objectMgr.loginMgr.getOSType();

    // 通话时顶部的浮框
    if (isTopFloatingWorking()) {
      _callTopFloating = CallTopFloat();
    }

    // ios在用户强制kill掉app的时候，不会触发objectMgr的didChangeAppLifecycleState函数
    if (Platform.isIOS && _appLifecycleState == null) {
      _appLifecycleState = AppLifecycleState.resumed;
    }
  }

  Future<void> _onSocketOpen(a, b, c) async {
    getCallServerStatus(rtcChannelId);
  }

  void getCallServerStatus(String channelId) async {
    try {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "getCallServerStatus",
            opt: "start",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );
      if (channelId != "" && channelId != rtcChannelId) {
        return;
      }
      CallInfo callInfo = await getCurrentCallStatus();
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "getCallServerStatus",
            opt:
                "inCall: ${callInfo.inCall} CallItem: ${callInfo.call?.toJson()}",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );
      if (callInfo.inCall) {
        if (callInfo.call != null) {
          doCallChangePorcess(callInfo.call!);
        }
      } else {
        handleEvent(CallEvent.CallNetException);
      }
    } catch (e) {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "getCallServerStatus",
            opt: "failed e:$e",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );
    }
  }

  @override
  Future<void> reloadData() async {
    isLogout = false;
  }

  closeAllPopUpMenu() {
    Get.find<ChatListController>().popUpMenuController.hideMenu();
    if (Get.isRegistered<CustomInputController>()) {
      Get.find<CustomInputController>().chatController.resetPopupWindow();
    }

    if (Get.isRegistered<ChatInfoController>()) {
      Get.find<ChatInfoController>().floatWindowOverlay?.remove();
    }

    if (Get.isRegistered<GroupChatInfoController>()) {
      Get.find<GroupChatInfoController>().floatWindowOverlay?.remove();
    }

    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().popUpMenuController.hideMenu();
    }
  }

  getChat(int chatID) async {
    Chat? chat = objectMgr.chatMgr.getChatById(chatID);
    chat ??= await objectMgr.chatMgr.loadRemoteChatByChatID(chatID);
    return chat;
  }

  getFriendUser() async {
    User? user = objectMgr.userMgr.getUserById(_chat!.friend_id);
    user ??= await objectMgr.userMgr.getRemoteUser(_chat!.friend_id);
    return user;
  }

  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      if (Platform.isAndroid) {
        _methodChannel.invokeMethod("stopVoIPService");
      } else if (Platform.isIOS) {
        //防止在画中画时结束通话，页面没有关闭的情况，但这个逻辑最好做在popCallView里面
        if (Get.currentRoute == RouteName.agoraCallView &&
            Get.isRegistered<AgoraCallController>() &&
            objectMgr.callMgr.currentState.value == CallState.Idle) {
          Get.back();
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      if (Platform.isAndroid &&
          (currentState.value == CallState.InCall ||
              currentState.value == CallState.Ringing) &&
          !objectMgr.pushMgr.localNotificationClicking) {
        if (_chat != null) {
          _methodChannel.invokeMethod(
            "startVoIPService",
            {"chatId": _chat!.chat_id.toString()},
          );
        }
      }
    }
  }

  floatingWindowOnTap({bool isBack = false}) {
    if (isMinimized.value) {
      if (!isBack) {
        floatWindowIsMe.value = keepState["floatWindowIsMe"] ?? false;

        Get.toNamed(
          RouteName.agoraCallView,
          arguments: [
            objectMgr.callMgr.opponent,
          ],
        );

        // 目的是当进入通话页面的时候，已经向下偏移的offset不要复位，这样当退出通话页面时，就不会有页面跳动
        showTopFloating(false, goingDown: true);

        if (!selfCameraOn.value && !friendCameraOn.value ||
            currentState.value != CallState.InCall) {
          CallFloat().floatingManager.closeAllFloating();
        }
      } else {
        floatWindowIsMe.value = false;
      }
      isMinimized.value = isBack;

      if (!isBack) {
        objectMgr.callMgr.onExitCallView(isExit: false);
      }
    } else {
      floatWindowIsMe.value = !floatWindowIsMe.value;
    }

    if (!objectMgr.callMgr.friendCameraOn.value &&
        !objectMgr.callMgr.selfCameraOn.value) {
      updateShowNativeVideo(false);
    } else if (objectMgr.callMgr.floatWindowIsMe.value) {
      updateShowNativeVideo(
        objectMgr.callMgr.friendCameraOn.value,
        updateButton: objectMgr.callMgr.friendCameraOn.value == false,
      );
    } else if (!objectMgr.callMgr.floatWindowIsMe.value) {
      updateShowNativeVideo(
        objectMgr.callMgr.selfCameraOn.value,
        updateButton: objectMgr.callMgr.selfCameraOn.value == false,
      );
    }
    updateNativeFloatVal();
  }

  updateNativeFloatVal() {
    _methodChannel.invokeMethod("toggleFloat", {"isMe": floatWindowIsMe.value});
  }

  checkIsEnableVoip() async {
    final res = await deviceList();
    if (res['current_device'] != null) {
      var currentDevice = DeviceModel.fromJson(res['current_device']);
      _currentDeviceUdid = currentDevice.udid!;
      if (currentDevice.enableVoip == 1) {
        voipEnabled = true;
      } else {
        voipEnabled = false;
      }
    }
  }

  void handleEvent(CallEvent event) async {
    CallState preCallState = currentState.value;
    switch (currentState.value) {
      case CallState.Idle:
        await _handleEventIdleState(event);
        break;
      case CallState.Init:
        _handleEventInitState(event);
        break;
      case CallState.Requesting:
        _handleEventRequestingState(event);
        break;
      case CallState.Waiting:
        _handleEventWaitingState(event);
        break;
      case CallState.Ringing:
        _handleEventRingingState(event);
        break;
      case CallState.Connecting:
        _handleEventConnectingState(event);
        break;
      case CallState.InCall:
        _handleEventInCallState(event);
        break;
    }

    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "handleEvent",
          state: currentState.value,
          event: event,
          opt: "prestate: $preCallState",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );

    pdebug(
      "Call handleEvent event: $event prestate:$preCallState  state:${currentState.value}",
    );
    if (preCallState != currentState.value) {
      if (agoraViewController != null) {
        agoraViewController!.updateCallStatusString(callEvent: event);
      }
    }

    this.event(this, CallMgr.eventCallStateChanged, data: event);
  }

  String getLogCallInfoStr() {
    return "${objectMgr.userMgr.mainUser.uid}";
  }

  /// 需要知道当前呼叫状态变化
  _setCurrentCallStateValue(CallState state) {
    _changeCurrentCallStateValue(state);
    if (Platform.isAndroid) return; //android这里报错
    if (state == CallState.Idle) {
      SoundMode.iosPlayMp3();
    } else {
      SoundMode.iosPauseMp3();
    }
  }

  Future<void> _handleEventIdleState(CallEvent event) async {
    switch (event) {
      case CallEvent.CallStart:
        _setCurrentCallStateValue(CallState.Init);
        isInviter = true;
        initCall("CallStart");
        break;
      case CallEvent.CallInComing:
        _setCurrentCallStateValue(CallState.Init);
        isInviter = false;
        initCall("CallInComing");
        break;
      case CallEvent.CallNoPermisson:
      case CallEvent.CallException:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      default:
        pdebug('State:Idle illegal event:$event');
        break;
    }
  }

  void _handleEventInitState(CallEvent event) {
    switch (event) {
      case CallEvent.CallAccepted:
        //此时还未初始化完成，等待重试
        Future.delayed(const Duration(milliseconds: 100), () {
          handleEvent(event);
        });
        break;
      case CallEvent.CallReject:
      case CallEvent.CallLogout:
      case CallEvent.CallInitFailed:
      case CallEvent.CallNoPermisson:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.CallException:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallInited:
        _setCurrentCallStateValue(CallState.Requesting);
        requestToken();
        break;
      default:
        pdebug('State:Init illegal event:$event');
        break;
    }
  }

  void _handleEventRequestingState(CallEvent event) async {
    switch (event) {
      case CallEvent.CallAccepted:
        //此时还未连接完成，等待重试
        Future.delayed(const Duration(milliseconds: 100), () {
          handleEvent(event);
        });
        break;
      case CallEvent.CallReject:
      case CallEvent.CallLogout:
      case CallEvent.RequestFailed:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallBusy:
      case CallEvent.CallOptBusy:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.CallNoPermisson:
      case CallEvent.CallException:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.Requested:
        _setCurrentCallStateValue(CallState.Waiting);
        if (isInviter) {
          _methodChannel.invokeMethod("playDialingSound");
        }
        break;
      default:
        pdebug('State:Connecting illegal event:$event');
        break;
    }
  }

  Future<void> _handleEventWaitingState(CallEvent event) async {
    switch (event) {
      case CallEvent.CallLogout:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallOptReject:
      case CallEvent.CallReject:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.RequestFailed:
      case CallEvent.CallNoPermisson:
      case CallEvent.CallNetException:
      case CallEvent.CallException:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallRinging:
        _setCurrentCallStateValue(CallState.Ringing);
        break;
      case CallEvent.CallOptAccepted:
      case CallEvent.CallAccepted:
        _setCurrentCallStateValue(CallState.Connecting);
        resetNotification();
        if (!isInviter) {
          joinChannel();
          updateServerStatus(event);
        }
        if (!isVoiceCall) {
          CallFloat().showAppFloatingWindow();
          // showTopFloating(true);
          floatingWindowOnTap();
        }
        if (isVoiceCall) {
          await _methodChannel.invokeMethod("playPickedSound");
        }

        _methodChannel.invokeMethod("enableAgoraAudio");

        // 同步个对方当前的电量状态
        if (Get.isRegistered<AgoraCallController>()) {
          Get.find<AgoraCallController>().syncWithBackendLowBattery();
        }

        break;
      default:
        pdebug('State:Waiting illegal event:$event');
        break;
    }
  }

  void _handleEventRingingState(CallEvent event) async {
    switch (event) {
      case CallEvent.CallLogout:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallOptReject:
      case CallEvent.CallOptEnd:
      case CallEvent.CallReject:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.RequestFailed:
      case CallEvent.CallNoPermisson:
      case CallEvent.CallNetException:
      case CallEvent.CallException:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallOptAccepted:
      case CallEvent.CallAccepted:
        _setCurrentCallStateValue(CallState.Connecting);
        resetNotification();
        if (!isInviter) {
          joinChannel();
          updateServerStatus(event);
        }
        if (!isVoiceCall) {
          CallFloat().showAppFloatingWindow();
          // showTopFloating(true);
          floatingWindowOnTap();
        }
        if (isVoiceCall) {
          await _methodChannel.invokeMethod("playPickedSound");
        }

        _methodChannel.invokeMethod("enableAgoraAudio");

        // 同步个对方当前的电量状态
        if (Get.isRegistered<AgoraCallController>()) {
          Get.find<AgoraCallController>().syncWithBackendLowBattery();
        }
        break;
      default:
        pdebug('State:Ringing illegal event:$event');
        break;
    }
  }

  void _handleEventConnectingState(CallEvent event) {
    switch (event) {
      case CallEvent.CallConnected:
        _setCurrentCallStateValue(CallState.InCall);
        unsetCallTimeOut();
        startInCallTimer();
        break;
      case CallEvent.CallCancel:
      case CallEvent.CallLogout:
      case CallEvent.CallEnd:
      case CallEvent.CallOptEnd:
      case CallEvent.CallOptCancel:
      case CallEvent.RequestFailed:
      case CallEvent.CallNetException:
      case CallEvent.CallException:
      case CallEvent.CallTimeOut:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallBusy:
        updateCallLog(event, opponent!);
        break;
      default:
        pdebug('State:InCall illegal event:$event');
        break;
    }
  }

  void _handleEventInCallState(CallEvent event) {
    switch (event) {
      case CallEvent.CallLogout:
      case CallEvent.CallEnd:
      case CallEvent.CallOptEnd:
      case CallEvent.CallOptCancel:
      case CallEvent.RequestFailed:
      case CallEvent.CallNetException:
      case CallEvent.CallException:
      case CallEvent.CallTimeOut:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallBusy:
        updateCallLog(event, opponent!);
        break;
      default:
        pdebug('State:InCall illegal event:$event');
        break;
    }
  }

  CallState getCurrentState() {
    return currentState.value;
  }

  bool _isAllowCall() {
    User? user = objectMgr.userMgr.getUserById(_chat!.friend_id);
    if (user != null) {
      opponent = user;
      if (user.deletedAt > 0) {
        Toast.showToast(localized(userHasBeenDeleted));
        return false;
      }
      return true;
    }
    return false;
  }

  Future<void> initCall(String sender) async {
    if (currentState.value != CallState.Init) return;
    _logId =
        "${DateTime.now().millisecondsSinceEpoch}-${objectMgr.userMgr.mainUser}";
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "initCall",
          state: currentState.value,
          opt: "isInviter: $isInviter",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );

    agoraViewController?.isEnding.value = false;

    // 通话时限制不支持横屏
    isInitLandscape = MediaQuery.of(navigatorKey.currentContext!).orientation ==
        Orientation.landscape;

    if (isInitLandscape) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    CallFloat().closeAllFloat();
    showTopFloating(false);
    if (isInviter) {
      if (await requestPermission() == false) {
        handleEvent(CallEvent.CallNoPermisson);
        return;
      }
    }
    objectMgr.chatMgr.event(this, ChatMgr.eventVoicePause);
    // resetNotification();
    if (isInviter) {
      Get.toNamed(RouteName.agoraCallView);
      toggleProximity(true);
    } else if (currentState.value == CallState.Init) {
      if (!isCallKit) {
        event(this, eventIncomingCall);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "initCall",
              state: currentState.value,
              opt:
                  "AgoraCallAnswer started: Context: ${Get.context}, chat: $_chat, friendUid:${_chat?.friend_id}",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );

        if (Get.isRegistered<AgoraCallController>()) {
          if (Get.find<AgoraCallController>().isInTryMode()) {
            popCallView(CallEvent.CallStart);
          }
        }

        if (Platform.isIOS && isTopFloatingWorking()) {
          // iOS端就要唤起callkit，是有callkit提供的提示弹框
          incomingCallKit();
        } else {
          // 这个是flutter 层的一个电话提示弹框
          InAppNotification.show(
            child: AgoraCallAnswer(_chat!),
            context: Get.context!,
            duration: const Duration(seconds: 4294967296),
            onDismiss: () {
              if (!Get.isRegistered<AgoraCallController>()) {
                CallFloat().onMinimizeWindow();
                showTopFloating(true);
              }
            },
          );
        }

        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "initCall",
              state: currentState.value,
              opt: "AgoraCallAnswer end",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
      }
    }
    _startInitTime = DateTime.now().millisecondsSinceEpoch;
    if (!isInviter) {
      requestPermission();
    }
    WakelockPlus.enable();
    setCallTimeOut();

    initAgoraEngine();

    if (!isInviter && notBlank(rtcChannelId)) {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "initCall",
            state: currentState.value,
            opt: "initCall end",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );

      if (Platform.isIOS) {
        final isIOSForeground =
            await _methodChannel.invokeMethod("isInForeground");
        if (!isCallKit && isIOSForeground) {
          _methodChannel.invokeMethod("playRingSound");
        }
      } else if (Platform.isAndroid) {
        final isInForeApp = await objectMgr.pushMgr.getAppState();
        if (isInForeApp) {
          _methodChannel.invokeMethod("playRingSound");
        }
      } else {
        objectMgr.pushMgr.showIncomingCallNotification(_chat!, rtcChannelId);
        objectMgr.pushMgr.cancelRemoteIncomingCall();
      }
    }
  }

  bool isCallCompleted(String channelId) {
    return completedCalls.contains(channelId);
  }

  Future<void> initAgoraEngine() async {
    try {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          type: MetricsMgr.METRICS_TYPE_CALL,
          msg:
              "uid:${objectMgr.userMgr.mainUser.uid} channel: $rtcChannelId initAgoraEngine -> width: ${VideoDimensionsModel.getVideoWidth(resolution)} height: ${VideoDimensionsModel.getVideoHeight(resolution)} at ${DateTime.now().millisecondsSinceEpoch} version: ${appVersionUtils.currentAppVersion}",
          mediaType: getLogCallInfoStr(),
        ),
      );

      _methodChannel.invokeMethod(
        'setupAgoraEngine',
        {
          "appID": Config().agoraAppID,
          "isVoiceCall": isVoiceCall,
          "fps": fps,
          "width": VideoDimensionsModel.getVideoWidth(resolution),
          "height": VideoDimensionsModel.getVideoHeight(resolution),
          "uid": opponent?.uid,
          "avatarUrl": opponent != null && notBlank(opponent?.profilePicture)
              ? "${serversUriMgr.download2Uri}/${opponent?.profilePicture}"
              : "",
          "nickname": objectMgr.userMgr.getUserTitle(opponent),
          "isInviter": isInviter,
        },
      );
      if (isVoiceCall) {
        shouldShowNativeVideo.value = false;
        floatWindowIsMe.value = true;
      } else {
        floatWindowIsMe.value = false;
        isSpeaker.value = true;
      }
    } catch (e) {
      handleEvent(CallEvent.CallInitFailed);
    }
  }

  onUserJoined(int uid) {
    if (!objectMgr.userMgr.isMe(uid)) {
      handleEvent(CallEvent.CallOptAccepted);
    }
  }

  remoteVideoStateChange(int uid, bool cameraIsOn) async {
    if (objectMgr.userMgr.isMe(uid)) {
      return;
    }
    friendCameraOn.value = cameraIsOn;
    if (friendCameraOn.value) {
      await requestFloatingPermission();

      shouldShowNativeVideo.value = true;

      if (!selfCameraOn.value) {
        floatWindowIsMe.value = true;
        CallFloat().showAppFloatingWindow();
        // showTopFloating(true);
        updateNativeFloatVal();
      }
    } else {
      if (selfCameraOn.value) {
        if (floatWindowIsMe.value) {
          updateShowNativeVideo(false, updateButton: true);
        }
      } else {
        if (isMinimized.value) {
          CallFloat().showAppFloatingWindow();
          showTopFloating(true);
        } else {
          CallFloat().closeAllFloat();
          showTopFloating(false);
        }

        floatWindowIsMe.value = true;
        updateNativeFloatVal();

        updateShowNativeVideo(false, updateButton: true);
      }
    }
  }

  Future<void> joinChannel() async {
    if (_rtcToken == null) {
      return;
    }
    _methodChannel.invokeMethod('joinChannel', {
      'token': _rtcToken!,
      'channelId': rtcChannelId,
      'uid': objectMgr.userMgr.mainUser.uid,
      "encryptKey": _rtcEncryptKey,
    });
  }

  Future<int> getAndroidVersionApi() async {
    return await _methodChannel.invokeMethod('getAndroidVersion', {});
  }

  void requestToken({int attempts = 0}) async {
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "requestToken",
          opt: "chat:${_chat?.chat_id}, isInviter: $isInviter",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );

    getRTCToken(
      _chat!.chat_id,
      isVoiceCall ? 0 : 1,
      recipientIds: isInviter ? [_chat!.friend_id] : [],
      channelId: isInviter ? null : rtcChannelId,
    )
        .then((value) => handleRTCResponse(value, _chat))
        .onError((error, stackTrace) {
      if (error is CodeException && error.getPrefix() == 20504) {
        handleEvent(CallEvent.CallOptBusy);
      } else if (error is CodeException && error.getPrefix() == 20505) {
        handleEvent(CallEvent.RequestFailed);
      } else if (error is CodeException && error.getPrefix() == 20509) {
        handleEvent(CallEvent.CallBusy);
      } else {
        handleEvent(CallEvent.RequestFailed);
      }
    });
  }

  Future<void> handleRTCResponse(ResponseData res, chat) async {
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "handleRTCResponse",
          opt: "code:${res.code}",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );
    if (res.success()) {
      final rtcToken = CallRtcToken.fromJson(res.data);
      _rtcToken = rtcToken.rtcToken;
      rtcChannelId = rtcToken.rtcChannelId!;
      _rtcEncryptKey = rtcToken.rtcEncryptKey!;

      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "handleRTCResponse",
            opt: "data:${rtcToken.toJson()}",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );

      if (isInviter) {
        if (Platform.isIOS && isTopFloatingWorking()) {
          // iOS端就要唤起callkit
          reportOutgoingCall();
        }
        await joinChannel();
      } else {
        handleEvent(CallEvent.Requested);
      }
    } else {
      if (res.code == 20307) {
        // black list / not friend
        handleEvent(CallEvent.CallOptReject);
      } else {
        handleEvent(CallEvent.RequestFailed);
      }
    }
  }

  void doCallNotificationChange(UpdateBlockBean block) {
    if (block.data != null) {
      var data = block.data;
      for (var item in data) {
        if (item["udid"] == _currentDeviceUdid.toString()) {
          voipEnabled = item["enable_voip"] == 1;
        }
      }
    }
  }

  void doCallChange(UpdateBlockBean block) async {
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "doCallChange",
          state: currentState.value,
          opt: "block: $block",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );

    if (block.opt != blockOptReplace) {
      return;
    }

    final Map<String, dynamic> callMap = json.decode(block.data[0]["message"]);
    if (callMap.containsKey("info")) {
      BatteryInfo batteryInfo = BatteryInfo.fromJson(callMap["info"]);
      doCalleeBatteryChanged(batteryInfo);
    } else {
      if (callMap['inviter_id'] == null && callMap['caller_id'] == null) {
        pdebug("doCallChange[error]: $callMap");
      }
      callItem = Call.fromJson(callMap);
      if (callItem != null) {
        doCallChangePorcess(callItem!);
      }
    }
  }

  void doCalleeBatteryChanged(BatteryInfo info) async {
    if (Get.isRegistered<AgoraCallController>()) {
      AgoraCallController agoraCallController = Get.find<AgoraCallController>();
      agoraCallController.updateBatteryInfo(info);
    }
  }

  void doCallChangePorcess(Call callItem) async {
    if (objectMgr.userMgr.isMe(callItem.callerId)) {
      /// 我是拨打方
      if (callItem.status == ServerCallState.optRejected.status) {
        handleEvent(CallEvent.CallOptReject);
      } else if (callItem.status == ServerCallState.ringing.status) {
        handleEvent(CallEvent.CallRinging);
      } else if (callItem.status == ServerCallState.optEnded.status) {
        handleEvent(CallEvent.CallOptEnd);
      } else if (callItem.status == ServerCallState.answer.status) {
        handleEvent(CallEvent.CallOptAccepted);
      }
    } else {
      /// 我是接听方
      if (callItem.status == ServerCallState.waiting.status ||
          callItem.status == ServerCallState.ringing.status) {
        if (currentState.value != CallState.Idle) {
          return;
        }
        if (!voipEnabled) {
          return;
        }

        if (Platform.isIOS) {
          final isIOSForeground =
              await _methodChannel.invokeMethod("isInForeground");
          if (isIOSForeground) {
            addChannelID([callItem.channelId]);
          }
        }
        isVoiceCall = callItem.isVideoCall == 0;
        selfCameraOn.value = callItem.isVideoCall == 1;
        rtcChannelId = callItem.channelId;
        opponent = await objectMgr.userMgr.loadUserById(callItem.callerId);
        _chat = await objectMgr.chatMgr.getChatByFriendId(callItem.callerId);
        handleEvent(CallEvent.CallInComing);
      } else if (callItem.status == ServerCallState.optCancelled.status) {
        handleEvent(CallEvent.CallOptCancel);
      } else if (callItem.status == ServerCallState.noRsp.status) {
        handleEvent(CallEvent.CallTimeOut);
      } else if (callItem.status == ServerCallState.busy.status) {
        objectMgr.callLogMgr.loadRemoteCallLog();
      } else if (callItem.status == ServerCallState.optRejected.status) {
        handleEvent(CallEvent.CallOtherDeviceReject);
      } else if (callItem.status == ServerCallState.answer.status) {
        handleEvent(CallEvent.CallOtherDeviceAccepted);
      } else if (callItem.status == ServerCallState.optEnded.status) {
        handleEvent(CallEvent.CallOptEnd);
      }
    }
  }

  Future<void> nativeCallback(MethodCall call) async {
    objectMgr.pushMgr.stopVibrate();
    objectMgr.pushMgr.clearNotification();
    objectMgr.pushMgr.cancelLocalNotification();

    pdebug(
      "CallsMgr: native callback: ${call.method} | ${call.arguments} | $currentState",
    );

    if (call.method != 'onNetworkQuality') {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          type: MetricsMgr.METRICS_TYPE_CALL,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "nativeCallback",
            opt: "method: ${call.method}",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );
    }

    switch (call.method) {
      case 'pushKitToken':
        await PushNotificationServices().registerPushDevice(
          registrationId: call.arguments,
          platform: 2,
          source: 2,
        );
        break;
      case 'callInited':
        handleEvent(CallEvent.CallInited);
        break;
      case 'CallInitFailed':
        handleEvent(CallEvent.CallInitFailed);
        break;
      case 'joinChannelSuccess':
        handleEvent(CallEvent.Requested);
        break;
      case 'acceptCall':
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(channelId: rtcChannelId, method: "acceptCall")
                .toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        if (await checkPermission() == false) {
          handleEvent(CallEvent.CallNoPermisson);
          return;
        }
        Map data = call.arguments;
        isVoiceCall = data["isVideo"] == 0;
        acceptCall();
        Get.toNamed(RouteName.agoraCallView);
        break;
      case 'rejectCall':
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(channelId: rtcChannelId, method: "rejectCall")
                .toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        rejectCall();
        break;
      case 'hangupCall':
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(channelId: rtcChannelId, method: "hangupCall")
                .toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        endCall();
        break;
      case 'muteCall':
        Map data = call.arguments;
        isMute.value = data['is_muted'];
        break;
      case 'callKitIncomingCall':
        if (Get.context != null) {
          InAppNotification.dismiss(context: Get.context!);
        }
        isCallKit = true;
        Map data = call.arguments;
        int chatID = int.parse(data['chat_id']);
        isVoiceCall = data['isVideoCall'] == 0;
        selfCameraOn.value = !isVoiceCall;
        _chat = await objectMgr.chatMgr.getChatByGroupId(chatID);
        if (_chat != null) {
          opponent = await objectMgr.userMgr.loadUserById(_chat!.friend_id);
          rtcChannelId = data['rtc_channel_id'];
        }
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "callKitIncomingCall",
              opt: "Chat: $_chat",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        handleEvent(CallEvent.CallInComing);
        break;
      case 'callKitError':
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "callKitIncomingCall",
              opt: "callKitError: ${call.arguments["error"]}",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );

        _setCurrentCallStateValue(CallState.Idle);
        closeCall(CallEvent.CallKitErr);
        break;
      case 'audioGain':
        break;
      case 'startCallIOS':
        int chatID = int.parse(call.arguments);
        Chat? chat = objectMgr.chatMgr.getChatById(chatID);
        if (chat != null) {
          startCall(chat, true);
        }
        break;
      case "onUserJoined":
        Map data = call.arguments;
        int uid = int.parse(data['uid']);
        onUserJoined(uid);
        break;
      case "onRemoteVideoStateChanged":
        Map data = call.arguments;
        if (data['cameraMuted'] != null) {
          int uid = int.parse(data['uid']);
          bool cameraMuted = data['cameraMuted'];
          remoteVideoStateChange(uid, !cameraMuted);
        }
        break;
      case "CallEnd":
        handleEvent(CallEvent.CallEnd);
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            type: MetricsMgr.METRICS_TYPE_CALL,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "nativeCallback",
              state: currentState.value,
              opt: "callMethod: ${call.method}",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        break;
      case "CallOptEnd":
        handleEvent(CallEvent.CallOptEnd);
        logMgr.logCallMgr.addMetrics(
          LogCallMsg(
            deviceId: _logId,
            type: MetricsMgr.METRICS_TYPE_CALL,
            msg: CallLogInfo(
              channelId: rtcChannelId,
              method: "nativeCallback",
              state: currentState.value,
              opt: "callMethod: ${call.method}",
            ).toString(),
            mediaType: getLogCallInfoStr(),
          ),
        );
        break;
      case "onNetworkQuality":
        Map data = call.arguments;
        if (currentState.value != CallState.InCall) {
          if (data["uid"] != null) {
            updateCallingNetwork(data["uid"], data["txQuality"]);
          }
        } else {
          if (data["uid"] != null) {
            updateInCallNetwork(
              data["uid"],
              data["txQuality"],
              data["rxQuality"],
            );
          }
        }
        break;
      case "onFirstLocalVideoFrame":
        firstLocalVideoFrameDone.value = true;
        break;
      case "cameraIsInit":
        updateShowNativeVideo(true);
        break;
      case "iosAppDidToForeground":
        break;
      case "iosAppDidToBackground":
        break;
      case "iOSVideoOnlyEndCall":
        event(this, CallMgr.eventCallStateChanged,
            data: CallEvent.CallVideoTencentEnd);
        break;
      case "firstRemoteAudioReceived":
        Map data = call.arguments;
        final uid = data["uid"] ?? -1;
        if (!objectMgr.userMgr.isMe(uid)) {
          handleEvent(CallEvent.CallConnected);
        }
        break;
      case "audioMuted":
        Map data = call.arguments;
        final uid = data["uid"] ?? -1;
        final isMuted = data["muted"] ?? false;
        pdebug("audioMuted=======> $uid, $isMuted");
        if (!objectMgr.userMgr.isMe(uid) && isMuted) {
          handleEvent(CallEvent.CallConnected);
        }
        break;
      default:
        break;
    }
  }

  void resetNotification() {
    objectMgr.pushMgr.stopVibrate();
    objectMgr.pushMgr.clearNotification();
    objectMgr.pushMgr.cancelLocalNotification();
    objectMgr.pushMgr.cancelAllNotification();

    _methodChannel.invokeMethod("stopRingSound");

    if (Platform.isAndroid) {
      objectMgr.pushMgr.stopCall();
    }
  }

  void setCallTimeOut() {
    if (_callTimeOut != null) {
      _callTimeOut!.cancel();
    }
    _callTimeOut = Timer(Duration(seconds: timeout), () {
      handleEvent(CallEvent.CallTimeOut);
    });
  }

  void unsetCallTimeOut() {
    if (_callTimeOut != null) {
      _callTimeOut!.cancel();
      _callTimeOut = null;
    }
  }

  void startInCallTimer() {
    if (_inCallTimer != null) {
      _inCallTimer!.cancel();
    }
    if (agoraViewController != null) {
      agoraViewController!.updateCallDuration(constructTimeVerbose(0));
    }
    _startInCallTime = DateTime.now().millisecondsSinceEpoch;
    _inCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateCallTime();

      if (_appLifecycleState != AppLifecycleState.resumed) {
        objectMgr.scheduleMgr.heartBeat.resetDelayCount();
      }
    });
  }

  void updateCallTime() {
    int curTime = DateTime.now().millisecondsSinceEpoch;
    int diffDuration = (curTime - _startInCallTime) ~/ 1000;
    if (agoraViewController != null) {
      agoraViewController!
          .updateCallDuration(constructTimeVerbose(diffDuration));
    }
  }

  void endInCallTimer() {
    if (_inCallTimer != null) {
      _inCallTimer!.cancel();
    }
  }

  Future<void> startCall(Chat chat, bool isVoiceCall) async {
    if (currentState.value == CallState.Idle) {
      _chat = chat;
      this.isVoiceCall = isVoiceCall;
      selfCameraOn.value = !isVoiceCall;
      if (!_isAllowCall()) {
        return;
      }
      handleEvent(CallEvent.CallStart);
    } else {
      Toast.showToast(localized(toastEndCallFirst));
    }
  }

  void cancelCall() {
    handleEvent(CallEvent.CallCancel);
  }

  void acceptCall({bool informCallKit = false}) async {
    if (mustPermissionDialogOpened) {
      return;
    }
    if (await requestPermission() == false) {
      return;
    }
    if (Platform.isIOS) {
      if (informCallKit) {
        acceptCallKit();
      }
    }
    toggleProximity(true);
    handleEvent(CallEvent.CallAccepted);
  }

  void rejectCall() {
    handleEvent(CallEvent.CallReject);
  }

  void endCall() {
    handleEvent(CallEvent.CallEnd);
  }

  Future<void> toggleProximity(bool enable) async =>
      await _methodChannel.invokeMethod('toggleProximity', {'enable': enable});

  Future<void> cancelCallKit() async {
    await _methodChannel.invokeMethod('cancelCallKitCall', {
      'rtc_channel_id': rtcChannelId,
      'chat_id': _chat!.chat_id,
      'video_call': isVoiceCall ? 1 : 0,
    });
  }

  Future<void> acceptCallKit() async =>
      await _methodChannel.invokeMethod('acceptCallKit', {
        'rtc_channel_id': rtcChannelId,
        'chat_id': _chat!.chat_id,
        'video_call': isVoiceCall ? 1 : 0,
      });

  Future<void> outgoingCallConnected() async =>
      await _methodChannel.invokeMethod('outgoingCallConnected', {
        'rtc_channel_id': rtcChannelId,
        'chat_id': _chat!.chat_id,
        'video_call': isVoiceCall ? 0 : 1,
      });

  Future<void> reportOutgoingCall() async =>
      await _methodChannel.invokeMethod('reportOutgoingCall', {
        "caller": opponent?.username ?? "",
        "chat_id": _chat?.chat_id ?? 0,
        "rtc_channel_id": rtcChannelId,
        "video_call": isVoiceCall ? 0 : 1,
      });

  Future<void> incomingCallKit() async =>
      await _methodChannel.invokeMethod('incomingCallKit', {
        "caller": opponent?.username ?? "",
        "chat_id": _chat?.chat_id ?? 0,
        "rtc_channel_id": rtcChannelId,
        "video_call": isVoiceCall ? 0 : 1,
      });

  Future<String> getCurrentAudioRoute() async {
    String result = await _methodChannel.invokeMethod('currentAudioRoute');
    return result;
  }

  Future<void> releaseAgoraEngine() async {
    await _methodChannel.invokeMethod(
      "releaseEngine",
      {"resetAudioSession": true},
    );
  }

  onExitCallView({bool isExit = true}) {
    _methodChannel.invokeMethod("callViewDismiss", {"isExit": isExit});
  }

  bluetoothPlay({bool isExit = true}) async {
    _methodChannel.invokeMethod("bluetooth");
  }

  //注：聊天室内的气泡，客户端不再发送，统一有服务器发送
  void closeCall(CallEvent event) async {
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "closeCall",
          state: currentState.value,
          event: event,
          opt: "started",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );

    shouldShowNativeVideo.value = false;
    await playEndSound(event);
    isCallKit = false;
    bool isIOSForeground = true;
    _changeCurrentCallStateValue(CallState.Idle);
    if (Platform.isIOS) {
      isIOSForeground = await _methodChannel.invokeMethod('isInForeground');
    }
    updateUIEndCallStatus(event);
    _closeCallTime = DateTime.now().millisecondsSinceEpoch;
    updateServerStatus(event);
    toggleProximity(false);
    releaseAgoraEngine();
    if (Platform.isIOS) {
      cancelCallKit();
    } else {
      stopVoIpService;
      _methodChannel.invokeMethod("closeFloatWindow");
    }
    firstLocalVideoFrameDone.value = false;
    if (opponent != null && event != CallEvent.CallKitErr) {
      await updateCallLog(event, opponent!);
    }
    unsetCallTimeOut();
    endInCallTimer();
    resetNotification();

    popCallView(event, iOSForeground: isIOSForeground);

    closeAllPopUpMenu();
    completedCalls.add(rtcChannelId);
    rtcChannelId = "";
    _rtcEncryptKey = "";
    _setCurrentCallStateValue(CallState.Idle);
    isVoiceCall = false;
    selfCameraOn.value = false;
    isSpeaker.value = false;
    isMute.value = false;
    friendCameraOn.value = false;
    isFrontCamera.value = false;
    floatWindowIsMe.value = true;
    isMinimized.value = false;
    _startInitTime = 0;
    _startInCallTime = 0;
    isLogout = false;
    networkStatus.value = '';
    selfNetworkQuality = 4;
    friendNetworkQuality = 4;
    _friendMuteSwitch = true;
    _friendOpenStreamTime = 0;
    _logId = "";
    if (Get.currentRoute.isNotEmpty && await WakelockPlus.enabled) {
      WakelockPlus.disable();
    }
    mustPermissionDialogOpened = false;
    objectMgr.pushMgr.isOnlyVibrate = false;
    keepState.clear();
    InAppNotification.dismiss(context: Get.context!);
    //当观看视频的时候接听电话，结束通话的时候需要重制视频页面支持横屏
    if (isInitLandscape) {
      isInitLandscape = false;
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: _logId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: rtcChannelId,
          method: "closeCall",
          state: currentState.value,
          opt: "ended",
        ).toString(),
        mediaType: getLogCallInfoStr(),
      ),
    );
  }

  playEndSound(CallEvent event) async {
    if (isInviter) {
      if (currentState.value != CallState.InCall) {
        if (event == CallEvent.CallOptReject ||
            event == CallEvent.CallReject ||
            event == CallEvent.CallCancel ||
            event == CallEvent.CallTimeOut) {
          await _methodChannel.invokeMethod("playEndSound");
        } else if (event == CallEvent.CallOptBusy ||
            event == CallEvent.CallBusy) {
          await _methodChannel.invokeMethod("playBusySound");
        }
      }
    } else {
      if (currentState.value != CallState.InCall) {
        if (event == CallEvent.CallOptReject ||
            event == CallEvent.CallReject ||
            event == CallEvent.CallOptCancel ||
            event == CallEvent.CallTimeOut ||
            event == CallEvent.CallOptEnd ||
            event == CallEvent.CallEnd) {
          await _methodChannel.invokeMethod("playEnd2Sound");
        }
      }
    }
  }

  updateUINetworkStatus(int status) {
    switch (status) {
      case 0:
        networkStatus.value = '';
        break;
      case 1:
        networkStatus.value = localized(callMeNetworkBad);
        break;
      case 2:
        networkStatus.value = localized(callOptNetworkBad);
        break;
    }
  }

  updateCallingNetwork(int remoteUid, int txQuality) {
    switch (txQuality) {
      case 5:
      case 6:
        networkStatus.value = localized(callMeNetworkBad);
        break;
      case 7:
      case 8:
        networkStatus.value = localized(callMeNetworkNonConn);
        break;
      default:
        networkStatus.value = '';
        break;
    }
  }

  updateInCallNetwork(int remoteUid, int txQuality, int rxQuality) {
    bool friendStreamOpen = true;
    bool selfStreamOpen = true;
    if (!_friendMuteSwitch) {
      friendStreamOpen = false;
    }
    if (!selfCameraOn.value && isMute.value) {
      selfStreamOpen = false;
    }
    int signalNetwork = -1;
    switch (txQuality) {
      case 1:
      case 2:
        signalNetwork = 4;
        break;
      case 3:
        signalNetwork = 3;
        break;
      case 4:
        signalNetwork = 2;
        break;
      case 5:
        signalNetwork = 1;
        break;
      case 6:
        signalNetwork = 0;
        break;
      case 0:
        int curTime = DateTime.now().millisecondsSinceEpoch;
        int diffDuration = (curTime - _friendOpenStreamTime) ~/ 1000;
        if (diffDuration < 5 || _friendOpenStreamTime == 0) {
          break;
        }
        if (remoteUid == 0) {
          if (selfStreamOpen) {
            signalNetwork = 0;
          }
        } else {
          if (friendStreamOpen) {
            signalNetwork = 0;
          }
        }
        break;
      default:
        break;
    }

    switch (rxQuality) {
      case 3:
        if (signalNetwork > 3) {
          signalNetwork = 3;
        }
        break;
      case 4:
        if (signalNetwork > 2) {
          signalNetwork = 2;
        }
        break;
      case 5:
        if (signalNetwork > 1) {
          signalNetwork = 1;
        }
        break;
      case 6:
        signalNetwork = 0;
        break;
      case 0:
        int curTime = DateTime.now().millisecondsSinceEpoch;
        int diffDuration = (curTime - _friendOpenStreamTime) ~/ 1000;
        if (diffDuration < 5 || _friendOpenStreamTime == 0) {
          break;
        }
        if (remoteUid == 0) {
          if (friendStreamOpen) {
            signalNetwork = 0;
          }
        } else {
          if (selfStreamOpen) {
            signalNetwork = 0;
          }
        }
        break;
      default:
        break;
    }

    if (signalNetwork == -1) {
      if (remoteUid == 0) {
        if (!selfStreamOpen) {
          selfNetworkQuality = 4;
        }
      } else {
        if (!friendStreamOpen) {
          friendNetworkQuality = 4;
        }
      }
    }

    /// 更新 UI 信号格
    if (signalNetwork != -1) {
      if (remoteUid == 0) {
        selfNetworkQuality = signalNetwork;
        if (selfNetworkQuality < 4) {
          updateUINetworkStatus(1);
        } else {
          updateUINetworkStatus(0);
        }
      } else {
        friendNetworkQuality = signalNetwork;
        if (friendNetworkQuality < 4) {
          updateUINetworkStatus(2);
        } else {
          updateUINetworkStatus(0);
        }
      }
      if (selfNetworkQuality < friendNetworkQuality) {
        agoraViewController?.updateSignalNetwork(selfNetworkQuality);
      } else {
        agoraViewController?.updateSignalNetwork(friendNetworkQuality);
      }
    }
  }

  updateUIEndCallStatus(CallEvent event) {
    var string = '';
    switch (event) {
      case CallEvent.CallInitFailed:
        string = localized(callInitFailed);
        break;
      case CallEvent.RequestFailed:
        string = localized(callRequestFailed);
        break;
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
        string = localized(callCancelled);
        break;
      case CallEvent.CallTimeOut:
        string = localized(callUnanswered);
        break;
      case CallEvent.CallBusy:
        string = localized(callBusyLater);
        break;
      case CallEvent.CallOptReject:
      case CallEvent.CallReject:
        string = localized(callRejectByOther);
        break;
      case CallEvent.CallOptEnd:
      case CallEvent.CallEnd:
        string = localized(chatEndedCall);
        break;
      case CallEvent.CallOptBusy:
        string = localized(callBusyFriend);
        break;
      case CallEvent.CallOtherDeviceReject:
        string = localized(callOtherDeviceReject);
        break;
      case CallEvent.CallOtherDeviceAccepted:
        string = localized(callOtherDeviceAccepted);
        break;
      case CallEvent.CallLogout:
        string = localized(callLogout);
        break;
      case CallEvent.CallKitErr:
        string = localized(chatEndedCall);
        break;
      default:
        break;
    }
    if (agoraViewController != null) {
      agoraViewController!.callStatusString.value = string;
    }
  }

  void toggleMic() {
    isMute.value = !isMute.value;
    _methodChannel.invokeMethod("toggleMic", {"isMute": isMute.value});
  }

  void switchOnOffCam() async {
    await requestFloatingPermission();

    selfCameraOn.value = !selfCameraOn.value;
    _methodChannel.invokeMethod(
      'muteLocalVideoStream',
      {
        "selfCameraOn": selfCameraOn.value,
        "hasBluetooth": isBluetooth.value,
      },
    );

    if (selfCameraOn.value) {
      isSpeaker.value = true;
      if (friendCameraOn.value) {
        if (floatWindowIsMe.value) {
          CallFloat().showAppFloatingWindow();
          // showTopFloating(true);
        }
        updateShowNativeVideo(true);
      } else {
        floatWindowIsMe.value = true;
        CallFloat().showAppFloatingWindow();
        // showTopFloating(true);
        updateShowNativeVideo(false);
        updateNativeFloatVal();
      }
    } else {
      if (friendCameraOn.value) {
        if (!floatWindowIsMe.value) {
          updateShowNativeVideo(false);
        }
      } else {
        if (!isMinimized.value) {
          CallFloat().closeAllFloat();
          showTopFloating(false);
          updateShowNativeVideo(false);
          floatWindowIsMe.value = true;
        }
      }

      Toast.showAgoraToast(
        msg: localized(mutedCamera),
        svg: 'assets/svgs/call_video_icon.svg',
      );
    }

    if (Platform.isIOS) {
      setAudioSound(isSpeaker.value ? SoundType.speaker : SoundType.reciever);
    }
  }

  updateShowNativeVideo(bool shouldShow, {bool updateButton = false}) {
    shouldShowNativeVideo.value = shouldShow;
    if (updateButton) {
      agoraViewController?.showButton(customize: !shouldShow);
    }
  }

  switchSpeaker() {
    engine?.setEnableSpeakerphone(!isSpeaker.value);
  }

  void flipCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    _methodChannel.invokeMethod("switchCamera");
  }

  /*
  * 1. iOSForeground 为false的时候防止从画中画切回到app的时候controller被销毁访问不到的情况，因为iOS在后端view没有被销毁
  * 2. 在app在前台的时候锁屏在CallKit挂断时在解锁会出现 !iOSForeground && !Get.isRegistered<AgoraCallController>() && Get.currentRoute == RouteName.agoraCallView 的情况，
  * 导致通话页面没有在挂断CallKit时关闭
  * */
  void popCallView(CallEvent event, {bool iOSForeground = true}) {
    if (event == CallEvent.CallTimeOut ||
        event == CallEvent.CallOptReject ||
        event == CallEvent.CallOptBusy ||
        event == CallEvent.CallInitFailed ||
        event == CallEvent.RequestFailed ||
        event == CallEvent.CallNetException ||
        event == CallEvent.CallException) {
      if (Get.isRegistered<AgoraCallController>() &&
          objectMgr.callMgr._chat != null) {
        Get.find<AgoraCallController>().enableTryMode(objectMgr.callMgr._chat);
      }
    } else {
      if (Get.isRegistered<AgoraCallController>()) {
        Get.find<AgoraCallController>().enableTryMode(null);
      }

      if ((mustPermissionDialogOpened && !isInviter) ||
          (Get.currentRoute == RouteName.agoraCallView &&
              !isLogout &&
              iOSForeground) ||
          (!iOSForeground &&
              !Get.isRegistered<AgoraCallController>() &&
              Get.currentRoute == RouteName.agoraCallView)) {
        Future.delayed(
            Duration(milliseconds: event == CallEvent.CallStart ? 0 : 1500),
            () {
          logMgr.logCallMgr.addMetrics(
            LogCallMsg(
              deviceId: _logId,
              type: MetricsMgr.METRICS_TYPE_CALL,
              msg:
                  "channel: $rtcChannelId OptPerm: $optPermissionExist popCallView -> event: $event, state:${currentState.value} version: ${appVersionUtils.currentAppVersion} at ${DateTime.now().millisecondsSinceEpoch}",
              mediaType: getLogCallInfoStr(),
            ),
          );
          if (optPermissionExist) {
            Get.back();
          }
          Get.back();
          agoraViewController?.onCallEnded();
        });
      }
    }

    if ((Get.currentRoute == RouteName.agoraCallView ||
            CallFloat().floatingManager.floatingSize() > 0) &&
        !isLogout) {
      CallFloat().closeAllFloat();
      showTopFloating(false);
    }
  }

  Future<void> updateServerStatus(CallEvent event, {int attempts = 0}) async {
    int status = ServerCallState.ended.status;
    switch (event) {
      case CallEvent.CallCancel:
        status = ServerCallState.cancelled.status;
        break;
      case CallEvent.CallTimeOut:
        status = ServerCallState.optNoRsp.status;
        break;
      case CallEvent.CallReject:
        status = ServerCallState.rejected.status;
        break;
      case CallEvent.CallAccepted:
        status = ServerCallState.answer.status;
        break;
      case CallEvent.CallEnd:
        status = ServerCallState.ended.status;
        break;
      case CallEvent.CallOptEnd:
        status = ServerCallState.optEnded.status;
        break;
      case CallEvent.CallOptBusy:
        status = ServerCallState.optBusy.status;
        break;
      default:
        return;
    }
    int duration = 0;
    if (_startInCallTime != 0) {
      duration = (_closeCallTime - _startInCallTime) ~/ 1000;
    }
    if (duration == 0 &&
        (event == CallEvent.CallEnd || event == CallEvent.CallOptEnd)) {
      duration = 1;
      duration = 1;
    }

    try {
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          type: MetricsMgr.METRICS_TYPE_CALL,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "updateServerStatus",
            state: currentState.value,
            event: event,
            opt: "Status: $status Duration: $duration",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );

      await updateCallStatus(rtcChannelId, status, duration);
    } catch (e) {
      pdebug(
        "UpdateCallStatus Failed ${e.toString()}, $rtcChannelId, $status, $duration",
      );
      logMgr.logCallMgr.addMetrics(
        LogCallMsg(
          deviceId: _logId,
          type: MetricsMgr.METRICS_TYPE_CALL,
          msg: CallLogInfo(
            channelId: rtcChannelId,
            method: "updateServerStatus",
            state: currentState.value,
            event: event,
            opt: "failed: ${e.toString()}",
          ).toString(),
          mediaType: getLogCallInfoStr(),
        ),
      );
    }
  }

  Future<void> updateCallLog(CallEvent event, User user) async {
    int duration = 0;
    if (_startInCallTime != 0) {
      duration = (_closeCallTime - _startInCallTime) ~/ 1000;
    }
    if (duration == 0 &&
        (event == CallEvent.CallEnd || event == CallEvent.CallOptEnd)) {
      duration = 1;
    }

    Call call = Call(
      channelId: rtcChannelId.isEmpty
          ? (_closeCallTime ~/ 1000).toString()
          : rtcChannelId,
      callerId: isInviter ? objectMgr.userMgr.mainUser.uid : user.uid,
      receiverId: isInviter ? user.uid : objectMgr.userMgr.mainUser.uid,
      chatId: _chat!.chat_id,
      duration: duration,
      createdAt:
          _startInitTime == 0 ? _closeCallTime ~/ 1000 : _startInitTime ~/ 1000,
      updatedAt: _closeCallTime ~/ 1000,
      endedAt: _closeCallTime ~/ 1000,
      status: event.index,
      isVideoCall: isVoiceCall ? 0 : 1,
    );

    if (Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().tabController!.index == 1) {
      call.isRead = 1;
    } else {
      if (objectMgr.callLogMgr.isMissCallLog(call)) {
        call.isRead = 0;
        Get.find<HomeController>().missedCallCount.value++;
      } else {
        call.isRead = 1;
      }
    }

    objectMgr.callLogMgr.saveCallLog("Local-UpdateCallLog", [call]);
  }

  isBluetoothConnected() async {
    final isConnected =
        await _methodChannel.invokeMethod("isBluetoothConnected");
    return isConnected;
  }

  @override
  Future<void> logout() async {
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
    isLogout = true;
    completedCalls.clear();
    handleEvent(CallEvent.CallLogout);
  }

  Future<int> startVoIpService(Chat chat) async {
    final result = await _methodChannel
        .invokeMethod('startVoIPService', {"chatId": chat.id.toString()});
    return result;
  }

  Future<int> get stopVoIpService async {
    final result = await _methodChannel.invokeMethod('stopVoIPService');
    return result;
  }

  void addChannelID(List<String> channelIDList) async {
    pdebug("................................$channelIDList");
    if (Platform.isIOS) {
      await _methodChannel.invokeMethod('addChannelID', channelIDList);
    }
  }

  Future<bool> checkPermission() async {
    var statusCam = await Permission.camera.status;
    var statusMic = await Permission.microphone.status;

    if (!(statusCam.isGranted && statusMic.isGranted)) {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> requestPermission() async {
    var statusCam = await Permission.camera.status;
    var statusMic = await Permission.microphone.status;

    if (statusCam.isDenied) {
      statusCam = await Permission.camera.request();
    }

    if (statusMic.isDenied) {
      statusMic = await Permission.microphone.request();
    }

    var accessDetail = "";
    if (!statusCam.isGranted) {
      accessDetail = localized(callAccessCamera);
    }
    if (!statusMic.isGranted) {
      accessDetail = localized(callAccessMic);
    }
    if (!statusCam.isGranted && !statusMic.isGranted) {
      accessDetail = localized(callAccessDetail);
    }

    if (!(statusCam.isGranted && statusMic.isGranted)) {
      mustPermissionDialogOpened = true;
      showModalBottomSheet(
        context: Get.context!,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title: localized(callAccessNeeded),
            subTitle: accessDetail,
            confirmButtonText: localized(goToSettings),
            cancelButtonText: localized(discardButton),
            confirmCallback: () => openAppSettings(),
            cancelCallback: () => Navigator.of(context).pop(),
          );
        },
      ).then((value) => mustPermissionDialogOpened = false);
      return false;
    } else {
      return true;
    }
  }

  requestFloatingPermission() async {
    if (Platform.isAndroid) {
      var result = await _methodChannel.invokeMethod("hasOverlayPermission");
      if (!result && !optPermissionExist) {
        optPermissionExist = true;
        showModalBottomSheet(
          context: Get.context!,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          builder: (BuildContext context) {
            return CustomConfirmationPopup(
              title: localized(callAccessNeeded),
              subTitle: localized(enableFloatingDialog),
              confirmButtonText: localized(goToSettings),
              cancelButtonText: localized(discardButton),
              confirmCallback: () async {
                _methodChannel.invokeMethod("requestOverlayPermission");
              },
              cancelCallback: () {
                Navigator.pop(context);
              },
            );
          },
        ).then((value) {
          optPermissionExist = false;
        });
      }
    }
  }

  Future<void> updateCallLogDatabase(List<Call> callLogs) async {
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBCallLog.tableName,
        callLogs.map((e) => e.toJson()).toList(),
      ),
      notify: false,
    );
  }

  bool getMissedStatus(Call callItem) {
    final bool isMe = objectMgr.userMgr.isMe(callItem.callerId);
    final int status = callItem.status;

    return !isMe &&
        (status == CallEvent.CallTimeOut.event ||
            status == CallEvent.CallBusy.event ||
            status == CallEvent.CallOptCancel.event ||
            status == CallEvent.CallReject.event);
  }

  String getCallStatusBrief({CallEvent? callEvent}) {
    switch (currentState.value) {
      case CallState.Init:
        return localized(initingAgora);
      case CallState.Requesting:
        return localized(requesting);
      case CallState.Waiting:
        if (isInviter) {
          return localized(waitingForAnswer);
        } else {
          return localized(incomingCallAgora);
        }
      case CallState.Ringing:
        return localized(ringing);
      case CallState.Connecting:
        return localized(connecting);
      case CallState.Idle:
        if (callEvent == null) {
          return "";
        }

        if (callEvent == CallEvent.CallOptEnd) {
          agoraViewController?.isEnding.value = true;
          return localized(chatEndedCall);
        } else if (callEvent == CallEvent.CallEnd) {
          agoraViewController?.isEnding.value = true;
          return localized(chatEndedCall);
        } else if (callEvent == CallEvent.CallOptBusy) {
          agoraViewController?.isEnding.value = true;
          return localized(callBusyFriend);
        } else if (callEvent == CallEvent.CallOptCancel) {
          agoraViewController?.isEnding.value = true;
          return localized(callCancelByOther);
        } else if (callEvent == CallEvent.CallCancel) {
          agoraViewController?.isEnding.value = true;
          return localized(callCancelled);
        } else if (callEvent == CallEvent.CallOptReject) {
          agoraViewController?.isEnding.value = true;
          return localized(callRejectByOther);
        } else if (callEvent == CallEvent.CallTimeOut) {
          agoraViewController?.isEnding.value = true;
          return localized(callTimeout);
        } else if (callEvent == CallEvent.CallBusy) {
          agoraViewController?.isEnding.value = true;
          return localized(callBusyLater);
        } else if (callEvent == CallEvent.CallNetException ||
            callEvent == CallEvent.CallInitFailed ||
            callEvent == CallEvent.RequestFailed ||
            callEvent == CallEvent.RequestFailed) {
          agoraViewController?.isEnding.value = true;
          return localized(callRequestFailed);
        }
        return "";
      default:
        return "";
    }
  }

  // 设置
  Future<bool> setAudioSound(SoundType type) async {
    return await _methodChannel
        .invokeMethod('toggleAudioRoute', {"device": type.value});
  }

  Future<bool> setAudioSoundForVoice(SoundType type) async {
    if (Platform.isIOS) {
      return await _methodChannel
          .invokeMethod('toggleAudioRouteForVoice', {"device": type.value});
    } else {
      return await _methodChannel
          .invokeMethod('toggleAudioRoute', {"device": type.value});
    }
  }

  void _changeCurrentCallStateValue(CallState state) {
    currentState.value = state;
    if (isTopFloatingWorking()) {
      ConnectionStatus status = currentState.value == CallState.InCall
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
      _callTopFloating.update(status);

      if (state == CallState.Idle) {
        showTopFloating(false);
      }

      if (Platform.isIOS &&
          state == CallState.InCall &&
          isTopFloatingWorking()) {
        if (isInviter) {
          outgoingCallConnected();
        } else {
          acceptCallKit();
        }
      }
    }
  }

  /// 是否展示顶部的水波纹UI
  /// 参数：
  /// * [show] - 是否展示顶部的水波纹UI。
  /// * [goingDown] - 展示水波纹的时候，整体ui会往下移动，不展示的时候，整体会向上移动，但是如果这里有值，就以这个为准。
  void showTopFloating(bool show, {bool? goingDown}) {
    if (!isTopFloatingWorking()) {
      return;
    }
    if (goingDown != null) {
      topFloatingOffsetY = goingDown ? 25.0 : 0.0;
      event(this, CallMgr.eventTopFloating, data: topFloatingOffsetY);
    } else {
      topFloatingOffsetY = show ? 25.0 : 0.0;
      event(this, CallMgr.eventTopFloating, data: topFloatingOffsetY);
    }
    if (show) {
      _callTopFloating.show(navigatorKey.currentContext!,
          title: opponent?.nickname ?? "",
          status: currentState.value == CallState.InCall
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected, onTap: () {
        floatingWindowOnTap();
      });
    } else {
      _callTopFloating.hide();
    }
  }

  /// 顶部的水波纹是否起作用，目前只支持iOS
  bool isTopFloatingWorking() {
    return false;
  }
}
