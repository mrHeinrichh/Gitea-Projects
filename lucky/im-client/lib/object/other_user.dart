import 'package:jxim_client/object/user.dart';
import 'package:events_widget/event_dispatcher.dart';

class OtherUser extends EventDispatcher {
  int userId = 0;
  int followId = 0;
  int id = 0;
  int createTime = 0;
  int chatID = 0;
  late User user = User();
  late GroupData groupData = GroupData();
  int count = 0;

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('follow_id')) followId = json['follow_id'];
    if (json.containsKey('user_id')) userId = json['user_id'];
    if (json.containsKey('create_time')) createTime = json['create_time'];
    if (json.containsKey('user_data')) user.updateValue(json['user_data']);
    if (json.containsKey('group_data')) groupData.applyJson(json['group_data']);
    if (json.containsKey('chat_id')) chatID = json['chat_id'];
    if (json.containsKey('count'))
      count = json['count'] is int ? json['count'] : int.parse(json['count']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['follow_id'] = followId;
    data['user_id'] = userId;
    data['create_time'] = createTime;
    data['user_data'] = user.toJson();
    data['group_data'] = groupData.toJson();
    data['chat_id'] = chatID;
    data['count'] = count;

    return data;
  }
}

class GroupData extends EventDispatcher {
  String name = '';
  int icon = 0;
  String profile = '';

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('name')) name = json['name'];
    if (json.containsKey('icon')) icon = json['icon'];
    if (json.containsKey('profile')) profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['icon'] = icon;
    data['profile'] = profile;
    return data;
  }
}
