// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/platform_utils.dart';

// # 错误上报
Future<HttpResponseBean> postException(
    Object error, StackTrace stackTrace, String logs, String deviceInfo) async {
  String appVer = await PlatformUtils.getAppVersion();

  dynamic data = {};
  data["server_name"] = "client_${Config().isDebug ? 'debug' : 'release'}";
  data["host"] = serversUriMgr.apiUrl;
  data["exception"] = error.toString();
  data["stack"] = stackTrace.toString();
  data["logs"] = logs;
  data["params"] = "version:$appVer user_id:${objectMgr.userMgr.mainUser.uid}";
  data["device_info"] = deviceInfo;
  String json = jsonEncode(data);
  String jdata = base64Encode(json);
  return Request.send("/exception_log/add_exception",
      method: Request.methodTypePost, data: {"data": jdata});
}
