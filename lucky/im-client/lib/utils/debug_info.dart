import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 输出限定字符串长度,0为不限制
const OUTPUT_LEN = 500;

enum EnumSentry {
  EnumSentryDef,
}

DebugInfo debugInfo = new DebugInfo();

const int _max = 100;

var logger = Logger(
  filter: MyLogFilter(),
  // printer: MyLogPrinter(),
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
pdebug(dynamic info,
    {int? len, bool writeSentry = true, String? prefix, bool isError = false}) {
  prefix ??= "debug";

  List logs = [];
  if (info is List) {
    logs = info;
  } else {
    logs.add(info.toString());
  }

  for (int i = 0; i < logs.length; i++) {
    String msg = '${DateTime.now()} $prefix: ${logs[i]}';
    if (writeSentry) debugInfo.addLog(msg);
    if (!Config().isDebug) return;
    len = len ?? OUTPUT_LEN;
    if (len > 0 && msg.length > len) {
      msg = msg.substring(0, len);
    }
    if (isError) {
      logger.e('ERROR:═════ $msg');
    } else {
      logger.d('═════ $msg');
    }
  }
}

extension objectExtension on Object {
  @protected
  mypdebug(dynamic msg,
      {bool writeSentry = true,
      int len = OUTPUT_LEN,
      bool toast = false,
      bool isError = false}) {
    String outMsg = '[$runtimeType]$msg';
    pdebug([outMsg], writeSentry: writeSentry, len: len, isError: isError);

    if (toast) {
      Toast.showToast(msg);
    }
  }
}

//////////////////////////////////////////////////////////
//////////////////////////堆栈收集/////////////////////////
//////////////////////////////////////////////////////////
class DebugInfo {
  late List<String> _logs;

  /// log堆栈数量
  late int _bi;

  late String _deviceStr;
  late String _version;

  get deviceStr => _deviceStr;
  get version => _version;

  int debugCount = 0;

  get fourceDebug => debugCount > 1;

  DebugInfo() {
    _logs = [];
    _bi = 0;
    _deviceStr = "";
  }

  Future<void> init() async {
    _deviceStr = await PlatformUtils.getDeviceString();
    _version = await PlatformUtils.getAppVersion();
  }

  /// log： "DateTime debug: $info"
  void addLog(String log) {
    if (_logs.length > _bi)
      _logs[_bi] = log;
    else
      _logs.add(log);
    _bi++;

    /// 重置log 数量
    if (_bi >= _max) _bi = 0;
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

  void _saveErrorMsg(e, s) async {
    if (Config().isDebug || serversUriMgr.sentryUrl.isEmpty) return;

    String version = _version ?? '10086';
    String temp = '''$e
      ${Config().appName}[${defaultTargetPlatform == TargetPlatform.iOS ? "苹果" : "安卓"}]$version
      机型:${_deviceStr}
      APP:${Config().appName} ${Config().orgChannel}
      用户:${objectMgr.userMgr.mainUser.uid} ${objectMgr.userMgr.mainUser.nickname}
      token:${objectMgr.loginMgr.account?.token ?? ''}
      ''';
    Sentry.captureException(temp, stackTrace: s);
  }

  /// [e]为错误类型 :可能为 Error , Exception ,String
  /// [s]为堆栈信息
  Future<void> printErrorStack(e, s,
      {String titleInfo = '',
      bool save = true,
      bool toast = false,
      EnumSentry es = EnumSentry.EnumSentryDef}) async {
    if (_exclude(e)) return;
    pdebug([titleInfo],isError: true);
    String msg = '$titleInfo\n${_formatE(e)}\n${_formatS(s)}';

    if (save) {
      try {
        _saveErrorMsg(e, s);
      } catch (e) {
        mypdebug("_saveErrorMsg:$e",isError: true);
        Sentry.captureException("_saveErrorMsg is error: $msg");
      }
    }

    if (toast || Config().showGlobalError) {
      MyErrorHandler.showError("${e.toString()}\n${s.toString()}");
    }
  }
}

class MyErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey = Routes.navigatorKey;

  static void showError(String message) {
    // 使用全局 navigatorKey 显示错误对话框
    unawaited(showDialog(
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
    ));
  }
}
