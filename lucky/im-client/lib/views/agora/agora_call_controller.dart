import 'package:cbb_video_player/cbb_video_event_dispatcher.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/views/agora/call_float.dart';
import '../../main.dart';
import '../../utils/localization/app_localizations.dart';

class AgoraCallController extends GetxController with GetSingleTickerProviderStateMixin {
  bool isInviter = false;
  bool visible = true;
  AnimationController? animationController;
  final callStatusString = ''.obs;
  final callTimeDuration = ''.obs;
  final networkSignalIcon = 'assets/svgs/signal-4.svg'.obs;

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
    objectMgr.callMgr.requestFloatingPermission();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  onBackBtnClicked(){
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      CallFloat().onMinimizeWindow();
    } else {
      CallFloat().closeAllFloat();
    }
    Get.back();
  }

  @override
  void onClose() {
    super.onClose();
    if(CBBVideoEvents.instance.activeController != null){
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  updateSignalNetwork(int level) {
    networkSignalIcon.value = 'assets/svgs/signal-$level.svg';
  }

  showButton({bool? customize}) {
    if (objectMgr.callMgr.shouldShowNativeVideo.value || customize != null) {
      if (customize != null) {
        visible = customize;
      }
      if (visible) {
        animationController?.reverse();
      } else {
        animationController?.forward();
      }
      visible = !visible;
    }
  }

  void updateCallStatusString() {
    callStatusString.value = objectMgr.callMgr.getCallStatusBrief();
  }

  shouldShowCallingView(){
    if(objectMgr.callMgr.currentState.value != CallState.InCall){
      return !objectMgr.callMgr.selfCameraOn.value && !objectMgr.callMgr.friendCameraOn.value;
    }
    return !objectMgr.callMgr.shouldShowNativeVideo.value
        || !(objectMgr.callMgr.shouldShowNativeVideo.value && objectMgr.callMgr.firstLocalVideoFrameDone.value);
  }

  void updateCallDuration(String value) => callTimeDuration.value = value;
}
