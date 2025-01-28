import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/managers/tags_mgr.dart';

// Tags
class Tags extends RowObject with EventDispatcher {
  static const String s3Folder = 'avatar';

  Tags() : super();

  static Tags creator() {
    return Tags();
  }

  /// ('''
  ///         CREATE TABLE IF NOT EXISTS tags (
  ///         id INTEGER PRIMARY KEY AUTOINCREMENT,
  ///         uid INTEGER,
  ///         name TEXT DEFAULT "",
  ///         type INTEGER,
  ///         created_at INTEGER,
  ///         updated_at INTEGER
  ///         );
  ///         ''');
  factory Tags.fromJson(Map<String, dynamic> json) {
    Tags tags = creator();
    tags.uid = json['uid'] ?? 0;
    tags.tagName = json['name'] ?? '';
    tags.type = json['type'] ?? TagsMgr.TAG_TYPE_MOMENT;

    try {
      tags.createAt = json["created_at"] ?? 0;
      tags.updatedAt = json["updated_at"] ?? 0;
    } catch (e) {
      tags.createAt = 0;
      tags.updatedAt = 0;
    }

    return tags;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'uid': uid,
      'name': tagName,
      'type': type,
      'created_at': createAt==0?updatedAt:createAt,
      'updated_at': updatedAt==0?createAt:updatedAt,
    };
  }

  Map<String, dynamic> toEditFriendJson()
  {
    return {
      'id': uid,
      'name': tagName,
    };
  }

  void copyFrom(Tags other) {
    uid = other.uid;
    tagName = other.tagName;
    type = other.type;
    createAt = other.createAt;
    updatedAt = other.updatedAt;
  }

  //Will be deleted
  @override
  bool operator ==(Object other) {
    return (other is Tags) && other.uid == uid && other.tagName == tagName;
  }

  @override
  int get hashCode => Object.hash(uid, tagName);

  int get uid => getValue('uid', 0);

  set uid(int value) {
    setValue('uid', value);
  }

  // tag名
  String get tagName => getValue('name', '');

  set tagName(String value) {
    setValue('name', value);
  }

  int get type => getValue('type', TagsMgr.TAG_TYPE_MOMENT);

  set type(int value) {
    setValue('type', value);
  }

  // 创建时间
  int get createAt => getValue('created_at', 0);
  set createAt(int? value) {
    setValue('created_at', value);
  }

  // 更新时间
  int get updatedAt => getValue('updated_at', 0);
  set updatedAt(int? value) {
    setValue('updated_at', value);
  }
}
