import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cbb_video_player/cbb_video_event_dispatcher.dart';
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
import 'package:jxim_client/im/media_detail/media_detail_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/agora/agora_call_answer.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/call_float.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:soundpool/soundpool.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../api/account.dart';
import '../data/db_call_log.dart';
import '../data/db_interface.dart';
import '../data/shared_remote_db.dart';
import '../home/home_controller.dart';
import '../im/custom_input/custom_input_controller.dart';
import '../object/call.dart';
import '../object/chat/chat.dart';
import '../object/device_list_model.dart';
import '../routes.dart';
import '../utils/net/update_block_bean.dart';
import '../views/agora/video_dimensions_model.dart';
import '../views/call_log/call_log_controller.dart';

enum CallState { Idle, Init, Connecting, Waiting, Ringing, InCall }

enum CallEvent {
  CallStart(0) /*拨打*/,
  CallInited(1) /*初始化完成*/,
  CallInitFailed(2) /*初始化失败*/,
  CallConnected(3) /*连接完成*/,
  CallConnectFailed(4) /*连接失败*/,
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
  CallNoPermisson(22) /*没有权限，初始化失败*/;

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

class CallMgr
    with EventDispatcher
    implements MgrInterface, SqfliteMgrInterface {
  RtcEngine? engine;
  late DBInterface _localDB;
  late SharedRemoteDB _sharedDB;
  static const _rtcChannel = 'jxim/rtc';
  final String socketCallLog = "video_call";
  final String socketCallNotification = "notification_setting";
  final String eventCallLogUpdate = "eventCallLogUpdate";
  static const eventIncomingCall = "eventIncomingCall";
  static var _methodChannel = const MethodChannel(_rtcChannel);
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
  String rtcChannelId = "";
  bool isVoiceCall = false;
  bool _friendCameraSwitch = false;
  bool _friendMuteSwitch = true;
  int resolution = 15;
  int fps = 30;

  /*对方摄像头是否打开*/
  Call? callItem;
  Chat? _chat;
  User? opponent;
  BuildContext? context;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
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

  // Call log 相关
  List<Call> callLog = [];
  int busyOptID = 0;
  int busyChatID = 0;
  int busyIsVideo = 0;

  @override
  Future<void> register() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;
    registerSqflite();
  }

  @override
  Future<void> init() async {
    _methodChannel.setMethodCallHandler(nativeCallback);
    if (Platform.isIOS) {
      await _methodChannel.invokeMethod("registerPushKit");
    }
  }

  @override
  Future<void> reloadData() async {
    isLogout = false;
    if (voipEnabled) {
      checkIncomingCall();
    }

    if (Get.isRegistered<CallLogController>()) {
      final CallLogController logController = Get.find<CallLogController>();
      logController.getRemoteCallLog();
    }
  }

