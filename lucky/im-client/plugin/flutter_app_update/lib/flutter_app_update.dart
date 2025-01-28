import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_app_update/request.dart';

import 'app_conf.dart';

typedef DownProgressHandel = void Function(int?);

class FlutterAppUpdate {
  static final MethodChannel _channel =
      const MethodChannel('flutter_app_update')
        ..setMethodCallHandler(methodCallHandler);

  static bool _testFlight = false;

  static AppConf? conf;

  /// 是否审核中
  static bool get audit {
    return conf != null ? conf!.audit : false;
  }

  /// 最低版本要求
  static String? get minversion {
    return conf != null ? conf!.minversion : null;
  }

  static String _changelogIos = '';

  /// 更新日志
  static String get changelog {
    var log = '';
    if (conf != null) {
      log = conf!.changelog;
    }
    if (Platform.isIOS && !_testFlight) {
      log = _changelogIos;
    }
    return log;
  }

  /// 加载配置
  /// value               app配置文件地址或配置
  static Future<bool> loadConf(dynamic value) async {
    if (value is Map<String, dynamic>) {
      conf = AppConf.created(value);
      return true;
    } else if (value is String) {
      var rep = await Request.send(value);
      if (rep.success) {
        conf = AppConf.created(rep.data);
      }
      return rep.success;
    }
    return false;
  }

  /// 是否旧版本
  static bool versionIsOlder = false;

  /// ios下载更新页地址
  static String iosItunesPath = '';

  /// 检查版本
  /// value               app配置文件地址或配置
  /// appid               IOS appid
  /// useSystemUI         是否使用系统UI
  static Future<bool> checkAppVersion(
      {dynamic value,
      String? iosAppid,
      bool testFlight = false,
      bool useSystemUI = false}) async {
    _testFlight = testFlight;
    // print("=================checkAppVersion=========");
    if (value != null) {
      await loadConf(value);
    }
    var arguments = <String, dynamic>{};
    if (conf == null) {
      if (Platform.isAndroid || _testFlight) {
        return false;
      }
    } else {
      if (_testFlight) {
        arguments['minVersion'] = conf!.version;
        return await _channel.invokeMethod('checkLowMinVersion', arguments);
      } else if (Platform.isAndroid) {
        var info = conf!.version.split('+');
        arguments['lastVersionName'] = info[0];
        arguments['lastVersionCode'] = int.tryParse(info[1]);
      }
    }

    arguments['useSystemUI'] = useSystemUI;
    if (Platform.isIOS) {
      arguments['appid'] = iosAppid;
    }
    // print(arguments);
    versionIsOlder = false;
    Map? res = await _channel.invokeMethod('checkAppVersion', arguments);
    if (res != null) {
      versionIsOlder = res["isOlder"] ?? false;
      if (Platform.isIOS) {
        // url                                        APP下载更新页地址
        iosItunesPath = res["url"] ?? "";
        _changelogIos = res["releaseNotes"] ?? "";
      }
    }
    return versionIsOlder;
  }

  /// 是否低于最低版本号
  static Future<bool> checkLowMinVersion() async {
    if (minversion == null || minversion!.isEmpty) {
      return false;
    }
    var arguments = <String, dynamic>{};
    arguments['minVersion'] = minversion;
    return await _channel.invokeMethod('checkLowMinVersion', arguments);
  }

  /// ios打开链接
  static Future<void> iosOpenURL(String url) async {
    await _channel.invokeMethod('openURL', <String, dynamic>{'url': url});
  }

  /// 下载进度
  static int? _downProgress;

  /// 下载进度回调
  static DownProgressHandel? downProgressHandel;

  /// 获取下载进度
  static Future<int?> get downProgress async {
    if (_downProgress == null && Platform.isAndroid) {
      _downProgress = await _channel.invokeMethod('getDownProgress');
    }
    return _downProgress;
  }

  /// 安卓下载apk
  static Future<int?> downloadAPK(String url, String md5,
      {bool useSystemUI = true}) async {
    _downProgress = 0;
    if (downProgressHandel != null) {
      downProgressHandel!(_downProgress);
    }
    if (Platform.isAndroid) {
      _downProgress = await _channel.invokeMethod(
          'downloadAPK', <String, dynamic>{
        'url': url,
        'md5': md5,
        'useSystemUI': useSystemUI
      });
    }
    if (downProgressHandel != null) {
      downProgressHandel!(_downProgress);
    }
    return _downProgress;
  }

  /// 下载进度回调
  static void setDownProgressHandel(DownProgressHandel? handel) {
    if (!Platform.isAndroid) {
      return;
    }
    downProgressHandel = handel;
  }

  /// 取消下载
  static Future<void> downloadCancel() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod('downloadCancel');
    Future.delayed(const Duration(milliseconds: 100), () {
      _downProgress = null;
      if (downProgressHandel != null) {
        downProgressHandel!(_downProgress);
      }
    });
  }

  /// 安装apk
  static Future<void> installAPK() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod('installAPK');
  }

  /// 原生回调
  static Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "downProgressChange":
        _downProgress = call.arguments["progress"];
        if (downProgressHandel != null) {
          downProgressHandel!(_downProgress);
        }
        if (_downProgress == 100) {
          downProgressHandel = null;
        }
        break;
    }
    return null;
  }
}
