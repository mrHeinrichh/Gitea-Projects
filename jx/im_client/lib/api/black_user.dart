import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/object/black_user.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<HttpResponseBean> create(int blackId) async {
  dynamic data = {};
  data["black_id"] = blackId;
  return CustomRequest.send(
    "/black_user/create",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

Future<BlackUser?> createNew<T>(int blackId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["black_user_id"] = blackId.toString();
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/black_user/create",
        data: dataBody);
    if (res.success()) {
    } else {
      debugPrint('${res.message}(${res.code})');
      return null;
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
  return null;
}

Future<HttpResponseBean> remove(int blackId) async {
  dynamic data = {};
  data["black_id"] = blackId;
  return CustomRequest.send(
    "/black_user/remove",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

Future<BlackUser?> removeNew<T>(int blackId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["black_user_id"] = blackId.toString();
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/black_user/remove",
        data: dataBody);
    if (res.success()) {
    } else {
      debugPrint('${res.message}(${res.code})');
      return null;
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
  return null;
}

Future<HttpResponseBean> queryBlackList(int page, int pageCount) async {
  dynamic data = {};
  data["page"] = page;
  data["page_count"] = pageCount;
  return CustomRequest.send(
    "/black_user/query_black_list",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}
