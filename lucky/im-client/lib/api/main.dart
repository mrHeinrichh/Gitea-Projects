import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/request.dart';

String get httpBase {
  return serversUriMgr.apiUrl + "/";
}


Future<bool> networkCheck() async {
  try {
    Map<String, dynamic> dataBody = {"channel": Config().orgChannel};

    final ResponseData res = await Request.doGet("/im/health/check", data: dataBody, needToken: false);
    return res.success();
  } on AppException {
    return false;
  }
}
