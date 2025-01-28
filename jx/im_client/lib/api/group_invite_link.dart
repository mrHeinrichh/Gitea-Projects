import 'package:jxim_client/object/group_invite_link.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<GroupInviteLink> createGroupLink(
  int group_id,
  String? name,
  String link,
  int limited,
  int duration,
) async {
  final Map<String, dynamic> dataBody = {
    "group_id": group_id,
    "name": name,
    "link": link,
    "limited": limited,
    "duration": duration,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/create",
      data: dataBody,
    );
    return GroupInviteLink.fromJson(res.data);
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<List<GroupInviteLink>> getGroupLinks(int group_id) async {
  final Map<String, dynamic> dataBody = {
    "group_id": group_id,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/my",
      data: dataBody,
    );
    if (res.data is List) {
      final list = <GroupInviteLink>[];
      for (var element in res.data) {
        list.add(GroupInviteLink.fromJson(element));
      }
      return list;
    }
    return [];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<GroupInfo?> getGroupInfoByLink(String link) async {
  final Map<String, dynamic> dataBody = {
    "link": link,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/info",
      data: dataBody,
    );
    return GroupInfo.fromJson(res.data);
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    return null;
  }
}

Future<GroupInviteLink> updateGroupLink(
  String name,
  String link,
  int limited,
  int duration,
) async {
  final Map<String, dynamic> dataBody = {
    "name": name,
    "link": link,
    "limited": limited,
    "duration": duration,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/edit",
      data: dataBody,
    );
    return GroupInviteLink.fromJson(res.data);
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<int> deleteGroupLink(String link) async {
  final Map<String, dynamic> dataBody = {
    "link": link,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/delete",
      data: dataBody,
    );
    return res.data;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<bool> joinGroupByLink(int group_id, String link) async {
  final Map<String, dynamic> dataBody = {
    "group_id": group_id,
    "link": link,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/join",
      data: dataBody,
    );
    if (res.code == 20002) {
      throw CodeException(res.code, localized(invitaitonLinkHasExpired), res);
    }
    return res.code == 0;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    if (e.getPrefix() == 20904) {
      Toast.showToast(localized(invitaitonLinkHasExpired));
    } else {
      Toast.showToast(e.getMessage());
    }
    rethrow;
  }
}

Future<int> cancelGroupLink(int link_id) async {
  final Map<String, dynamic> dataBody = {
    "link_id": link_id,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/cancle",
      data: dataBody,
    );
    if (res.data is Map) {
      return 0;
    }
    return 1;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<int> deleteInvalidGroupLink(int group_id) async {
  final Map<String, dynamic> dataBody = {
    "group_id": group_id,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/im/group/link/delete_invalid",
      data: dataBody,
    );
    if (res.data is Map) {
      return 0;
    }
    return 1;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}
