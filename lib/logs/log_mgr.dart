part of 'log_libs.dart';

final LogMgr logMgr = LogMgr();

// 日志管理器统一初始化
final LogUploadMgr _logUploadMgr = LogUploadMgr();

class LogMgr {
  final MetricsMgr metricsMgr = MetricsMgr();

  final LogDownloadMgr logDownloadMgr = LogDownloadMgr();
  final LogCallMgr logCallMgr = LogCallMgr();
  final LogVideoMgr logVideoMgr = LogVideoMgr();
  final RemoteImageMgr logRemoteImageMgr = RemoteImageMgr();

  final LogMomentMgr logMomentMgr = LogMomentMgr();
  final LogSendMessageMgr logSendMessageMgr = LogSendMessageMgr();

  init() async {
    logMgr.metricsMgr.init();
    _logUploadMgr.init();
    logDownloadMgr.init();
    logCallMgr.init();
    logVideoMgr.init();
    logMomentMgr.init();
    logSendMessageMgr.init();
    logRemoteImageMgr.init();
  }
}

class LogUploadMgr extends LoadMgrBase<LogUploadMsg> {}

class LogUploadMsg extends LogMsgBase {
  LogUploadMsg({
    super.type = 'UPLOAD_LOG',
    required super.msg,
    super.executionTime,
  });
}

class LogDownloadMgr extends LoadMgrBase<LogDownloadMsg> {}

class LogDownloadMsg extends LogMsgBase {
  LogDownloadMsg({super.type = 'DOWNLOAD_LOG', required super.msg});
}

class RemoteImageMgr extends LoadMgrBase<LogRemoteImageMsg> {}

class LogRemoteImageMsg extends LogMsgBase {
  LogRemoteImageMsg({super.type = 'REMOTE_LOG', required super.msg});
}

class LogCallMgr extends LoadMgrBase<LogCallMsg> {}

class LogCallMsg extends LogMsgBase {
  String? deviceId;

  LogCallMsg({
    super.type = 'CALL',
    required super.msg,
    super.mediaType,
    this.deviceId,
  });

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = super.toJson();
    map["deviceId"] = deviceId;
    return map;
  }
}

class LogVideoMgr extends LoadMgrBase<LogVideoMsg> {}

class LogVideoMsg extends LogMsgBase {
  LogVideoMsg({
    super.type = 'VIDEO',
    required super.msg,
    super.mediaType,
    super.executionTime,
  });
}

class CallLogInfo {
  final String channelId;
  final String method;
  CallState? state;
  CallEvent? event;
  String? opt;

  CallLogInfo({
    required this.method,
    required this.channelId,
    this.state,
    this.event,
    this.opt,
  });

  @override
  String toString() {
    return "channelId:$channelId method:$method ${state != null ? 'state: $state' : ''} "
        "${event != null ? 'event: $event' : ''} version: ${appVersionUtils.currentAppVersion} platform: ${Platform.isAndroid ? 'Android' : 'iOS'}"
        "${state != null ? 'state: $state' : ''} ${notBlank(opt) ? 'opt: $opt' : ''} at ${DateTime.now().millisecondsSinceEpoch}";
  }
}

class HttpLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      _sendLogToServer(line);
    }
  }

  _sendLogToServer(String logMessage) async {
    // ignore: avoid_print
    if (Config().isDebug) print("${DateTime.now()} => $logMessage");
    if (!logMessage.contains('uploadHandleRequest')) return;

    RegExp regex = RegExp(r'\{.*\}');
    Match? match = regex.firstMatch(logMessage);

    if (match != null) {
      String jsonStr = match.group(0)!;
      Map<String, dynamic> jsonData = jsonDecode(jsonStr);

      // 打印解析后的数据
      _logUploadMgr.addMetrics(
        LogUploadMsg(
          msg: '${jsonData['uploadHandleRequest']}',
          executionTime: int.parse('${jsonData['execution_time'] ?? -1}'),
        ),
      );
    } else {
      _logUploadMgr.addMetrics(
        LogUploadMsg(
          msg: logMessage,
        ),
      );
    }
  }
}

class LogMomentMgr extends LoadMgrBase<LogMomentMsg> {}

class LogMomentMsg extends LogMsgBase {
  LogMomentMsg({
    super.type = 'MOMENT_LOG',
    required super.msg,
    super.executionTime,
    super.e,
  });
}

class LogSendMessageMgr extends LoadMgrBase<LogSendMessageMsg> {}

class LogSendMessageMsg extends LogMsgBase {
  LogSendMessageMsg({
    super.type = "SEND_MESSAGE_LOG",
    required super.msg,
    super.executionTime,
    super.e,
  });
}
