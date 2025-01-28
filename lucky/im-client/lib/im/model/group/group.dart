import 'dart:convert';

import 'package:jxim_client/data/row_object.dart';

// 群列表类型
const kMyGroup = 1; // -- 我的群

//群枚举
const GROUP_TYPE_QUN = 0; //普通群

enum GroupPermissionMap {
  groupPermissionSendTextVoice(
      1, 'GroupPermissionSendTextVoice', 'sendTextVoicePermission'),
  groupPermissionSendMedia(
      2, 'GroupPermissionSendMedia', 'sendMediaPermission'),
  groupPermissionSendTextStickerEmoji(
      4, 'GroupPermissionSendTextStickerEmoji', 'sendStickerGifPermission'),
  groupPermissionSendDocument(
      8, 'GroupPermissionSendDocument', 'sendDocumentPermission'),
  groupPermissionSendContacts(16, 'GroupPermissionSendContacts', 'sendContactPermission'),
  // groupPermissionSendLocation(32, 'GroupPermissionSendLocation', 'sendLocationPermission'),
  groupPermissionSendRedPacket(
      64, 'GroupPermissionSendRedPacket', 'sendRedPacketPermission'),
  groupPermissionSendLink(
      128, 'GroupPermissionSendLink', 'sendHyperlinkPermission'),
  groupPermissionForwardMessages(
      256, 'GroupPermissionForwardMessages', 'forwardMessagePermission'),
  groupPermissionAddMembers(
      512, 'GroupPermissionAddMembers', 'addMembersPermission'),
  groupPermissionPin(1024, 'GroupPermissionPin', 'pinMessagePermission'),
  groupPermissionChangeChat(
      2048, 'GroupPermissionChangeChat', 'changeGroupInformationPermission'),
  groupPermissionScreenshot(
      4096, 'GroupPermissionScreenshot', 'changeGroupPermissionScreenshot');

  const GroupPermissionMap(this.value, this.name, this.displayNameKey);

  final int value;
  final String name;
  final String displayNameKey;

  bool isAllow(int permission) => (permission & value) != 0;
}

enum GameGroupPermissionMap {
  // value is 2^21
  groupPermissionSendMsg(2097152);

  final int value;

  const GameGroupPermissionMap(this.value);

  bool isAllow(int permission) => (permission & value) != 0;
}

const Map<String, int> adminPermissionMap = <String, int>{
  'GroupAdminPin': 1,
  'GroupAdminChangeGroup': 2,
  'GroupAdminDeleteMessage': 4,
  'GroupAdminManageVideoChat': 8,
  'GroupAdminAddAdmin': 16,
};

class GroupMember extends RowObject {
  int get user_id => getValue('user_id');
  set user_id(int v) => setValue('user_id', v);

  String get user_name => getValue('user_name');
  set user_name(String v) => setValue('user_name', v);

  String get group_alias => getValue('group_alias');
  set group_alias(String v) => setValue('group_alias', v);

  GroupMember();
  static GroupMember creator() {
    return GroupMember();
  }

  GroupMember.fromJson(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (key == 'user_id') {
        setValue('user_id', value);
      } else if (key == 'user_name' && value is String) {
        setValue('user_name', value);
      } else if (key == 'group_alias' && value != null && value is String) {
        setValue('group_alias', value);
      }else {
        setValue(key, value);
      }
    });
  }
}

class Group extends RowObject {
  static const String s3Folder = 'group';

  int get uid => getValue('id');
  set uid(int v) => setValue('id', v);

  int get createTime => getValue('create_time', 0);
  int get updateTime => getValue('update_time', 0);

  int get userJoinDate => getValue('user_join_date', 0);

  /// 群名
  String get name => getValue('name', '');
  set name(String v) => setValue('name', v);

  /// 群描述
  String get profile => getValue('profile', '');
  set profile(String v) => setValue('profile', v);

  /// 群头像
  String get icon => getValue('icon', '');
  set icon(String v) => setValue('icon', v);

  /// 群权限
  int get permission => getValue('permission', 0);
  set permission(int v) => setValue('permission', v);

  /// 管理员权限
  int get admin => getValue('admin', 0);
  set admin(int v) => setValue('admin', v);

  List get members => getValue('members', []);
  set members(List v) => setValue('members', v);

  List<GroupMember> membersList = [];


  int get owner => getValue('owner', 0);
  set owner(int v) => setValue('owner', v);

  List get admins => getValue('admins', []);
  set admins(List v) => setValue('admins', v);

  /// 历史消息是否可见， 0: 不可见 1: 可见
  int get visible => getValue('visible', 0);
  set visible(int v) => setValue('visible', v);

  int get speak_interval => getValue('speak_interval', 0);
  set speak_interval(int v) => setValue('speak_interval', v);

  bool get isVisible => visible == 1;

  Group();

  static Group creator() {
    return Group();
  }

  Group.fromJson(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (key == 'uid') {
        setValue('id', value);
      } else if (key == 'id' && value is String) {
        setValue('id', int.parse(value));
      } else if (key == 'members' && value is String) {
        setValue('members', jsonDecode(value));
      } else if (key == 'admins' && value is String) {
        setValue('admins', jsonDecode(value));
      } else {
        setValue(key, value);
      }
    });
    membersList = [];
    members.forEach((element) {
      membersList.add(GroupMember.fromJson(element));
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'create_time': createTime,
      'update_time': updateTime,
      'user_join_date': userJoinDate,
      'name': name,
      'profile': profile,
      'icon': icon,
      'permission': permission,
      'admin': admin,
      'members': members,
      'owner': owner,
      'admins': admins,
      'visible': visible,
      'speak_interval': speak_interval,
    };
  }

  generateGroupImageUrl() {
    String path = "$s3Folder/$uid/${DateTime.now().millisecondsSinceEpoch}";
    return path;
  }

  removeMembers(List<int> userIds) {
    List<dynamic> members = getValue('members');
    members.removeWhere((v) => userIds.contains(v['user_id']));
  }

  GroupMember? getGroupMemberByMemberID(memberUid){
    for (int i = 0; i < membersList.length; i++){
      if (members[i]['user_id'] == memberUid){
        return members[i];
      }
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (other is Group) {
      other.admins.sort((a, b) => a.compareTo(b));
      this.admins.sort((a, b) => a.compareTo(b));

      other.members.sort((a, b) => a['user_id'].compareTo(b['user_id']));
      this.members.sort((a, b) => a['user_id'].compareTo(b['user_id']));

      return other.uid == uid &&
          other.createTime == createTime &&
          other.updateTime == updateTime &&
          other.userJoinDate == userJoinDate &&
          other.name == name &&
          other.profile == profile &&
          other.icon == icon &&
          other.permission == permission &&
          other.admin == admin &&
          other.admins.join('') == this.admins.join('') &&
          other.members.join('') == this.members.join('') &&
          other.visible == visible &&
          other.owner == owner;
    }

    return false;
  }
}
