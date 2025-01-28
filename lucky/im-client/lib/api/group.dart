// ignore_for_file: non_constant_identifier_names

import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';

//创建群组
//"icon":"0",
//"name":"aabbgeddf",
//"profile":"0",
//"group_type":"0"
Future<Group> create({
  required String name,
  required String icon,
}) async {
  final data = <String, dynamic>{};
  data["name"] = name;
  data["icon"] = '';

  try {
    final ResponseData res = await Request.doPost(
      "/im/group/create",
      data: data,
    );

    if (res.success()) {
      return Group.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

//修改群名/头像/描述
Future<Map<String, dynamic>> edit({
  required int groupID,
  String? name,
  String? icon,
  String? profile,
  required int newGroup,
}) async {
  final data = <String, dynamic>{};
  data["group_id"] = groupID;
  data['new_group'] = newGroup;
  if (name != null) data['name'] = name;
  if (icon != null) data['icon'] = icon;
  if (profile != null) data['profile'] = profile;

  try {
    final ResponseData res = await Request.doPost(
      "/im/group/edit",
      data: data,
    );

    if (res.success()) {
      return res.data;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<String> addGroupMember(
    {required int groupId, required List<int> userIds}) async {
  final data = <String, dynamic>{};
  data['group_id'] = groupId;
  data['members'] = userIds;

  try {
    final ResponseData res = await Request.doPost(
      "/im/group/add_members",
      data: data,
    );

    if (res.success()) {
      return res.message;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

/// 获取群组详情
/// data: {"id":756,"name":"Group 17","profile":"0","icon":0,"permission":127,"admin":31,"visible":0,"create_time":1677471818}
Future<ResponseData> getGroupInfo(int groupId) async => await Request.doPost(
      "/im/group/get",
      data: {
        'group_id': groupId,
      },
    );

/// 获取共同群组 数据
Future<ResponseData> getCommonGroup(int userId) async {
  try {
    final ResponseData res = await Request.doPost('/im/group/common_group',
        data: {'user_id': userId});
    if (res.success()) {
      return res;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

/// 获取群成员 数据
/// 返回*
/// data:
/// user_id 群成员id
/// user_name: 群成员名字
Future<ResponseData> getGroupMember(int groupId) async =>
    await Request.doPost("/im/group/members", data: {
      'group_id': groupId,
    });

/// 添加管理员
Future<ResponseData> addAdmins({
  required int groupId,
  required List<int> admins,
}) =>
    Request.doPost("/im/group/add_admins", data: {
      'group_id': groupId,
      'admins': admins,
    });

/// 移除管理员
Future<ResponseData> deleteAdmins({
  required int groupId,
  required List<int> admins,
}) =>
    Request.doPost("/im/group/del_admins", data: {
      'group_id': groupId,
      'admins': admins,
    });

/// 剔除成员
Future<ResponseData> kickMembers({
  required int groupId,
  required List<int> members,
}) async =>
    Request.doPost("/im/group/kick_members", data: {
      'group_id': groupId,
      'members': members,
    });

// 退群
Future<ResponseData> leaveGroup({
  required int groupId,
}) async =>
    Request.doPost("/im/group/leave", data: {
      'group_id': groupId,
    });

// 解散群
Future<ResponseData> dismissGroup({
  required int groupId,
}) async =>
    Request.doPost("/im/group/dismiss", data: {
      'group_id': groupId,
    });

/// 转移群主
/// [groupId] 群id
/// [userId] 转移的用户id
Future<ResponseData> transferOwnership({
  required int groupId,
  required int userId,
}) async =>
    Request.doPost("/im/group/transfer_owner", data: {
      'group_id': groupId,
      'new_owner': userId,
    });

/// 更新群成员权限
Future<ResponseData> updateGroupPermission({
  required int groupId,
  required int permission,
  int type = 0, // 0: 普通群, 1: 認證群
}) async {
  dynamic data = {};
  data['group_id'] = groupId;
  data['set_type'] = type;
  data['permission'] = permission;

  final res = Request.doPost("/im/group/set_permission", data: data);

  return res;
}

//设置发言间隔
Future<ResponseData> setSpeakInterval({
  required int groupId,
  required int interval,
}) async {
  dynamic data = {};
  data['group_id'] = groupId;
  data['interval'] = interval;

  final res = Request.doPost("/im/group/set_speak_interval", data: data);

  return res;
}

/// 设置新成员查看历史消息
Future<ResponseData> viewHistory(int groupId, int visible) async =>
    await Request.doPost(
      "/im/group/set_history_visible",
      data: {'group_id': groupId, 'visible': visible},
    );

const reportTypeUser = 0; //举报用户
const reportTypeGroup = 1; //举报群
const reportTypePost = 2; //举报动态
const reportTypeActivity = 3; //举报活动
const reportTypeAppraise = 4; //举报评价
const reportTypeReply = 5; //举报评价回复
const reportTypeAdvert = 6; //举报广告
const reportTypeDiscuss = 7; //举报讨论组

//投诉
Future<HttpResponseBean> report({
  required int reportId,
  required int type,
  required String reasons,
  required String content,
  required String pics,
  String? reportName,
}) async {
  dynamic data = {};
  data['report_id'] = reportId;
  data['type'] = type;
  data['reasons'] = reasons;
  data['content'] = content;
  data['pics'] = pics;
  // data['report_name'] = reportName;
  return Request.send("/report/create",
      method: Request.methodTypePost, data: data);
}

//移除自定义表情包
//url  表情包id
Future<HttpResponseBean> deleMyEmoji({
  required String id,
}) async {
  dynamic data = {};
  data["id"] = id;
  return Request.send("/im/myemoj/remove_myemoj",
      method: Request.methodTypePost, data: data);
}

//查询自定义表情包
Future<HttpResponseBean> queryEmoji() async {
  dynamic data = {};
  return Request.send("/im/myemoj/query_myemoj",
      method: Request.methodTypePost, data: data);
}

//查询自定义表情包总数
Future<HttpResponseBean> emojiCount() async {
  dynamic data = {};
  return Request.send("/myemoj/myemoj_count",
      method: Request.methodTypePost, data: data);
}
