import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/offline_request_mgr.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/response_data.dart';

//消息推送配置表
Future<HttpResponseBean> getPushConfig() async {
  dynamic data = {};
  return Request.send("/message_push/get_push_config",
      method: Request.methodTypePost, data: data);
}

//推送群
Future<HttpResponseBean> getPushCarGroup() async {
  dynamic data = {};
  return Request.send("/message_push/car_group",
      method: Request.methodTypePost, data: data);
}

//推送用户 0:语音  1:视频
Future<HttpResponseBean> getPushUser(int type) async {
  dynamic data = {};
  data["type"] = type;
  return Request.send("/message_push/user",
      method: Request.methodTypePost, data: data);
}

//消息通知修改
Future<HttpResponseBean> userNoticeEdit(String? extra, int id, int open) async {
  dynamic data = {};

  if (extra != null) {
    data["extra"] = extra;
  }
  data["open"] = open;
  data["id"] = id;
  return Request.send("/user_notice_setting/edit",
      method: Request.methodTypePost, data: data);
}

//消息通知查询
Future<HttpResponseBean> queryUserNotice() async {
  dynamic data = {};
  return Request.send("/user_notice_setting/query_by_id",
      method: Request.methodTypePost, data: data);
}

class PushNotificationServices {
  String _pushNotificationUrl = '/app/api/auth';

  /// 注册推送设备
  /// [source] 1 : Engagelab 国际版
  /// [source] 2 : VOIP Device ID 注册
  /// [source] 3 : APNS Device ID 注册
  /// [source] 4 : JPush 中国
  Future<void> registerPushDevice({
    required String registrationId,
    required int platform,
    required int source,
    String voip_device_token = '',
    int enableEncryption = 0,
  }) async {
    String url = "$_pushNotificationUrl/register-push-notification";

    final Map<String, dynamic> dataBody = {
      'registration_id': registrationId,
      "voip_device_token": voip_device_token,
      'platform': platform,
      'source': source,
      'enable_encryption': Config().enablePushCipher ? 1 : 0,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> unRegisterPushDevice(
      {required String registrationId, String voip_device_token = ''}) async {
    String url = "/im/notification/unregister";

    final Map<String, dynamic> dataBody = {
      "registration_id": registrationId,
      "voip_device_token": voip_device_token,
    };

    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      OfflineRequest req = OfflineRequest(url, dataBody, needToken: false);
      objectMgr.offlineRequestMgr.add(req);
      return;
    }

    try {
      final ResponseData res = await Request.doPost(
        url,
        data: dataBody,
        needToken: false,
      );

      if (res.success()) {
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> enablePushKit() async {
    try {
      final ResponseData res = await Request.doPost(
        '/im/user/enable_push_kit',
        data: {'enable': Config().enablePushKit ? 1 : 0},
      );

      if (res.success()) {
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }
}

// enum Platform
