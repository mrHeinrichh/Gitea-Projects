import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

myPrint(Object? object) {
  if (kDebugMode) {
    myPrint(object);
  }
}

class FlutterYunCengKiwi {
  static const MethodChannel _channel = MethodChannel('flutter_yun_ceng_kiwi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  //初始化接口
  static Future initEx(String appKey, String token) async {
    dynamic args;
    args = {
      "appKey": appKey,
      "token": token,
    };

    int result = -1;
    try {
      result = await _channel.invokeMethod('initEx', args);
    } on PlatformException catch (e) {
      myPrint(e);
    } catch (e) {
      myPrint(e);
    }
    return result;
  }

  static Future initAsync(String appKey, String token) async {
    dynamic args;
    args = {
      "appKey": appKey,
      "token": token,
    };

    try {
      await _channel.invokeMethod('initAsync', args);
    } on PlatformException catch (e) {
      myPrint(e);
    } catch (e) {
      myPrint(e);
    }
    return 0;
  }

  static Future isInitDone() async {
    dynamic args = {};
    return await _channel.invokeMethod('isInitDone', args);
  }

  //网络接口重置
  static Future restartAllServer() async {
    dynamic args = {};
    int result = -1;
    try {
      result = await _channel.invokeMethod('restartAllServer', args);
    } on PlatformException catch (e) {
      myPrint(e);
    }
    return result;
  }

  // 网络恢复回调接口
  static Future onNetworkOn() async {
    dynamic args = {};
    return await _channel.invokeMethod('onNetworkOn', args);
  }

  //异步初始化
  static Future initExWithCallback(String appKey, String token) {
    dynamic args;
    args = {
      "appKey": appKey,
      "token": token,
    };

    Completer com = Completer();
    _channel.setMethodCallHandler((call) {
      if (call.method == "initExWithCallbackResult") {
        com.complete(call.arguments);
        return Future.value();
      }
      throw MissingPluginException(
        '${call.method} was invoked but has no handler',
      );
    });
    _channel.invokeMethod('initExWithCallback', args);
    return com.future;
  }

  ///请求游戏盾端口 @return HashMap<dynamic, dynamic>(target_ip, target_port, code)
  static Future getProxyTcpByDomain(
      String token, String groupname, String dport) async {
    dynamic args;
    args = {"token": token, "group_name": groupname, "dport": dport};

    dynamic result; //HashMap<dynamic, dynamic>(target_ip, target_port, code)
    try {
      result = await _channel.invokeMethod('getProxyTcpByDomain', args);
    } on PlatformException catch (e) {
      myPrint(e);
    }
    return result;
  }
}