  @override
  Future<void> registerSqflite() async {
    _localDB.registerTable('''
        CREATE TABLE IF NOT EXISTS call_log (
        id TEXT PRIMARY KEY,
        caller_id INTEGER,
        receiver_id INTEGER,
        chat_id INTEGER,
        duration INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        ended_at INTEGER,
        status INTEGER,
        is_deleted INTEGER,
        deleted_at INTEGER,
        is_read INTEGER
        );
      ''');
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

  Future<void> checkIncomingCall() async {
    if (currentState.value != CallState.Idle) {
      return;
    }
    final res = await getCallInviteList();
    if (!res.success()) {
      return;
    }
    final inviteList = res.data
        .map<CallInviteList>((e) => CallInviteList.fromJson(e))
        .toList();
    for (final CallInviteList inviteItem in inviteList) {
      if (!objectMgr.userMgr.isMe(inviteItem.inviterId!)) {
        _chat = await getChat(inviteItem.chatId!);
        if (_chat != null) {
          opponent = await getUser();
          if (opponent != null) {
            isVoiceCall = inviteItem.isVideoCall == 0;
            selfCameraOn.value = !isVoiceCall;
            rtcChannelId = inviteItem.channelId!;
            addChannelID([rtcChannelId]);
            handleEvent(CallEvent.CallInComing);
          } else {
            handleEvent(CallEvent.CallConnectFailed);
            closeCall(CallEvent.CallConnectFailed);
          }
        } else {
          Toast.showToast('call unable to get chat');
          handleEvent(CallEvent.CallConnectFailed);
          closeCall(CallEvent.CallConnectFailed);
        }
        break;
      }
    }
  }

  getChat(int chatID) async {
    Chat? chat = objectMgr.chatMgr.getChatById(chatID);
    if (chat == null) {
      chat = await objectMgr.chatMgr.loadRemoteChatByChatID(chatID);
    }
    return chat;
  }

  getUser() async {
    User? user = objectMgr.userMgr.getUserById(_chat!.friend_id);
    if (user == null) {
      user = await objectMgr.userMgr.getRemoteUser(_chat!.friend_id);
    }
    return user;
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      if (Platform.isAndroid) {
        _methodChannel.invokeMethod("stopVoIPService");
      }else if(Platform.isIOS){
        //防止在画中画时结束通话，页面没有关闭的情况，但这个逻辑最好做在popCallView里面
        if(Get.currentRoute == RouteName.agoraCallView && Get.isRegistered<AgoraCallController>() && objectMgr.callMgr.currentState.value == CallState.Idle){
          Get.back();
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      if (Platform.isAndroid && currentState.value == CallState.InCall) {
        _methodChannel.invokeMethod(
            "startVoIPService", {"chatId": _chat!.chat_id.toString()});
      }
    }
  }

  floatingWindowOnTap({bool isBack = false}) {
    if (isMinimized.value) {

      if (!isBack) {
        floatWindowIsMe.value = keepState["floatWindowIsMe"] ?? false;
        Get.toNamed(RouteName.agoraCallView, arguments: [
          objectMgr.callMgr.opponent,
        ]);

        if (!selfCameraOn.value && !friendCameraOn.value || currentState.value != CallState.InCall) {
          CallFloat().floatingManager.closeAllFloating();
        }
      }else{
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
      updateShowNativeVideo(objectMgr.callMgr.friendCameraOn.value,
          updateButton: objectMgr.callMgr.friendCameraOn.value == false);
    } else if (!objectMgr.callMgr.floatWindowIsMe.value) {
      updateShowNativeVideo(objectMgr.callMgr.selfCameraOn.value, updateButton: objectMgr.callMgr.selfCameraOn.value == false);
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
      case CallState.Connecting:
        _handleEventConnectingState(event);
        break;
      case CallState.Waiting:
        _handleEventWaitingState(event);
        break;
      case CallState.Ringing:
        _handleEventRingingState(event);
        break;
      case CallState.InCall:
        pdebug("Call handleEvent event:1 $event prestate:$preCallState  state:${currentState.value}");
        _handleEventInCallState(event);
        break;
    }

    pdebug("Call handleEvent event:2 $event prestate:$preCallState  state:${currentState.value}");
    if (preCallState != currentState.value) {
      if (agoraViewController != null) {
        agoraViewController!.updateCallStatusString();
      }
    }
  }

  /// 需要知道当前呼叫状态变化
  _setCurrentCallStateValue(CallState state) {
    currentState.value = state;
    // print("Call _currentCallStateDidChange state:${state}");
    if(Platform.isAndroid) return; //android这里报错
    if (state == CallState.Idle) {
      SoundMode.iosPlayMp3();
    }else{
      SoundMode.iosPauseMp3();
    }
  }

  Future<void> _handleEventIdleState(CallEvent event) async {
    switch (event) {
      case CallEvent.CallStart:
        _setCurrentCallStateValue(CallState.Init);
        isInviter = true;
        initCall();
        break;
      case CallEvent.CallInComing:
        _setCurrentCallStateValue(CallState.Init);
        isInviter = false;
        initCall();
        break;
      case CallEvent.CallNoPermisson:
        _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      default:
        pdebug('State:Idle illegal event:${event}');
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
      _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallInited:
        _setCurrentCallStateValue(CallState.Connecting);
        requestToken();
        break;
      default:
        pdebug('State:Init illegal event:${event}');
        break;
    }
  }

  void _handleEventConnectingState(CallEvent event) {
    switch (event) {
      case CallEvent.CallAccepted:
        //此时还未连接完成，等待重试
        Future.delayed(const Duration(milliseconds: 100), () {
          handleEvent(event);
        });
        break;
      case CallEvent.CallReject:
      case CallEvent.CallLogout:
      case CallEvent.CallConnectFailed:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallBusy:
      case CallEvent.CallOptBusy:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.CallNoPermisson:
      _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallConnected:
        _setCurrentCallStateValue(CallState.Waiting);
        break;
      default:
        pdebug('State:Connecting illegal event:${event}');
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
      case CallEvent.CallConnectFailed:
      case CallEvent.CallNoPermisson:
      _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallRinging:
        _setCurrentCallStateValue(CallState.Ringing);
        break;
      case CallEvent.CallOptAccepted:
      case CallEvent.CallAccepted:
      _setCurrentCallStateValue(CallState.InCall);
        resetNotification();
        unsetCallTimeOut();
        startInCallTimer();
        if (!isInviter) joinChannel();
        updateServerStatus(event);
        if (!isVoiceCall) {
          CallFloat().showAppFloatingWindow();
          floatingWindowOnTap();
        }
        break;
      default:
        pdebug('State:Waiting illegal event:${event}');
        break;
    }
  }

  void _handleEventRingingState(CallEvent event) {
    switch (event) {
      case CallEvent.CallLogout:
      case CallEvent.CallTimeOut:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallOptReject:
      case CallEvent.CallReject:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.CallConnectFailed:
      case CallEvent.CallNoPermisson:
      _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallOptAccepted:
      case CallEvent.CallAccepted:
      _setCurrentCallStateValue(CallState.InCall);
        resetNotification();
        unsetCallTimeOut();
        startInCallTimer();
        if (!isInviter) joinChannel();
        updateServerStatus(event);
        if (!isVoiceCall) {
          CallFloat().showAppFloatingWindow();
          floatingWindowOnTap();
        }
        break;
      default:
        pdebug('State:Ringing illegal event:${event}');
        break;
    }
  }

  void _handleEventInCallState(CallEvent event) {
    switch (event) {
      case CallEvent.CallLogout:
      case CallEvent.CallEnd:
      case CallEvent.CallOptEnd:
      case CallEvent.CallConnectFailed:
      _setCurrentCallStateValue(CallState.Idle);
        closeCall(event);
        break;
      case CallEvent.CallBusy:
        updateCallLog(event, opponent!);
        break;
      default:
        pdebug('State:InCall illegal event:${event}');
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
      if (user.relationship != Relationship.friend) {
        Toast.showToast(localized(callNotFriend));
        return false;
      } else {
        return true;
      }
    }
    return false;
  }

  Future<void> initCall() async {
    // 通话时限制不支持横屏
    isInitLandscape = MediaQuery.of(Routes.navigatorKey.currentContext!).orientation == Orientation.landscape;
    if(isInitLandscape){
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }

    CallFloat().closeAllFloat();
    if (isInviter) {
      if (await requestPermission() == false) {
        handleEvent(CallEvent.CallNoPermisson);
        return;
      }
    }
    resetNotification();
    if (isInviter) {
      Get.toNamed(RouteName.agoraCallView);
      toggleProximity();
    } else if (currentState.value == CallState.Init) {
      Get.lazyPut(() => AgoraCallController());
      if (!isCallKit) {
        event(this, eventIncomingCall);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        if(isInitLandscape && Platform.isIOS){
          await Future.delayed(const Duration(milliseconds: 300));
        }
        InAppNotification.show(
            child: AgoraCallAnswer(_chat!.friend_id),
            context: Get.context!,
            duration: const Duration(seconds: 4294967296));
      }
    }
    _startInitTime = DateTime.now().millisecondsSinceEpoch;
    if (Platform.isAndroid) {
      await requestAudio;
    }
    if (!isInviter) {
      requestPermission();
    }
    WakelockPlus.enable();
    setCallTimeOut();

    initAgoraEngine();
    if (!isInviter) {
      // prevent agora cut off notification sound
      restoreAudioCategory();
      objectMgr.pushMgr.showIncomingCallNotification(_chat!, rtcChannelId);
    }
  }

  restoreAudioCategory() {
    if(Platform.isIOS){
      _methodChannel.invokeMethod('restoreAudioCategory');
    }
  }

  Future<void> initAgoraEngine() async {
    try {
      _methodChannel.invokeMethod(
        'setupAgoraEngine',
        {
          "appID": Config().agoraAppID,
          "isVoiceCall": isVoiceCall,
          "fps": fps,
          "width": VideoDimensionsModel.getVideoWidth(resolution),
          "height": VideoDimensionsModel.getVideoHeight(resolution),
          "uid": opponent?.uid,
          "avatarUrl": opponent != null && notBlank(opponent?.profilePicture) ? "${serversUriMgr.download2Uri}/${opponent?.profilePicture}" : "",
          "nickname": objectMgr.userMgr.getUserTitle(opponent),
          "isInviter": isInviter
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
    pdebug("onUserJoined=======> ${objectMgr.userMgr.isMe(uid)}");
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
        updateNativeFloatVal();
      }

    } else {
      if (selfCameraOn.value) {
        if (floatWindowIsMe.value) {
          updateShowNativeVideo(false, updateButton: true);
        }
      } else {
        // 小窗模式需要切换浮窗
        if (isMinimized.value) {
          CallFloat().showAppFloatingWindow();
        } else {
          CallFloat().closeAllFloat();
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
    });
  }

  void requestToken() {
    getRTCToken(_chat!.chat_id, isVoiceCall ? 0 : 1,
            recipientIds: isInviter ? [_chat!.friend_id] : [],
            channel_id: isInviter ? null : rtcChannelId)
        .then((value) => handleRTCResponse(value, _chat))
        .onError((error, stackTrace) {
      if (error is CodeException && error.getPrefix() == 20504) {
        handleEvent(CallEvent.CallOptBusy);
      } else if (error is CodeException && error.getPrefix() == 20505) {
        handleEvent(CallEvent.CallConnectFailed);
      } else if (error is CodeException && error.getPrefix() == 20509) {
        handleEvent(CallEvent.CallBusy);
      } else {
        handleEvent(CallEvent.CallConnectFailed);
      }
    });
  }

  Future<void> handleRTCResponse(res, chat) async {
    if (res.success()) {
      final rtcToken = CallRtcToken.fromJson(res.data);
      _rtcToken = rtcToken.rtcToken;
      rtcChannelId = rtcToken.rtcChannelId!;
      if (isInviter) {
        await joinChannel();
      } else {
        handleEvent(CallEvent.CallConnected);
      }
    } else {
      handleEvent(CallEvent.CallConnectFailed);
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

  void doCallChange(UpdateBlockBean block) {
    if (block.opt != blockOptReplace) {
      return;
    }
    final Map<String, dynamic> callMap = json.decode(block.data[0]["message"]);
    callItem = Call.fromJson(callMap);
    if (objectMgr.userMgr.isMe(callItem!.callerId)) {
      /// 我是拨打方
      if (callItem!.status == ServerCallState.optRejected.status) {
        handleEvent(CallEvent.CallOptReject);
      } else if (callItem!.status == ServerCallState.ringing.status) {
        handleEvent(CallEvent.CallRinging);
      } else if (callItem!.status == ServerCallState.optEnded.status) {
        handleEvent(CallEvent.CallOptEnd);
      }
    } else {
      /// 我是接听方
      if (callItem!.status == ServerCallState.waiting.status) {
        if (currentState.value != CallState.Idle) {
          return;
        }
        if (!voipEnabled) {
          return;
        }
        if (Platform.isIOS && _appLifecycleState == AppLifecycleState.resumed) {
          addChannelID([callItem!.channelId]);
        }
        isVoiceCall = callItem!.isVideoCall == 0;
        selfCameraOn.value = callItem!.isVideoCall == 1;
        rtcChannelId = callItem!.channelId;
        opponent = objectMgr.userMgr.getUserById(callItem!.callerId);
        _chat = objectMgr.chatMgr.getChatById(callItem!.chatId);
        handleEvent(CallEvent.CallInComing);
      } else if (callItem!.status == ServerCallState.optCancelled.status) {
        handleEvent(CallEvent.CallOptCancel);
      } else if (callItem!.status == ServerCallState.noRsp.status) {
        handleEvent(CallEvent.CallTimeOut);
      } else if (callItem!.status == ServerCallState.busy.status) {
        busyOptID = callItem!.callerId;
        busyChatID = callItem!.chatId;
        busyIsVideo = callItem!.isVideoCall;
        handleEvent(CallEvent.CallBusy);
      } else if (callItem!.status == ServerCallState.optRejected.status) {
        handleEvent(CallEvent.CallOtherDeviceReject);
      } else if (callItem!.status == ServerCallState.answer.status) {
        handleEvent(CallEvent.CallOtherDeviceAccepted);
      } else if (callItem!.status == ServerCallState.optEnded.status) {
        handleEvent(CallEvent.CallOptEnd);
      }
    }
  }

  Future<void> nativeCallback(MethodCall call) async {
    objectMgr.pushMgr.stopVibrate();
    objectMgr.pushMgr.clearNotification();
    objectMgr.pushMgr.cancelLocalNotification();
    pdebug(
        "CallsMgr: native callback: ${call.method} | ${call.arguments} | ${currentState}");

    switch (call.method) {
      case 'pushKitToken':
        await PushNotificationServices().registerPushDevice(
            registrationId: call.arguments, platform: 2, source: 2);
        break;
      case 'callInited':
        handleEvent(CallEvent.CallInited);
        break;
      case 'CallInitFailed':
        handleEvent(CallEvent.CallInitFailed);
        break;
      case 'joinChannelSuccess':
        handleEvent(CallEvent.CallConnected);
        break;
      case 'acceptCall':
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
        rejectCall();
        break;
      case 'hangupCall':
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
        _chat = await objectMgr.chatMgr.getChatById(chatID);
        opponent = objectMgr.userMgr.getUserById(_chat!.friend_id);
        rtcChannelId = data['rtc_channel_id'];
        handleEvent(CallEvent.CallInComing);
        break;
      case 'callKitError':
        _setCurrentCallStateValue(CallState.Idle);
        Map data = call.arguments;
        if (data["isCancel"]) {
          closeCall(CallEvent.CallOptCancel);
        } else {
          closeCall(CallEvent.CallKitErr);
        }
        break;
      case 'audioGain':
        break;
      case 'startCallIOS':
        int chatID = int.parse(call.arguments);
        Chat? chat = await objectMgr.chatMgr.getChatById(chatID);
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
        break;
      case "CallOptEnd":
        handleEvent(CallEvent.CallOptEnd);
        break;
      case "onNetworkQuality":
        if (currentState.value != CallState.InCall) {
          return;
        }
        Map data = call.arguments;
        if (data["uid"] != null) {
          updateNetwork(data["uid"], data["txQuality"], data["rxQuality"]);
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
      default:
        break;
    }
  }

  void resetNotification() {
    objectMgr.pushMgr.stopVibrate();
    objectMgr.pushMgr.clearNotification();
    objectMgr.pushMgr.cancelLocalNotification();
    objectMgr.pushMgr.cancelAllNotification();
    if (Platform.isAndroid) {
      objectMgr.pushMgr.stopCall();
    }
  }

  void setCallTimeOut() {
    if (_callTimeOut != null) {
      _callTimeOut!.cancel();
    }
    _callTimeOut = Timer(const Duration(seconds: 30), () {
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
      int curTime = DateTime.now().millisecondsSinceEpoch;
      int diffDuration = (curTime - _startInCallTime) ~/ 1000;
      if (agoraViewController != null) {
        agoraViewController!
            .updateCallDuration(constructTimeVerbose(diffDuration));
      }
      if (_appLifecycleState != AppLifecycleState.resumed) {
        objectMgr.scheduleMgr.heartBeat.execute();
      }
    });
  }

  void endInCallTimer() {
    if (_inCallTimer != null) {
      _inCallTimer!.cancel();
    }
  }

  void startCall(Chat chat, bool isVoiceCall) {
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
    toggleProximity();
    CBBVideoEvents.instance.onPause();
    handleEvent(CallEvent.CallAccepted);
  }

  void rejectCall() {
    handleEvent(CallEvent.CallReject);
  }

  void endCall() {
    handleEvent(CallEvent.CallEnd);
  }

  Future<void> toggleProximity() async =>
      await _methodChannel.invokeMethod('toggleProximity');

  Future<void> cancelCallKit() async =>
      await _methodChannel.invokeMethod('cancelCallKitCall', {
        'rtc_channel_id': rtcChannelId,
        'chat_id': _chat!.chat_id,
        'video_call': isVoiceCall == 0 ? 1 : 0,
      });

  Future<void> acceptCallKit() async =>
      await _methodChannel.invokeMethod('acceptCallKit', {
        'rtc_channel_id': rtcChannelId,
        'chat_id': _chat!.chat_id,
        'video_call': isVoiceCall == 0 ? 1 : 0,
      });

  Future<void> releaseAgoraEngine() async {
    await _methodChannel.invokeMethod("releaseEngine");
  }

  onExitCallView({bool isExit = true}) {
    _methodChannel.invokeMethod("callViewDismiss", {"isExit": isExit});
  }

  //注：聊天室内的气泡，客户端不再发送，统一有服务器发送
  void closeCall(CallEvent event) async {
    isCallKit = false;
    bool isIOSForeground = true;
    shouldShowNativeVideo.value = false;
    if (Platform.isIOS) {
      isIOSForeground = await _methodChannel.invokeMethod('isInForeground');
    }
    updateUIEndCallStatus(event);
    _closeCallTime = DateTime.now().millisecondsSinceEpoch;
    updateServerStatus(event);
    releaseAgoraEngine();
    if (Platform.isIOS) {
      cancelCallKit();
    } else {
      stopVoIpService;
      abandonAudio;
      _methodChannel.invokeMethod("closeFloatWindow");
    }
    firstLocalVideoFrameDone.value = false;
    if (opponent != null) {
      await updateCallLog(event, opponent!);
    }
    unsetCallTimeOut();
    endInCallTimer();
    resetNotification();
    popCallView(iOSForeground: isIOSForeground);
    closeAllPopUpMenu();
    rtcChannelId = "";
    _setCurrentCallStateValue(CallState.Idle);
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
    if (await WakelockPlus.enabled) {
      WakelockPlus.disable();
    }
    mustPermissionDialogOpened = false;
    InAppNotification.dismiss(context: Get.context!);

    //当观看视频的时候接听电话，结束通话的时候需要重制视频页面支持横屏
    if(isInitLandscape){
      isInitLandscape = false;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
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

  updateNetwork(int remoteUid, int txQuality, int rxQuality) {
    bool friendStreamOpen = true;
    bool selfStreamOpen = true;
    if (!_friendCameraSwitch && !_friendMuteSwitch) {
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
      case CallEvent.CallConnectFailed:
        string = localized(callConnectFailed);
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
        string = localized(declinedCall);
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
        string = localized(callCancelled);
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

  void toggleSpeaker() {
    isSpeaker.value = !isSpeaker.value;
    _methodChannel
        .invokeMethod("toggleSpeaker", {"isSpeaker": isSpeaker.value});
  }

  void switchOnOffCam() async {
    await requestFloatingPermission();

    selfCameraOn.value = !selfCameraOn.value;
    _methodChannel.invokeMethod(
      'muteLocalVideoStream',
      {"selfCameraOn": selfCameraOn.value},
    );

    if (selfCameraOn.value) {
      isSpeaker.value = true;
      if (friendCameraOn.value) {
        if (floatWindowIsMe.value) {
          CallFloat().showAppFloatingWindow();
        }
        updateShowNativeVideo(true);
      } else {
        floatWindowIsMe.value = true;
        CallFloat().showAppFloatingWindow();
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
          updateShowNativeVideo(false);
          floatWindowIsMe.value = true;
        }
      }

      Toast.showAgoraToast(
          msg: localized(mutedCamera), svg: 'assets/svgs/call_video_icon.svg');
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
  void popCallView({bool iOSForeground = true}) {
    if ((mustPermissionDialogOpened && !isInviter) ||
        (Get.currentRoute == RouteName.agoraCallView &&
            !isLogout &&
            iOSForeground) ||
        (!iOSForeground &&
            !Get.isRegistered<AgoraCallController>() &&
            Get.currentRoute == RouteName.agoraCallView)) {
      if (optPermissionExist) {
        Get.back();
      }
      Get.back();
    }

    if ((Get.currentRoute == RouteName.agoraCallView ||
            CallFloat().floatingManager.floatingSize() > 0) &&
        !isLogout) {
      CallFloat().closeAllFloat();
    }
  }

  Future<void> updateServerStatus(CallEvent event) async {
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
    try{
      await updateCallStatus(rtcChannelId, status, duration);   
    }catch(e){
      pdebug("UpdateCallStatus Failed ${e.toString()}, $rtcChannelId, $status, $duration");
    }
  }

  Future<void> updateCallLog(CallEvent event, User user) async {
    Call? currentCall;
    int duration = 0;
    // if (rtcChannelId != '' && await objectMgr.localDB.isExist(rtcChannelId)) {
    //   return;
    // }
    if (_startInCallTime != 0) {
      duration = (_closeCallTime - _startInCallTime) ~/ 1000;
    }
    if (duration == 0 &&
        (event == CallEvent.CallEnd || event == CallEvent.CallOptEnd)) {
      duration = 1;
      duration = 1;
    }
    int isRead = 0;
    if (event == CallEvent.CallCancel ||
        event == CallEvent.CallOptReject ||
        event == CallEvent.CallReject ||
        event == CallEvent.CallOptEnd ||
        event == CallEvent.CallOptBusy ||
        event == CallEvent.CallEnd ||
        event == CallEvent.CallOtherDeviceReject ||
        event == CallEvent.CallOtherDeviceAccepted) {
      isRead = 1;
    } else {
      if (event == CallEvent.CallTimeOut && isInviter) {
        isRead = 1;
      } else {
        Get.find<HomeController>().addMissedCallUnread(1);
      }
    }
    if (event == CallEvent.CallBusy) {
      currentCall = Call(
        channelId: (_closeCallTime ~/ 1000).toString(),
        callerId: busyOptID,
        receiverId: objectMgr.userMgr.mainUser.uid,
        chatId: busyChatID,
        duration: 0,
        createdAt: _closeCallTime ~/ 1000,
        updatedAt: _closeCallTime ~/ 1000,
        endedAt: _closeCallTime ~/ 1000,
        status: event.index,
        isRead: isRead,
        isVideoCall: busyIsVideo,
      );
    } else {
      currentCall = Call(
        channelId: rtcChannelId.isEmpty
            ? (_closeCallTime ~/ 1000).toString()
            : rtcChannelId,
        callerId: isInviter ? objectMgr.userMgr.mainUser.uid : user.uid,
        receiverId: isInviter ? user.uid : objectMgr.userMgr.mainUser.uid,
        chatId: _chat!.chat_id,
        duration: duration,
        createdAt: _startInitTime == 0
            ? _closeCallTime ~/ 1000
            : _startInitTime ~/ 1000,
        updatedAt: _closeCallTime ~/ 1000,
        endedAt: _closeCallTime ~/ 1000,
        status: event.index,
        isRead: isRead,
        isVideoCall: isVoiceCall ? 0 : 1,
      );
    }
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBCallLog.tableName,
        [currentCall.toJson()],
      ),
      notify: false,
    );
    updateAllLogs([currentCall]);
  }

  @override
  Future<void> logout() async {
    isLogout = true;
    handleEvent(CallEvent.CallLogout);
  }

  Future<int> get requestAudio async {
    final result = await _methodChannel.invokeMethod('requestAudioFocus');
    return result;
  }

  Future<int> get abandonAudio async {
    final result = await _methodChannel.invokeMethod('releaseAudioFocus');
    return result;
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

  /// Call log 通话记录
  Call get lastUpdatedCallLog {
    Call mostRecentCall = callLog.first;

    for (Call log in callLog) {
      if (log.createdAt > mostRecentCall.createdAt) {
        mostRecentCall = log;
      }
    }
    return mostRecentCall;
  }

  onCallLogChanged(List<Call> callLogs) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBCallLog.tableName,
        callLogs.map((e) => e.toJson()).toList(),
      ),
      notify: false,
    );
    updateAllLogs(callLogs);
  }

  updateAllLogs(List<Call> callLogs) {
    for (Call log in callLogs) {
      final int existingIndex =
          callLog.indexWhere((item) => item.channelId == log.channelId);
      if (existingIndex == -1) {
        callLog.add(log);
      } else {
        callLog[existingIndex] = log;
      }
    }
    callLogSort();
  }

  void callLogSort() {
    callLog.sort((a, b) {
      if (a.createdAt == 0)
        return -1;
      else if (b.createdAt == 0)
        return 1;
      else
        return b.createdAt - a.createdAt;
    });
    event(this, eventCallLogUpdate);
  }

  bool getMissedStatus(Call callItem) {
    final bool isMe = objectMgr.userMgr.isMe(callItem.callerId);
    final int status = callItem.status;

    return status == CallEvent.CallTimeOut.event && !isMe ||
        status == CallEvent.CallBusy.event && !isMe ||
        status == CallEvent.CallOptCancel.event && !isMe;
  }

  String getCallStatusBrief() {
    switch (currentState.value) {
      case CallState.Init:
        return localized(initingAgora);
      case CallState.Connecting:
        return localized(connecting);
      case CallState.Waiting:
        if (isInviter) {
          return localized(waitingForAnswer);
        } else {
         return localized(incomingCallAgora);
        }
      case CallState.Ringing:
        return localized(ringing);
      default:
        return "";
    }
  }
}
