
import 'dart:convert';

///{
///     "datas": [
///         {
///             "target_uuid": "1673857371hw38lZ",
///             "friend_tags": []
///         }
///     ]
/// }
class EditFriend
{
  String? target_uuid;
  List<int>? friend_tags;

  EditFriend({this.target_uuid, this.friend_tags});

  factory EditFriend.fromJson(Map<String, dynamic> json) => EditFriend(
      target_uuid: json["target_uuid"],
      friend_tags:json["friend_tags"] != null
        ? json["friend_tags"] is String ? List<int>.from(jsonDecode(json["friend_tags"])) : List<int>.from(json["friend_tags"])
        : <int>[]
  );

  Map<String, dynamic> toJson() => {
    "target_uuid": target_uuid,
    "friend_tags": friend_tags,
  };
}