import 'package:events_widget/event_dispatcher.dart';
import 'package:lpinyin/lpinyin.dart';

import 'package:jxim_client/data/row_object.dart';

enum Relationship {
  self,
  friend,
  stranger,
  sentRequest,
  receivedRequest,
  blocked,
  blockByTarget
}

// 用户
class User extends RowObject with EventDispatcher {
  static const String s3Folder = 'avatar';
  static const String eventPraiseChange = "eventPraiseChange";
  static const String eventLoverChange = "eventLoverChange";

  User() : super();

  static User creator() {
    return User();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    User user = creator();
    user.uid = json['uid'] ?? 0;
    user.accountId = json['uuid'] ?? '';
    user.username = json['username'] ?? '';
    user.nickname = json['nickname'] ?? '';
    user.contact = json['contact'] ?? '';
    user.countryCode = json['country_code'] ?? '';
    user.email = json['email'] ?? '';
    user.lastOnline = json["last_online"] ?? 0;
    user.profilePicture = json["profile_pic"] ?? '';
    user.relationship = getEnumType((json["relationship"] ?? 2));
    user.profileBio = json["bio"] ?? '';
    user.alias = json["user_alias"] ?? '';
    user.remark = json["remark"] ?? '';
    user.groupTags = json["group_tags"] != null && json["group_tags"] is List
        ? List<String>.from(json["group_tags"])
        : <String>[];
    if (json["request_at"] != null) user.requestTime = json["request_at"];

    try {
      user.deletedAt = json["deleted_at"] ?? 0;
    } catch (e) {
      user.deletedAt = 0;
    }
    if(json["public_key"] != null && json["public_key"] != ""){
      user.publicKey = json["public_key"];
    }

    return user;
  }

  factory User.fromGroupMember(Map<String, dynamic> json) {
    User user = creator();
    user.uid = json['user_id'] ?? 0;
    user.nickname = json['user_name'] ?? '';
    user.profilePicture = json["icon"] ?? '';
    user.lastOnline = json["last_online"] ?? 0;
    user.deletedAt = json["delete_time"] ?? 0;
    user.publicKey = json["public_key"] ?? '';
    return user;
  }

  Map<String, dynamic> groupMemberToJson() {
    return {
      'user_id': uid,
      'user_name': nickname,
      'icon': profilePicture,
      'last_online': lastOnline,
      'public_key': publicKey,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'uid': uid,
      'uuid': accountId,
      'username': username,
      'nickname': nickname,
      'contact': contact,
      'country_code': countryCode,
      'email': email,
      'last_online': lastOnline,
      'profile_pic': profilePicture,
      'relationship': setEnumType(relationship),
      'bio': profileBio,
      'user_alias': alias,
      'remark': remark,
      'group_tags': groupTags,
      if (requestTime != 0) 'request_at': requestTime,
      'deleted_at': deletedAt,
      if(publicKey != "") 'public_key': publicKey,
    };
  }

  //Will be deleted
  @override
  bool operator ==(other) {
    return (other is User) &&
        other.uid == uid &&
        other.accountId == accountId &&
        other.username == username &&
        other.nickname == nickname &&
        other.contact == contact &&
        other.countryCode == countryCode &&
        other.lastOnline == lastOnline &&
        other.profilePicture == profilePicture &&
        other.relationship == relationship &&
        other.profileBio == profileBio;
  }

  @override
  int get hashCode => Object.hash(
        accountId,
        uid,
        username,
        nickname,
        contact,
        countryCode,
        lastOnline,
        profilePicture,
        relationship,
        profileBio,
      );

  //获取数据时间
  int getDataTime = 0;

  // 用户ID
  int get uid => getValue('id', 0);

  set uid(int value) {
    setValue('id', value);
  }

  // 用户AccountID
  String get accountId => getValue('uuid', '');

  set accountId(String value) {
    setValue('uuid', value);
  }

  // 用户名
  String get username => getValue('username', '');

  set username(String value) {
    setValue('username', value);
  }

  // 备注名
  String get alias => getValue('user_alias', '');

  set alias(String value) {
    setValue('user_alias', value);
  }

  //用户简介
  String get profileBio => getValue('bio', '');

  set profileBio(String value) {
    setValue('bio', value);
  }

  // 用户别名
  String get nickname => getValue('nickname', '');

  set nickname(String value) {
    setValue('nickname', value);
  }

  // 用户别名 - 转换之后的，用于排序
  String get nicknameChars {
    String name = (alias.trim() != '') ? alias : nickname;
    String nameChs =
        PinyinHelper.getPinyinE(name, separator: "", defPinyin: '#');
    String upName = nameChs.toUpperCase();
    return upName;
  }

