import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/battery_helper.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/agora/call_float.dart';

class AgoraCallController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final alertThreshold = 10;
  bool visible = true;
  AnimationController? animationController;
  final callStatusString = ''.obs;
  final callTimeDuration = '00:00'.obs;
  final networkSignalIcon = 'assets/svgs/signal-4.svg'.obs;
  final isEnding = false.obs;
  BatteryInfo? batteryInfo;
  BatteryInfo? calleeBatteryInfo;
  final showMeBatteryAlert = false.obs;
  final showCalleeBatteryAlert = false.obs;
  final Rxn<RetryInfo?> retryInfo = Rxn<RetryInfo?>();

  // iOS拨打视频到Android接听时，触发Android第一帧对方画面会有一段时间的延迟，导致iOS画面会从音频头像类型转换到视频画面，影响体验
  final iosBeforeReceiveRemoteDelayPassed = (Platform.isIOS ? false : true).obs;

  @override
  onInit() {
    super.onInit();
    objectMgr.callMgr.agoraViewController = this;
    objectMgr.callMgr.closeAllPopUpMenu();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    updateCallStatusString();
    setupBatteryListener();
    objectMgr.callMgr.requestFloatingPermission();

    if (objectMgr.callMgr.currentState.value == CallState.InCall) {
      objectMgr.callMgr.updateCallTime();
    }

    if (objectMgr.callMgr.isCallKit) {
      getCurrentAudioRoute();
    }
  }

  void getCurrentAudioRoute() async {
    String result = await objectMgr.callMgr.getCurrentAudioRoute();
    objectMgr.callMgr.isSpeaker.value = result == "speaker";
  }

  void doFriendJoined() async {
    if (objectMgr.callMgr.isInviter && Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 700),
          () => iosBeforeReceiveRemoteDelayPassed.value = true);
    }
  }

  bool isInTryMode() {
    return retryInfo.value != null;
  }

  void enableTryMode(Chat? chat) {
    if (chat != null) {
      retryInfo.value =
          RetryInfo(chat, isVoiceCall: objectMgr.callMgr.isVoiceCall);
    } else {
      retryInfo.value = null;
    }
  }

  Future<void> doRetry() async {
    var mgr = objectMgr.callMgr;
    if (retryInfo.value == null) {
      return;
    }

    if (mgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCall));
      return;
    }

    try {
      bool isVoice = retryInfo.value?.isVoiceCall ?? false;
      if (retryInfo.value?.chat != null) {
        mgr.startCall(retryInfo.value!.chat, isVoice);
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }

    retryInfo.value?.accumulate();
  }

  void doClosePage() {
    Get.back();
    onCallEnded();
  }

  setupBatteryListener() async {
    BatteryHelper()
        .addBatteryListener(this, (state) => _onBatteryChanged(state));
    batteryInfo = await BatteryHelper().getCurrentBatteryInfo();
    calleeBatteryInfo = objectMgr.callMgr.keepState["calleeBatteryInfo"];
    if (batteryInfo != null || calleeBatteryInfo != null) {
      updateBatteryInfo(batteryInfo!);
    }
  }

  _onBatteryChanged(BatteryInfo info) {
    if (Get.isRegistered<AgoraCallController>()) {
      final controller = Get.find<AgoraCallController>();
      controller.updateBatteryInfo(info);
    }
  }

  onBackBtnClicked() {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      CallFloat().onMinimizeWindow();
      objectMgr.callMgr.showTopFloating(true);
    } else {
      onCallEnded();
      CallFloat().closeAllFloat();
      objectMgr.callMgr.showTopFloating(false);
    }
    Get.back();
  }

  @override
  void onClose() {
    super.onClose();
    callTimeDuration.value = '00:00';
    showMeBatteryAlert.value = false;
    showCalleeBatteryAlert.value = false;
    batteryInfo = null;
    calleeBatteryInfo = null;
    retryInfo.value = null;
    BatteryHelper().onClose();
    iosBeforeReceiveRemoteDelayPassed.value = Platform.isIOS ? false : true;
    enableTryMode(null);
  }

  updateBatteryInfo(BatteryInfo info) {
    if (objectMgr.userMgr.isMe(info.uid)) {
      batteryInfo = info;
      checkIfShowLowBatteryAlert();

      syncWithBackendLowBattery();
    } else {
      calleeBatteryInfo = info;
      checkIfShowLowBatteryAlert();
    }
  }

  checkIfShowLowBatteryAlert() {
    checkMe();
    checkCallee();
  }

  checkMe() {
    int level = batteryInfo?.level ?? 100;
    BatteryState state = batteryInfo?.state ?? BatteryState.unknown;
    if (level <= alertThreshold) {
      if (state == BatteryState.charging || state == BatteryState.full) {
        showMeBatteryAlert.value = false;
      } else {
        showMeBatteryAlert.value = true;
      }
    } else {
      showMeBatteryAlert.value = false;
    }
  }

  checkCallee() {
    int level = calleeBatteryInfo?.level ?? 100;
    BatteryState state = calleeBatteryInfo?.state ?? BatteryState.unknown;
    if (level <= alertThreshold) {
      if (state == BatteryState.charging || state == BatteryState.full) {
        showCalleeBatteryAlert.value = false;
      } else {
        showCalleeBatteryAlert.value = true;
      }
    } else {
      showCalleeBatteryAlert.value = false;
    }
  }

  String getBatteryBrief() {
    if (showCalleeBatteryAlert.value && !showMeBatteryAlert.value) {
      return localized(callOtherLowBattery);
    }
    return localized(callMeLowBattery);
  }

  syncWithBackendLowBattery() async {
    if (batteryInfo != null && notBlank(objectMgr.callMgr.rtcChannelId)) {
      final result =
          await getCallUpdate(objectMgr.callMgr.rtcChannelId, batteryInfo!);
      pdebug(
          "syncWithBackendLowBattery: $result, ${objectMgr.callMgr.rtcChannelId}, ${batteryInfo?.level}, ${batteryInfo?.state}");
    }
  }

  updateSignalNetwork(int level) {
    networkSignalIcon.value = 'assets/svgs/signal-$level.svg';
  }

  // 判断通话是否是正常接通后的挂断
  bool isInCallEnded() {
    return callStatusString.value == localized(chatEndedCall);
  }

  showButton({bool? customize, bool animate = true}) {
    if (!shouldShowCallingView() || customize != null) {
      if (customize != null) {
        visible = customize;
      }
      if (visible) {
        animationController?.reverse(from: animate ? null : 0.0);
      } else {
        animationController?.forward(from: animate ? null : 1.0);
      }
      visible = !visible;
    }
  }

  void updateCallStatusString({CallEvent? callEvent}) {
    callStatusString.value =
        objectMgr.callMgr.getCallStatusBrief(callEvent: callEvent);
  }

  String getStateDesc() {
    return objectMgr.callMgr.currentState.value == CallState.InCall
        ? callTimeDuration.value
        : callStatusString.value;
  }

  shouldShowCallingView() {
    pdebug("shouldShowCallingView====> ${objectMgr.callMgr.currentState}");
    if (objectMgr.callMgr.currentState.value != CallState.InCall) {
      if (objectMgr.callMgr.isInviter ||
          objectMgr.callMgr.currentState.value == CallState.Idle ||
          objectMgr.callMgr.currentState.value == CallState.Init) {
        return !objectMgr.callMgr.selfCameraOn.value &&
            !objectMgr.callMgr.friendCameraOn.value;
      } else {
        return objectMgr.callMgr.currentState.value == CallState.Waiting ||
            (objectMgr.callMgr.currentState.value == CallState.Connecting &&
                !objectMgr.callMgr.selfCameraOn.value);
      }
    }

    final bool mainViewShowVideo = (objectMgr.callMgr.floatWindowIsMe.value &&
            objectMgr.callMgr.firstRemoteVideoFrameDone.value &&
            objectMgr.callMgr.friendCameraOn.value) ||
        (!objectMgr.callMgr.floatWindowIsMe.value &&
            objectMgr.callMgr.firstLocalVideoFrameDone.value &&
            objectMgr.callMgr.selfCameraOn.value);

    bool realShowVideo = iosBeforeReceiveRemoteDelayPassed.value
        ? mainViewShowVideo
        : objectMgr.callMgr.firstLocalVideoFrameDone.value;

    return !objectMgr.callMgr.shouldShowNativeVideo.value ||
        !(objectMgr.callMgr.shouldShowNativeVideo.value && realShowVideo) ||
        (objectMgr.callMgr.iosCallInBackground.value &&
            objectMgr.callMgr.floatWindowIsMe.value &&
            !objectMgr.callMgr.isMinimized.value);
  }

  void updateCallDuration(String value) => callTimeDuration.value = value;

  onCallEnded() {
    isEnding.value = false;
  }

  String getNetworkBrief() {
    pdebug(
        "getNetworkBrief: ${objectMgr.appInitState.value}, ${objectMgr.callMgr.networkStatus.value}");
    if (objectMgr.appInitState.value == AppInitState.no_connect ||
        objectMgr.appInitState.value == AppInitState.connecting ||
        objectMgr.appInitState.value == AppInitState.kiwi_failed) {
      return localized(callMeNetworkVBad);
    } else {
      return objectMgr.callMgr.networkStatus.value;
    }
  }
}

class RetryInfo {
  final Chat chat;
  final bool isVoiceCall;
  int times = 0;

  RetryInfo(this.chat, {this.isVoiceCall = true});

  accumulate() {
    times = times + 1;
  }
}
