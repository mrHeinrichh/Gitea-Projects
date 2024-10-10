part of 'log_libs.dart';

abstract class _LoadMgrBase<T> {
  Future<void> doSomeThing(T metrics);
  Future<void> init();
  Future<void> uploadMetrics(List<T> uploadMetricsList);
}

abstract class LoadMgrBase<T extends LogMsgBase> implements _LoadMgrBase<T> {
  final ReceivePort _receivePort = ReceivePort("${T.runtimeType}");

  SendPort get sendPort => _receivePort.sendPort;

  List<T> metricsList = [];

  Lock lock = Lock();

  bool _hasListen = false;
  @mustCallSuper
  @override
  Future<void> init() async {
    if (!_hasListen) {
      _receivePort.listen((message) async {
        addMetrics(message);
      });
      _hasListen = true;
    }
  }

  Future<void> addMetrics(T metrics) async {
    await lock.synchronized(() async {
      await doSomeThing(metrics);
    });
  }

  @override
  Future<void> doSomeThing(T metrics) async {
    uploadMetrics([metrics]);
  }

  @override
  Future<void> uploadMetrics(List<T> uploadMetricsList) async {
    if (!networkMgr.hasNetwork) return;
    Map<String, dynamic> map = {};
    map["log"] = uploadMetricsList;
    map["app_version"] = await PlatformUtils.getAppVersion();

    try {
      ResponseData res = await CustomRequest.doPost(
          "/app/api/account/record-device-latency-log",
          data: map,
          maxTry: 0);
      if (res.success()) {
        pdebug("日志上传成功");
      } else {
        pdebug("日志上传失败");
      }
    } catch (e) {
      pdebug("日志上传异常");
    }
  }
}

abstract class LogMsgBase implements JsonSerializable {
  String? type = "LogMsg";
  String? msg;
  String? mediaType = '-';
  int? executionTime;
  String? stackTrace;
  String? e;
  String? platform;

  LogMsgBase({
    this.msg,
    this.type,
    this.mediaType,
    this.executionTime,
    this.e,
    this.stackTrace,
  }) {
    platform = GetPlatform.isMacOS
        ? 'macos'
        : (GetPlatform.isAndroid
            ? 'android'
            : (GetPlatform.isIOS ? 'ios' : 'others'));
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['type'] = type;
    map['media_type'] = mediaType;
    map['msg'] = msg ?? '';
    map['stackTrace'] = stackTrace ?? '';
    map['e'] = e ?? '';
    map['execution_time'] = executionTime ?? 0;
    map['orgChannel'] = Config().orgChannel;
    map['appName'] = Config().appName;
    map['nickname'] = objectMgr.userMgr.mainUser.nickname;
    map['platform'] = platform;
    return map;
  }
}
