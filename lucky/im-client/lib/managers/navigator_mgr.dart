import 'dart:io';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';

/// 跳转类型
const String navigatorTypeChat = 'chat'; // 聊天

const String navigatorTypeRecharge = 'Recharge'; // 充值

const String navigatorTypeVideoFull = 'video_full'; // 全屏视频

const String navigatorTypeRecordVoice = 'record_voice'; // 录音界面

const String navigatorTypeScan = 'scan'; //扫描

const String navigatorTypeQrcode = 'qrcode'; // 二维码

class NavigatorMgr extends EventDispatcher {
  BuildContext? mContext;

  double SCREEN_WIDTH = 0.0;
  double SCREEN_HEIGHT = 0.0;
  double SAFE_TOP = 0.0;
  double SAFE_BOTTOM = 0.0;

  List<String> navigatorRoutes = [];

  bool isExit(String name) {
    for (var item in navigatorRoutes) {
      if (item == name) {
        return true;
      }
    }
    return false;
  }

  addRoutes(String name) {
    navigatorRoutes.add(name);
  }

  removeRoutes(String name) {
    for (var item in navigatorRoutes) {
      if (item == name) {
        navigatorRoutes.remove(item);
        return;
      }
    }
  }

  initScreenSize(BuildContext context) {
    mContext = context;
    if (SCREEN_WIDTH > 0.0) {
      return;
    }
    SCREEN_WIDTH = MediaQuery.of(context).size.width;
    SCREEN_HEIGHT = MediaQuery.of(context).size.height;
    SAFE_TOP = MediaQuery.of(context).padding.top;
    SAFE_BOTTOM = MediaQuery.of(context).padding.bottom;
  }

  Future closeFullVideo() async {
    if (isExit(navigatorTypeVideoFull)) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      if (Platform.isIOS) {
        await objectMgr.shareMgr.iosSwitchPortraitScreen;
        AutoOrientation.portraitUpMode();
      }
      Navigator.of(mContext!).pop();
    }
  }

  bool _showAllScreen = false;

  closeAllScreen() async {
    if (Platform.isIOS && _showAllScreen) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await objectMgr.shareMgr.iosSwitchPortraitScreen;
      AutoOrientation.portraitUpMode();
    }
  }

  showAllScreen() {
    if (Platform.isIOS) {
      _showAllScreen = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp
      ]);
      objectMgr.shareMgr.iosSwitchAllScreen;
    }
  }

  closeRecordVoice() {
    if (isExit(navigatorTypeRecordVoice)) {
      Navigator.of(mContext!).pop();
    }
  }
}
