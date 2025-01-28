import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';

final ConnectivityMgr connectivityMgr = ConnectivityMgr();

/// 连接状态管理, 由于socket在连接变化的时候响应不够及时,监听网络变化提示
class ConnectivityMgr extends EventDispatcher {
  /// 当前的网络连接状态aa
  ConnectivityResult? _connectivityResult;
  Map<String, List<dynamic>>? offlineRequests = {};

  static const onNetworkStatusChange = "onNetworkStatusChange";

  /// 连接状态.
  ConnectivityResult get connectivityResult =>
      _connectivityResult ?? ConnectivityResult.wifi;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool isInitialized = false;

  /// 初始化网络状态
  initConnectivityMgr() async {
    // 监听网络变化
    _connectivitySubscription ??=
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    ConnectivityResult? result;
    try {
      result = await _connectivity.checkConnectivity();
      if (Platform.isIOS) {
        /// connection_plus 在IOS上面的bug, 有网络的时候也会返回none
        await Future.delayed(const Duration(microseconds: 5), () async {
          result = await _connectivity.checkConnectivity();
          if (result == ConnectivityResult.none) {
            isInitialized = true;
          }
        });
      } else if (result == ConnectivityResult.none) {
        isInitialized = true;
      }
    } on PlatformException catch (e) {
      mypdebug(e.toString());
    }

    // 如果连接状态有变化的时候要记录下来
    if (_connectivityResult == null) {
      _connectivityResult = result;
      objectMgr.appInitState.value = hasNetwork() ? AppInitState.idle : AppInitState.no_connect;
      return;
    }
  }

  /// 释放所有资源
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  int trigger = 0;
  _updateConnectionStatus(ConnectivityResult newStatus) async {
    /// 阻止初始化的时候是有网的情况会跑changeState, 只有当网络变化的时候才能跑
    if (Platform.isIOS) {
      trigger++;
      if (trigger == 1) return;

      await Future.delayed(const Duration(milliseconds: 1000));
      ConnectivityResult newStatus1 = await _connectivity.checkConnectivity();
      if (newStatus1 != newStatus) {
        return;
      }
      trigger = 0;
    }

    // // 触发一下所有的状态变化
    // var oldStatus = _connectivityResult;
    // 保存一下连接状态
    _connectivityResult = newStatus;

    if (isInitialized) {
      switch (newStatus) {
        case ConnectivityResult.none:
          _noConnect();
          mypdebug('连接状态变化:无');
          break;
        case ConnectivityResult.mobile:
          _changeState();
          mypdebug('连接状态变化:移动网络');
          break;
        case ConnectivityResult.wifi:
          _changeState();
          mypdebug('连接状态变化:WIFI');
          break;
        default:
          break;
      }
    } else {
      isInitialized = true;
    }

    event(this, onNetworkStatusChange, data: {
      'shouldReload': hasNetwork(),
    });

    // // 如果连接发生变化并且网络是由 有到无
    // const none = ConnectivityResult.none;
    // if (oldStatus != newStatus) {
    //   // 从有到无
    //   if (oldStatus != none && newStatus == none) {
    //   }

    //   // 从无到有
    //   if (oldStatus == none && newStatus != none) {

    //   }
    // }
  }

  bool hasNetwork() {
    return connectivityMgr.connectivityResult != ConnectivityResult.none &&
        connectivityMgr.connectivityResult != ConnectivityResult.bluetooth;
  }
}

_noConnect() {
  Future.delayed(const Duration(milliseconds: 500), () {
    objectMgr.socketMgr.isConnect = false;
    objectMgr.onNetworkOff();
  });
}

int lastOnlineTime = 0;

_changeState() {
  // Prevent run twice
  pdebug("_changeState=================> ");
  if (DateTime.now().millisecondsSinceEpoch - lastOnlineTime > 500) {
    lastOnlineTime = DateTime.now().millisecondsSinceEpoch;
    objectMgr.onNetworkOn();
  }
}
