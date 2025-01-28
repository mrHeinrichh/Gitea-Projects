import 'dart:isolate';

import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

DebugInfo debugInfo = DebugInfo();

var _logger = Logger(
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
}) {
  // 非主线程
  if (Isolate.current.debugName != 'main') {
    // ignore: avoid_print
    print(info);
    return;
  }
  String msg = isError
      ? debugInfo.getErrorFormatMsg(info, stackTrace)
      : (info ?? '').toString();

  if (writeSentry) debugInfo.writeToSentry(info, stackTrace);

  if (!Config().isDebug) return;
  if (isError) {
    _logger.e(
        '${DateTime.now()} ${debugInfo.prefix} ERROR: $msg', error, stackTrace);
  } else {
    _logger.d('${DateTime.now()} ${debugInfo.prefix} $msg', error, stackTrace);
  }
}

//////////////////////////////////////////////////////////
//////////////////////////堆栈收集/////////////////////////
//////////////////////////////////////////////////////////
class DebugInfo {
  String? _deviceStr;
  String? _version;
  final prefix = "debug";

  get deviceStr => _deviceStr;

  get version => _version;

  /// 排除
  // bool _exclude(e) {
  //   if (e is PlatformException) {
  //     if (e.code == 'OPEN' &&
  //         e.message == null &&
  //         e.details == null &&
  //         e.stacktrace == null) return true;
  //     if (e.code == 'PLAY_ERROR' && e.details == '网络连接已中断。') return true;
  //   }
  //   return false;
  // }

  String _formatE(e) {
    if (e == null) return "";
    var list = e.toString().split('\n');

    StringBuffer buffer = StringBuffer();
    for (var i = 0; i < list.length; i++) {
      if (list[i].isEmpty) continue;
      buffer.writeln(debugInfo.prefix + ' ' + list[i]);
    }
    String result = '''
<-----↓↓↓↓↓↓↓↓↓↓-----error-----↓↓↓↓↓↓↓↓↓↓----->
${buffer.toString()}
<-----↑↑↑↑↑↑↑↑↑↑-----error-----↑↑↑↑↑↑↑↑↑↑----->
''';
    return result;
  }

  String _formatS(StackTrace? s) {
    if (s == null) return "";
    var list = s.toString().split('\n');

    StringBuffer buffer = StringBuffer();
    for (var i = 0; i < list.length; i++) {
      if (list[i].isEmpty) continue;
      buffer.writeln(debugInfo.prefix + ' ' + list[i]);
    }
    // ignore: avoid_print
    String result = '''
<-----↓↓↓↓↓↓↓↓↓↓-----trace-----↓↓↓↓↓↓↓↓↓↓----->
${buffer.toString()}
<-----↑↑↑↑↑↑↑↑↑↑-----trace-----↑↑↑↑↑↑↑↑↑↑----->
''';
    return result;
  }

  String getErrorFormatMsg(
    e,
    StackTrace? s,
  ) {
    String errorMsg = '${_formatE(e)}\n${_formatS(s)}';
    return errorMsg;
  }

  void writeToSentry(e, [s]) async {
    if (Config().sentryUrl.isEmpty) return;

    _deviceStr ??= await PlatformUtils.getDeviceString();
    _version ??= await PlatformUtils.getAppVersion();
    StringBuffer buffer = StringBuffer()
      ..writeln('version: ${_version ?? '10086'}')
      ..writeln('device: ${_deviceStr ?? '-'}')
      ..writeln('APP: ${Config().appName}')
      ..writeln('channel: "${Config().orgChannel}"')
      ..writeln('user_id: "${objectMgr.userMgr.mainUser.uid}"')
      ..writeln('user_name: ${objectMgr.userMgr.mainUser.nickname}')
      ..writeln('token: ${objectMgr.loginMgr.account?.token ?? ''}')
      ..writeln('$e');

    String info = buffer.toString();
    try {
      SentryId sentryId = await Sentry.captureException(
        info,
        stackTrace: s,
        withScope: (scope) {
          scope.setTag('version', _version ?? '10086'); // 版本
          scope.setTag('device', _deviceStr ?? '-'); // 机型
          scope.setTag('APP', Config().appName); // APP
          scope.setTag('channel', "${Config().orgChannel}"); // 渠道
          scope.setTag('user_id', "${objectMgr.userMgr.mainUser.uid}"); // 用户id
          scope.setTag('user_name', objectMgr.userMgr.mainUser.nickname); // 用户名
          scope.setTag(
              'token', objectMgr.loginMgr.account?.token ?? ''); // token
        },
      );
      pdebug('sentryId:$sentryId');
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      pdebug(e, stackTrace: s);
    }
  }
}
