import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/native_video_widget.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/floating/assist/floating_slide_type.dart';
import 'package:jxim_client/views/component/floating/floating.dart';
import 'package:jxim_client/views/component/floating/manager/floating_manager.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:lottie/lottie.dart';

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
    if(objectMgr.callMgr.isTopFloatingWorking()) {
      if(objectMgr.callMgr.selfCameraOn.value || objectMgr.callMgr.friendCameraOn.value) {
        showAppFloatingWindow();
      } else {
        closeAllFloat();
      }
    } else {
      showAppFloatingWindow();
    }

    storeCallViewState();

    if (objectMgr.callMgr.friendCameraOn.value &&
        objectMgr.callMgr.floatWindowIsMe.value) {
      objectMgr.callMgr.floatingWindowOnTap(isBack: true);
    }

    objectMgr.callMgr.onExitCallView(isExit: true);
  }

  void storeCallViewState() {
    objectMgr.callMgr.keepState = {
      "floatWindowIsMe": objectMgr.callMgr.floatWindowIsMe.value,
    };

    if (Get.isRegistered<AgoraCallController>()) {
      objectMgr.callMgr.keepState["calleeBatteryInfo"] =
          Get.find<AgoraCallController>().calleeBatteryInfo;
    }
  }

  void showAppFloatingWindow() {
    if (floatingManager.getFloating('call_floating') == null) {
      Floating callFloating = floatingManager.createFloating(
        'call_floating',
        Floating(
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: getFloatingContentView(),
            ),
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

  getFloatingContentView() {
    return Obx(() {
      if (objectMgr.callMgr.isMinimized.value) {
        if (objectMgr.callMgr.friendCameraOn.value) {
          return getVideoView();
        } else {
          return Platform.isIOS
              ? Stack(
                  children: [
                    // 必须放这个view，因为需要在切画中画时候用来显示头像
                    getVideoView(),
                    getAudioView(),
                  ],
                )
              : getAudioView();
        }
      } else {
        if (!objectMgr.callMgr.friendCameraOn.value &&
            !objectMgr.callMgr.selfCameraOn.value) {
          return getAudioView();
        } else if (objectMgr.callMgr.floatWindowIsMe.value &&
            !objectMgr.callMgr.selfCameraOn.value) {
          return getAudioView();
        } else if (!objectMgr.callMgr.floatWindowIsMe.value &&
            !objectMgr.callMgr.friendCameraOn.value) {
          return getAudioView();
        }
        return getVideoView();
      }
    });
  }

  Widget getVideoView() {
    var children = <Widget>[];

    children.add(
      NativeVideoWidget(
        uid: objectMgr.userMgr.mainUser.uid,
        isBigScreen: false,
      ),
    );

    children.add(
      Positioned.fill(
        child: InkWell(
          onTap: () => objectMgr.callMgr.floatingWindowOnTap(),
          child: const SizedBox(),
        ),
      ),
    );
    return Stack(
      children: children,
    );
  }

  Widget getAudioView() {
    User? user = objectMgr.callMgr.floatWindowIsMe.value &&
            !objectMgr.callMgr.isMinimized.value
        ? objectMgr.userMgr.mainUser
        : objectMgr.callMgr.opponent;
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
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (user != null)
              CustomAvatar.user(
                user,
                size: 56,
              ),
            objectMgr.callMgr.currentState.value == CallState.Waiting ||
                    objectMgr.callMgr.currentState.value == CallState.Ringing
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      objectMgr.callMgr.getCallStatusBrief(),
                      style: jxTextStyle.textStyleBold12(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void closeAllFloat() {
    floatingManager.closeAllFloating();
  }
}

// 定义枚举类型来表示三种连接状态
enum ConnectionStatus {
  disconnected,
  connected,
  connectedAndTalking,
}

class CallTopFloat {
  OverlayEntry? _overlayEntry;
  late String _title;
  late ConnectionStatus _status;
  late VoidCallback _onTap;

  CallTopFloat() {
    _title = "";
    _status = ConnectionStatus.disconnected;
  }

  void show(BuildContext context,
      {required String title,
      required ConnectionStatus status,
      required VoidCallback onTap}) {
    _title = title;
    _status = status;
    _onTap = onTap;

    if (_overlayEntry != null) {
      _updateOverlay();
    } else {
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void update(ConnectionStatus status) {
    _status = status;
    _updateOverlay();
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = AppBar().preferredSize.height;
    final double totalHeight = statusBarHeight + appBarHeight * 0.5;

    return OverlayEntry(
      builder: (context) => Positioned(
        top: 0, // 设置浮动UI从Y轴0开始
        left: 0,
        right: 0,
        height: totalHeight,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _onTap,
            child: Stack(
              children: [
                // 波浪效果
                _buildWaveEffect(
                    MediaQuery.of(context).size.width, totalHeight),
                // 显示标题
                Container(
                  height: totalHeight,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      _title,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildWaveEffect(double bottomWaveWidth, double bottomWaveHeight) {
    String lottieAsset;

    // 根据状态设置不同的 Lottie 动画
    switch (_status) {
      case ConnectionStatus.connected:
        lottieAsset = 'assets/lottie/animate_topbar_communicate_wave_a.json';
        break;
      case ConnectionStatus.connectedAndTalking:
        lottieAsset =
            'assets/lottie/animate_topbar_talking_wave.json'; // 假设有这样一个 Lottie 动画
        break;
      case ConnectionStatus.disconnected:
      default:
        lottieAsset = 'assets/lottie/animate_topbar_communicate_gray.json';
        break;
    }

    return Positioned.fill(
      child: Lottie.asset(
        lottieAsset,
        fit: BoxFit.cover, // 填充整个背景
      ),
    );
  }
}
