import 'dart:async';

import 'package:flutter_yun_ceng_kiwi/flutter_yun_ceng_kiwi.dart';
import 'package:jxim_client/utils/debug_info.dart';

final dunMgr = DunMgr();

class DunMgr {
  ///当前token
  final String _currentToken = "token";

  Future<int> initAsync(String key) async {
    assert(key.isNotEmpty);
    int begin = DateTime.now().millisecondsSinceEpoch;
    pdebug("YunCeng.initAsync() begin");
    int code = await FlutterYunCengKiwi.initAsync(key, _currentToken);
    int end = DateTime.now().millisecondsSinceEpoch;
    pdebug("YunCeng.initAsync() => $code, cost ${end - begin} ms");
    return code;
  }

  Future<bool> isInitDone() async {
    int code = await FlutterYunCengKiwi.isInitDone();
    return code == 0;
  }

  Future<Uri?> serverToLocal(Uri uri) async {
    dynamic result = await FlutterYunCengKiwi.getProxyTcpByDomain(
      _currentToken,
      uri.host,
      "",
    );
    int code =
        result["code"] is int ? result["code"] : int.parse(result["code"]);
    pdebug("Kiwi serverToLocal ${uri.host} return $code");

    if (code == 0) {
      return uri.replace(
        port: int.parse(result["target_port"]),
        host: result["target_ip"],
      );
    }
    return null;
  }

  Future<int> restart() async {
    int code = await FlutterYunCengKiwi.restartAllServer();
    pdebug("YunCeng.restartAllServer() => $code");
    return code;
  }

  Future<int> onNetworkOn() async {
    int code = await FlutterYunCengKiwi.onNetworkOn();
    return code;
  }
}
