import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/object/call_info.dart';
import 'package:jxim_client/utils/battery_helper.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<ResponseData> getRTCToken(
  int chatId,
  int isVideo, {
  List<int> recipientIds = const <int>[],
  String? channelId,
}) async {
  Map<String, dynamic> data = {"chat_id": chatId};
  data['recipient_id'] = recipientIds;
  data['rtc_channel_id'] = channelId ?? '';
  data['video_call'] = isVideo;

  return await CustomRequest.doPost("/im/call/rtc_token",
      data: data, maxTry: 1);
}

Future<ResponseData> getCallInviteList() async {
  try {
    final res = await CustomRequest.doPost("/im/call/invite_list");
    return res;
  } catch (e) {
    if (e is NetworkException) {
      pdebug(e.getMessage());
    } else {
      pdebug(e.toString());
    }
    rethrow;
  }
}

Future<ResponseData> updateCallStatus(
  String rtcChannelId,
  int status,
  int duration,
) async {
  final data = <String, dynamic>{};
  data['rtc_channel_id'] = rtcChannelId;
  data['status'] = status;
  data['duration'] = duration;

  try {
    final res =
        await CustomRequest.doPost("/im/call/update_status", data: data);
    return res;
  } catch (e) {
    if (e is NetworkException) {
      // Toast.showToast(e.getMessage());
    } else {
      if (e is CodeException) {
        if (e.getPrefix() == 20508) {
          Toast.showToast(localized(callRequestFailed));
          objectMgr.callMgr.handleEvent(CallEvent.RequestFailed);
        }
      }
      pdebug(e.toString());
    }
    rethrow;
  }
}

Future<List<Call>?> getCallLog(int timestamp) async {
  Map<String, dynamic> dataBody = {};

  dataBody["start_from"] = timestamp;
  dataBody["status"] = -1;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/call/records",
      data: dataBody,
    );

    if (res.success()) {
      if (res.data != null) {
        final List<Call> callLogs =
            res.data.map<Call>((callItem) => Call.fromJson(callItem)).toList();
        return callLogs;
      }
    } else {
      return null;
    }
  } catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
  return null;
}

Future<bool> deleteLog(String rtcId) async {
  Map<String, dynamic> dataBody = {};

  dataBody["rtc_channel_id"] = rtcId;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/call/delete_record",
      data: dataBody,
    );

    if (res.success()) {
      return true;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } catch (e) {
    rethrow;
  }
}

Future<CallInfo> getCurrentCallStatus() async {
  try {
    final res = await CustomRequest.doPost("/im/call/current_status");
    return CallInfo.fromJson(res.data);
  } catch (e) {
    rethrow;
  }
}

Future<bool> getCallUpdate(String channelId, BatteryInfo info) async {
  Map<String, dynamic> dataBody = {};
  dataBody["channel_id"] = channelId;
  dataBody["info"] = info.toJson();

  try {
    final ResponseData res =
        await CustomRequest.doPost("/im/call/info_update", data: dataBody);
    return res.success();
  } catch (e) {
    rethrow;
  }
}
