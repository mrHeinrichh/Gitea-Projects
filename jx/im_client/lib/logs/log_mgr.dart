part of 'log_libs.dart';

class LogMgr {
  final _LogUploadMgr logUploadMgr = _LogUploadMgr();
  final MetricsMgr metricsMgr = MetricsMgr();

  final _LogDownloadMgr logDownloadMgr = _LogDownloadMgr();
  final _LogCallMgr logCallMgr = _LogCallMgr();
  final _LogVideoMgr logVideoMgr = _LogVideoMgr();

  final _LogNetworkDiagnoseMgr logNetworkMgr = _LogNetworkDiagnoseMgr();

  bool _isinit = false;
// 日志管理器统一初始化
  init() async {
    if (_isinit) return;
    _isinit = true;
    metricsMgr.init();
    logUploadMgr.init();
    logDownloadMgr.init();
    logCallMgr.init();
    logVideoMgr.init();
    logNetworkMgr.init();
  }
}

class _LogUploadMgr extends LoadMgrBase<LogUploadMsg> {
  @override
  Future<void> doSomeThing(LogUploadMsg metrics) async {
    if (!Config().enableUploadLog) return;
    uploadMetrics([metrics]);
  }
}

class LogUploadMsg extends LogMsgBase {
  LogUploadMsg({
    super.type = 'UPLOAD_LOG',
    required super.msg,
    super.executionTime,
  });
}

class _LogDownloadMgr extends LoadMgrBase<LogDownloadMsg> {}

class LogDownloadMsg extends LogMsgBase {
  LogDownloadMsg({super.type = 'DOWNLOAD_LOG', required super.msg});
}

class _LogCallMgr extends LoadMgrBase<LogCallMsg> {}

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

class _LogVideoMgr extends LoadMgrBase<LogVideoMsg> {}

class LogVideoMsg extends LogMsgBase {
  LogVideoMsg({
    super.type = 'LOG_VIDEO',
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
  }
}

class _LogNetworkDiagnoseMgr extends LoadMgrBase<LogNetworkDiagnoseMsg> {}

class LogNetworkDiagnoseMsg extends LogMsgBase {
  LogNetworkDiagnoseMsg({
    super.type = 'NETWORK_LOG',
    required super.msg,
    super.executionTime,
    super.e,
  });
}
