import 'package:jxim_client/api/main.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

Future<HttpResponseBean> pushSetDeviceToken(String channelID, int deviceType,
    {String? device_token_cs, String? fingerprint}) {
  var data = {"device_token": channelID, "device_type": deviceType};
  if (device_token_cs != null) {
    data["device_token_cs"] = device_token_cs;
  }
  if (fingerprint != null) {
    data["fingerprint"] = fingerprint;
  }
  return Request.send(httpBase + "remote_notifi/set_device_token_v2",
      method: Request.methodTypePost, data: data);
}

Future<HttpResponseBean> pushDelDeviceToken(String channelID) {
  return Request.send(httpBase + "remote_notifi/del_device_token_v2",
      method: Request.methodTypePost, data: {"device_token": channelID});
}
