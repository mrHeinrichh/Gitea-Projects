
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/agora/native_video_widget.dart';
import '../../utils/lang_util.dart';
import '../../utils/theme/text_styles.dart';
import '../component/floating/assist/floating_slide_type.dart';
import '../component/floating/floating.dart';
import '../component/floating/manager/floating_manager.dart';
import '../component/custom_avatar.dart';

class CallFloat {
  final FloatingManager floatingManager = FloatingManager();

  Floating? getAudioFloat() {
    return floatingManager.getFloating('audio_view');
  }

  Floating? getVideoFloat() {
    return floatingManager.getFloating('video_view');
  }

  void onMinimizeWindow() {
    objectMgr.callMgr.isMinimized.value = true;
    showAppFloatingWindow();

    objectMgr.callMgr.keepState = {
      "floatWindowIsMe": objectMgr.callMgr.floatWindowIsMe.value
    };

    if(objectMgr.callMgr.friendCameraOn.value && objectMgr.callMgr.floatWindowIsMe.value){
      objectMgr.callMgr.floatingWindowOnTap(isBack: true);
    }

    objectMgr.callMgr.onExitCallView(isExit: true);
  }

  void showAppFloatingWindow(){
    if(floatingManager.getFloating('call_floating') == null) {
      Floating callFloating = floatingManager.createFloating(
        'call_floating',
        Floating(
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12), child: getFloatingContentView()),
          ),
          slideType: FloatingSlideType.onRightAndTop,
          isShowLog: false,
          isSnapToEdge: true,
          isPosCache: true,
          moveOpacity: 1.0,
          right: 0,
          top: 100,
          width: 120,
          height: 200,
          slideBottomHeight: 30,
        ),
      );
      callFloating.open(objectMgr.callMgr.context!);
    }
  }

  getFloatingContentView(){
    return Obx((){
      if(objectMgr.callMgr.isMinimized.value){
        if(objectMgr.callMgr.friendCameraOn.value){
          return getVideoView();
        }else{
          return Platform.isIOS ? Stack(
            children: [
              // 必须放这个view，因为需要在切画中画时候用来显示头像
              getVideoView(),
              getAudioView()
            ],
          ) : getAudioView();
        }
      }else{
        if(!objectMgr.callMgr.friendCameraOn.value && !objectMgr.callMgr.selfCameraOn.value){
          return getAudioView();
        }else if(objectMgr.callMgr.floatWindowIsMe.value && !objectMgr.callMgr.selfCameraOn.value){
          return getAudioView();
        }else if(!objectMgr.callMgr.floatWindowIsMe.value && !objectMgr.callMgr.friendCameraOn.value){
          return getAudioView();
        }
        return getVideoView();
      }
    });
  }

  Widget getVideoView() {
    var children = <Widget>[];

    children.add(NativeVideoWidget(
      uid: objectMgr.userMgr.mainUser.uid,
      isBigScreen: false,
    ));

    children.add(Positioned.fill(
      child: InkWell(
          onTap: () => objectMgr.callMgr.floatingWindowOnTap(),
          child: const SizedBox()),
    ));
    return Stack(
      children: children,
    );
  }

  Widget getAudioView(){
    return GestureDetector(
      onTap: () => objectMgr.callMgr.floatingWindowOnTap(),
      child: Container(
          height: 200,
          width: 120,
          padding: const EdgeInsets.only(left: 12, right: 12, top: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4C000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 8),
                spreadRadius: 6,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CustomAvatar(
                  uid: objectMgr.callMgr.floatWindowIsMe.value && !objectMgr.callMgr.isMinimized.value
                      ? objectMgr.userMgr.mainUser.uid
                      : objectMgr.callMgr.opponent!.uid,
                  size: 56),
              objectMgr.callMgr.currentState.value == CallState.Waiting ||
                  objectMgr.callMgr.currentState.value ==
                      CallState.Ringing
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(objectMgr.callMgr.getCallStatusBrief(),
                    style: jxTextStyle.textStyleBold12(
                        color: Colors.white),
                    textAlign: TextAlign.center,
                ),
              )
                  : const SizedBox(height: 20)
            ],
          )
      ),
    );
  }

  void closeAllFloat() {
    floatingManager.closeAllFloating();
  }
}
