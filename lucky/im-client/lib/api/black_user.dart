//删除

import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/object/black_user.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';

//添加黑名单
Future<HttpResponseBean> create(int blackId) async {
  dynamic data = {};
  data["black_id"] = blackId;
  return Request.send("/black_user/create",
      method: Request.methodTypePost, data: data);
}

Future<BlackUser?> createNew<T>(int blackId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["black_user_id"] = blackId.toString();
  try {
    final ResponseData res =
        await Request.doPost("/app/api/black_user/create", data: dataBody);
    if (res.success()) {
      // BlackUser blackUser = BlackUser.fromJson(res.data);
      // return blackUser;
    } else {
      debugPrint('${res.message}(${res.code})');
      return null;
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

//移出黑名单
Future<HttpResponseBean> remove(int blackId) async {
  dynamic data = {};
  data["black_id"] = blackId;
  return Request.send("/black_user/remove",
      method: Request.methodTypePost, data: data);
}

Future<BlackUser?> removeNew<T>(int blackId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["black_user_id"] = blackId.toString();
  try {
    final ResponseData res =
        await Request.doPost("/app/api/black_user/remove", data: dataBody);
    if (res.success()) {
      // BlackUser blackUser = BlackUser.fromJson(dummy: res.dummy);
      // return blackUser;
    } else {
      debugPrint('${res.message}(${res.code})');
      return null;
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

//查询黑名单
Future<HttpResponseBean> queryBlackList(int page, int pageCount) async {
  dynamic data = {};
  data["page"] = page;
  data["page_count"] = pageCount;
  return Request.send("/black_user/query_black_list",
      method: Request.methodTypePost, data: data);
}

// Future<BlackUser?> queryBlackListNew<T>() async {
//   Map<String, dynamic> dataHeader = {};
//   dataHeader["Content-Type"] = "application/json";
//   dataHeader["token"] = "${objectMgr.loginMgr.account?.token}";
//   dataHeader["Dump"] = json.encode({
//     "datas": [
//       {
//         "id": 5,
//         "deleted": 0,
//         "black_id": 19,
//         "create_time": 1672991805,
//         "user_id": 20,
//         "user_data": {
//           "nick_name": "Big_Star",
//           "head": 96,
//           "main_car_series": 0,
//           "id": 19,
//           "level": 0,
//           "deleted": 0,
//           "s_id": 100026,
//           "birthday": 1072800000,
//           "gender": 1,
//           "flags": "1,2,3,22"
//         }
//       }
//     ],
//     "code": 0
//   });
//   try {
//     final ResponseData res = await Request.doGet(
//         "/app/api/black_user/query_black_list?page=0&limit=100",
//         headers: dataHeader);
//     if (res.success()) {
//       // BlackUser blackUser =
//       //     BlackUser.fromJson(list: res.data, dummy: res.dummy);
//       // return blackUser;
//     } else {
//       debugPrint('${res.message}(${res.code})');
//       return null;
//     }
//   } on AppException catch (e) {
//     // 请求过程中的异常处理
//     pdebug('AppException: ${e.toString()}');
//     rethrow;
//   }
// }
