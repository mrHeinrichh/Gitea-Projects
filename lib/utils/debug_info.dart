import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 输出限定字符串长度,0为不限制
const outputlen = 500;

DebugInfo debugInfo = DebugInfo();

var logger = Logger(
  filter: MyLogFilter(),
  // printer: MyLogPrinter(),
  output: HttpLogOutput(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: false,
    printTime: false,
  ),
);

class MyLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return [event.message];
  }
}

class MyLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.message
        .toString()
        .contains('account/record-device-latency-log')) {
      return false;
    }
    if (event.message.toString().contains('account/heartbeat')) {
      return false;
    }
    if (event.message.toString().contains('metrics_log')) {
      return false;
    }
    return true;
  }
}

//调试打印
pdebug(
  dynamic info, {
  int? len,
  dynamic error,
  StackTrace? stackTrace,
  bool writeSentry = false,
  bool isError = false,
  bool toast = false,
}) {
  String? prefix = "debug";

  List logs = [];
  if (info is List) {
    logs = info;
  } else {
    logs.add(info.toString());
  }

  for (int i = 0; i < logs.length; i++) {
    String msg = '${DateTime.now()} $prefix: ${logs[i]}';
    if (writeSentry) debugInfo.saveErrorMsg(info);
    if (!Config().isDebug) return;
    if (Isolate.current.debugName != 'main') {
      // ignore: avoid_print
      print(msg);
      continue;
    }
    len = len ?? outputlen;
    if (len > 0 && msg.length > len) {
      msg = msg.substring(0, len);
    }
    if (isError) {
      logger.e('ERROR:═════ $msg', error, stackTrace);
    } else {
      logger.d('═════ $msg', error, stackTrace);
    }
  }

  // if (toast || Config().showGlobalError) {
  //   MyErrorHandler.showError("${info.toString()}}");
  // }
}

//////////////////////////////////////////////////////////
//////////////////////////堆栈收集/////////////////////////
//////////////////////////////////////////////////////////
class DebugInfo {
  late String _deviceStr;
  String? _version;

  get deviceStr => _deviceStr;

  get version => _version;

  int debugCount = 0;

  get fourceDebug => debugCount > 1;

  DebugInfo() {
    _deviceStr = "";
  }

  Future<void> init() async {
    _deviceStr = await PlatformUtils.getDeviceString();
    _version = await PlatformUtils.getAppVersion();
  }

  /// 排除
  bool _exclude(e) {
    if (e is PlatformException) {
      if (e.code == 'OPEN' &&
          e.message == null &&
          e.details == null &&
          e.stacktrace == null) return true;
      if (e.code == 'PLAY_ERROR' && e.details == '网络连接已中断。') return true;
    }
    return false;
  }

  String _formatE(e) {
    if (e == null) return "";
    String result = '''
<-----↓↓↓↓↓↓↓↓↓↓-----error-----↓↓↓↓↓↓↓↓↓↓----->
$e
<-----↑↑↑↑↑↑↑↑↑↑-----error-----↑↑↑↑↑↑↑↑↑↑----->
''';
    pdebug(result);
    return e.toString();
  }

  String _formatS(s) {
    if (s == null) return "";
    String result = '''
<-----↓↓↓↓↓↓↓↓↓↓-----trace-----↓↓↓↓↓↓↓↓↓↓----->
$s
<-----↑↑↑↑↑↑↑↑↑↑-----trace-----↑↑↑↑↑↑↑↑↑↑----->
''';
    pdebug(result);
    return s.toString();
  }

  void saveErrorMsg(e, [s]) async {
    try {
      if (Isolate.current.debugName != 'main') {
        // ignore: avoid_print
        return print(e);
      }
      if (Config().isDebug || serversUriMgr.sentryUrl.isEmpty) return;

      String version = _version ?? '10086';
      String temp = '''$e
      ${Config().appName}[${defaultTargetPlatform == TargetPlatform.iOS ? "苹果" : "安卓"}]$version
      机型:$_deviceStr
      APP:${Config().appName} ${Config().orgChannel}
      用户:${objectMgr.userMgr.mainUser.uid} ${objectMgr.userMgr.mainUser.nickname}
      token:${objectMgr.loginMgr.account?.token ?? ''}
      ''';
      Sentry.captureException(temp, stackTrace: s);
    } catch (e, s) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(s);
    }
  }

  /// [e]为错误类型 :可能为 Error , Exception ,String
  /// [s]为堆栈信息
  Future<void> printErrorStack(
    e,
    s, {
    String titleInfo = '',
    bool save = true,
    bool toast = false,
  }) async {
    if (_exclude(e)) return;
    pdebug([titleInfo], error: e, stackTrace: s, isError: true, toast: toast);
    String msg = '$titleInfo\n${_formatE(e)}\n${_formatS(s)}';

    if (save) {
      try {
        saveErrorMsg(e, s);
      } catch (e) {
        pdebug(
          "saveErrorMsg:$e",
          error: e,
          stackTrace: s,
          isError: true,
          toast: toast,
        );
        Sentry.captureException("saveErrorMsg is error: $msg", stackTrace: s);
      }
    }
  }
}

class MyErrorHandler {
  static void showError(String message) {
    // 使用全局 navigatorKey 显示错误对话框
    unawaited(
      showDialog(
        context: navigatorKey.currentState?.overlay?.context ??
            navigatorKey.currentState!.context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: SingleChildScrollView(
              child: SelectableText(
                message,
                style: const TextStyle(color: Colors.red),
              ), // 支持滚动和复制的文本
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }
}
