import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';

class ForceLogout extends EventDispatcher {
  int id = 0;
  int createTime = 0;
  String reason = '';
  int banAccountTime = 0;

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('create_time')) createTime = json['create_time'];
    if (json.containsKey('reason')) {
      var data = jsonDecode(json['reason']);
      reason = data['fh'];
    }
    if (json.containsKey('ban_account')) banAccountTime = json['ban_account'];
  }
}
