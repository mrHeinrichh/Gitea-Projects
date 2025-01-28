import 'dart:isolate';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:synchronized/synchronized.dart';

abstract class JsonSerializable {
  Map<String, dynamic> toJson();
}

abstract class _LoadMgrBase<T> {
  Future<void> addMetrics(T metrics);
  Future<void> doSomeThing(T metrics);
  Future<void> init();
  Future<void> uploadMetrics(List<T> uploadMetricsList);
}

abstract class LoadMgrBase<T extends LogMsgBase> implements _LoadMgrBase<T> {
  ReceivePort _receivePort = ReceivePort();

  SendPort get sendPort => _receivePort.sendPort;

  List<T> metricsList = [];

  Lock lock = Lock();

  bool _hasListen = false;
  Future<void> init() async {
    if (!_hasListen) {
      _receivePort.listen((message) async {
        await addMetrics(message);
      });
      _hasListen = true;
    }
  }

  Future<void> addMetrics(T metrics) async {
    await lock.synchronized(() async {
      await doSomeThing(metrics);
    });
  }

  Future<void> doSomeThing(T metrics) async {
    uploadMetrics([metrics]);
  }

  Future<void> uploadMetrics(List<T> uploadMetricsList) async {
    Map<String, dynamic> map = {};
    map["log"] = uploadMetricsList;
    map["app_version"] = await PlatformUtils.getAppVersion();
    ResponseData res = await Request.doPost(
        "/app/api/account/record-device-latency-log",
        data: map);
    if (res.success()) {
      pdebug("日志上传成功");
    } else {
      pdebug("日志上传失败");
    }
  }
}

abstract class LogMsgBase implements JsonSerializable {
  String? type = "LogMsg";
  String? msg;
  String? media_type = '-';

  LogMsgBase({this.msg, this.type, this.media_type});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['type'] = type;
    map['media_type'] = media_type;
    map['msg'] = msg ?? '';
    map['orgChannel'] = Config().orgChannel;
    map['appName'] = Config().appName;
    map['nickname'] = objectMgr.userMgr.mainUser.nickname;
    return map;
  }
}
