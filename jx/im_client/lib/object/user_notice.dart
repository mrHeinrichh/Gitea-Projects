import 'package:jxim_client/data/row_object.dart';
import 'package:events_widget/event_dispatcher.dart';

class UserNotice extends RowObject {
  String get desc => getValue('desc', '');
  String get name => getValue('name', '');
  int get parent => getValue('parent', 0);
  int get order => getValue('key_index', 0);
  String get operator => getValue('operator', '');

  static UserNotice creator() {
    return UserNotice();
  }
}

class NoticeModel extends EventDispatcher {
  int id = 0;
  int open = 0; //0关闭 1开启
  String starTime = '';
  String endTime = '';
  String extra = '';
  int flag = 0;
  UserNotice userNotice = UserNotice();

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('flag')) flag = json['flag'];
    if (json.containsKey('open')) open = json['open'];
  }
}
