// ignore_for_file: non_constant_identifier_names

import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

/// 登陆
Future<HttpResponseBean> jximLogin(String token) async {
  return Request.send("/user/login",
      method: Request.methodTypePost, data: {"token": token});
}
