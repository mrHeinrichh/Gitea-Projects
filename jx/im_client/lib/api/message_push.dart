import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';

//消息推送配置表
Future<HttpResponseBean> getPushConfig() async {
  dynamic data = {};
  return CustomRequest.send(
    "/message_push/get_push_config",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

//推送群
Future<HttpResponseBean> getPushCarGroup() async {
  dynamic data = {};
  return CustomRequest.send(
    "/message_push/car_group",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

//推送用户 0:语音  1:视频
Future<HttpResponseBean> getPushUser(int type) async {
  dynamic data = {};
  data["type"] = type;
  return CustomRequest.send(
    "/message_push/user",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

//消息通知修改
Future<HttpResponseBean> userNoticeEdit(String? extra, int id, int open) async {
  dynamic data = {};

  if (extra != null) {
    data["extra"] = extra;
  }
  data["open"] = open;
  data["id"] = id;
  return CustomRequest.send(
    "/user_notice_setting/edit",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

//消息通知查询
Future<HttpResponseBean> queryUserNotice() async {
  dynamic data = {};
  return CustomRequest.send(
    "/user_notice_setting/query_by_id",
    method: CustomRequest.methodTypePost,
    data: data,
  );
}

class PushNotificationServices {
  final String _pushNotificationUrl = '/app/api/auth';

  /// 注册推送设备
  /// [source] 1 : Engagelab 国际版
  /// [source] 2 : VOIP Device ID 注册
  /// [source] 3 : APNS Device ID 注册
  /// [source] 4 : JPush 中国
  Future<void> registerPushDevice({
    required String registrationId,
    required int platform,
    required int source,
    String voipDeviceToken = '',
    int enableEncryption = 0,
  }) async {
    String url = "$_pushNotificationUrl/register-push-notification";

    final Map<String, dynamic> dataBody = {
      'registration_id': registrationId,
      "voip_device_token": voipDeviceToken,
      'platform': platform,
      'source': source,
      'enable_encryption': Config().enablePushCipher ? 1 : 0,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(url, data: dataBody);

      if (res.success()) {
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> unRegisterPushDevice({
    required String registrationId,
    String voipDeviceToken = '',
  }) async {
    String url = "/im/notification/unregister";

    final Map<String, dynamic> dataBody = {
      "registration_id": registrationId,
      "voip_device_token": voipDeviceToken,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
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
      final ResponseData res = await CustomRequest.doPost(
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
