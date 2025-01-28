// ignore_for_file: non_constant_identifier_names

import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

Future<HttpResponseBean> get_version() async {
  return Request.send("/tpl_config/get_version",
      method: Request.methodTypePost);
}

Future<HttpResponseBean> get_data_by_tbname(String tplname) async {
  dynamic data = {};
  data["tpl_name"] = tplname;
  return Request.send("/tpl_config/get_data_by_tbname",
      method: Request.methodTypePost, data: data);
}

Future<HttpResponseBean> get_card_data_by_type(int sid) async {
  dynamic data = {};
  data["serise"] = sid;
  return Request.send("/tpl_config/get_car_type",
      method: Request.methodTypePost, data: data);
}

Future<HttpResponseBean> query_car_model_by_id(String cid) async {
  dynamic data = {};
  data["ids"] = cid;
  return Request.send("/tpl_config/query_car_model_by_id",
      method: Request.methodTypePost, data: data);
}