  // 转换之后别名，是否以字母开头
  bool get nicknameStartWithChar {
    bool startChar = nicknameChars.startsWith(RegExp(r'[a-zA-Z]'));
    return startChar;
  }

  String get profilePicture => getValue('profile_pic', '');

  set profilePicture(String value) {
    setValue('profile_pic', value);
  }

  Relationship get relationship => getEnumType(getValue('relationship', 0));

  set relationship(Relationship value) {
    setValue('relationship', setEnumType(value));
  }

  //手机号
  String get contact => getValue('contact', '');

  set contact(String value) {
    setValue('contact', value);
  }

  //电子邮件
  String get email => getValue('email', '');

  set email(String value) {
    setValue('email', value);
  }

  // 国家代码
  String get countryCode => getValue('country_code', '');

  set countryCode(String value) {
    setValue('country_code', value);
  }

  // 最后上线时间
  int get lastOnline => getValue('last_online', 0);

  set lastOnline(int value) {
    setValue('last_online', value);
  }

  // 好友请求时间
  int get requestTime => getValue('request_at', 0);

  set requestTime(int? value) {
    setValue('request_at', value);
  }

  // 删除帐户时间
  int get deletedAt => getValue('deleted_at', 0);

  set deletedAt(int? value) {
    setValue('deleted_at', value);
  }

  // 用户组标签
  List<String>? get groupTags => getValue('group_tags', <String>[]);

  set groupTags(List<String>? value) {
    setValue('group_tags', value);
  }

  int get incomingSoundId => getValue('incoming_sound_id', 0);

  set incomingSoundId(int v) => setValue('incoming_sound_id', v);

  int get outgoingSoundId => getValue('outgoing_sound_id', 0);

  set outgoingSoundId(int v) => setValue('outgoing_sound_id', v);

  int get notificationSoundId => getValue('notification_sound_id', 0);

  set notificationSoundId(int v) => setValue('notification_sound_id', v);

  int get sendMessageSoundId => getValue('send_message_sound_id', 0);

  set sendMessageSoundId(int v) => setValue('send_message_sound_id', v);

  int get groupNotificationSoundId =>
      getValue('group_notification_sound_id', 0);

  set groupNotificationSoundId(int v) =>
      setValue('group_notification_sound_id', v);

  @transient
  String get remark => getValue("remark", '');

  set remark(String value) {
    setValue('remark', value);
  }

  // 绑定手机 位存储 值=1
  bool get bindMobile {
    int v = getValue('real_person', 0);
    return v & 1 != 0;
  }

  String get displayLastOnline => getValue('displayLastOnline', '');

  set displayLastOnline(String? value) {
    setValue('displayLastOnline', value);
  }

  // 创建时间
  int get createTime => getValue('create_time', 0);

  // 用户简介
  String get publicKey => getValue('public_key', '');

  set publicKey(String value) {
    setValue('public_key', value);
  }

  // 用户简介
  String get profile => getValue('profile', '');

  set profile(String value) {
    setValue('profile', value);
  }

  generateAvatarUrl() {
    String path = "$s3Folder/$uid/${DateTime.now().millisecondsSinceEpoch}";
    return path;
  }

  void destroy() {}

  @override
  setValue(String key, dynamic value) {
    super.setValue(key, value);
    switch (key) {
      case 'voice_file':
        if (_splitList(value).isEmpty) return;
        // voiceSignId = _splitList(value)[0];
        // voiceSignTime = _splitList(value)[1];
        break;
    }
  }

  _splitList(String data) {
    List<int> intData = [];
    if (data != '') {
      List<String> re = data.split(',');
      for (var item in re) {
        int? it = int.tryParse(item);
        if (it != null) {
          intData.add(it);
        }
      }
    }
    return intData;
  }

  ///Desktop Version ====================================================
  bool isSelected = false;
}

getEnumType(int relationship) {
  switch (relationship) {
    case 2:
      return Relationship.self;
    case 1:
      return Relationship.friend;
    case 0:
      return Relationship.stranger;
    case -1:
      return Relationship.sentRequest;
    case -2:
      return Relationship.receivedRequest;
    case -3:
      return Relationship.blocked;
    case -4:
      return Relationship.blockByTarget;
  }
}

setEnumType(Relationship relationship) {
  switch (relationship) {
    case Relationship.self:
      return 2;
    case Relationship.friend:
      return 1;
    case Relationship.stranger:
      return 0;
    case Relationship.sentRequest:
      return -1;
    case Relationship.receivedRequest:
      return -2;
    case Relationship.blocked:
      return -3;
    case Relationship.blockByTarget:
      return -4;
  }
}

const transient = Transient();

class Transient {
  const Transient();
}
