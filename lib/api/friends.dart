import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/install_info.dart';
import 'package:jxim_client/object/add_friend_request_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/object/block_list_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<Map> sendFriendRequest({String? uuid, String? remark}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  if (notBlank(remark)) {
    dataBody["remark"] = remark;
  }
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/create", data: dataBody);

    if (res.success()) {
      return res.data;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<bool> withdrawFriendRequest({
  User? user,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = user?.accountId;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/cancel", data: dataBody);

    if (res.success()) {
      return true;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_NOT_EXIST) {
      if (user != null) {
        user.relationship = Relationship.stranger;
        if (user.relationship == Relationship.stranger) user.alias = '';
        objectMgr.userMgr.onUserChanged([user], notify: true);
      }
    } else {
      Toast.showToast(e.getMessage());
    }
    rethrow;
  }
}

Future<bool> deleteFriend({
  String? uuid,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/remove", data: dataBody);
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<bool> acceptFriendRequest({String? uuid, String? secretUrl}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  if (secretUrl != null) {
    dataBody["secret"] = secretUrl;
  }
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/accept", data: dataBody);
    return res.success();
  } on AppException {
    // 请求过程中的异常处理
    // ImBottomToast(navigatorKey.currentContext!,
    //     title: e.getMessage(),
    //     icon: ImBottomNotifType.warning);
    rethrow;
  }
}

Future<bool> rejectFriendRequest({
  String? uuid,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/reject", data: dataBody);
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<GetFriendRequestModel> getFriendSecret(int? duration) async {
  Map<String, dynamic> dataBody = {};
  dataBody["duration"] = duration;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/contact/get-friend-secret",
      data: dataBody,
    );
    if (res.success()) {
      return GetFriendRequestModel.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<Map> friendAllRequestList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/contact/list-all",
    );
    if (res.success()) {
      return res.data;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<List> friendRequestList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/contact/request_list",
    );
    if (res.success()) {
      return res.data["users"];
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<List> friendAppliedList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/contact/sent-list",
    );
    if (res.success()) {
      return res.data["users"];
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<List> getUserList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/contact",
    );

    if (res.success()) {
      return res.data["users"];
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<Map<String, dynamic>> searchUser({
  required String param,
  required int offset,
}) async {
  final Map<String, dynamic> dataBody = {};
  const url = "/app/api/account/search";
  //query limit offset
  // limit is 20, first page is offset 0 second page is offset 20

  dataBody['query'] = param;
  dataBody['offset'] = offset;
  dataBody['limit'] = 20;

  try {
    final ResponseData res = await CustomRequest.doGet(
      url,
      data: dataBody,
    );

    if (res.success()) {
      return res.data;
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<List> createLocalContact({
  required List<Map<String, dynamic>>? list,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["data"] = list;
  try {
    final res = await CustomRequest.doPost(
      "/app/api/account/search-from-phonebook",
      data: dataBody,
    );
    return res.data ?? [];
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<List<User>> getUsersByUID({
  required List<int> uidList,
  int maxTry = 3,
}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["uid"] = uidList;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/account/request-info',
      data: dataBody,
      maxTry: maxTry,
    );

    if (res.success()) {
      return List<User>.from(res.data.map((x) => User.fromJson(x)));
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<Map<String, dynamic>> acceptFriendList({List<String>? userList}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuids"] = userList;
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/contact/mass-accept",
        data: dataBody);
    return res.data;
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<Map<String, dynamic>> rejectFriendList({List<String>? userList}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuids"] = userList;
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/contact/mass-reject",
        data: dataBody);
    return res.data;
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<Map<String, dynamic>> withdrawFriendList({
  List<String>? userList,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuids"] = userList;
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/contact/mass-cancel",
        data: dataBody);
    return res.data;
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<bool> editFriendNickname({
  required String uuid,
  required String alias,
  List<String> groupTags = const [],
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  dataBody["nickname"] = alias;
  dataBody["group_tags"] = groupTags;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/edit", data: dataBody);
    return res.success();
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<bool> doBlockUser(String uuid) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/block", data: dataBody);
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<bool> doUnblockUser(String uuid) async {
  Map<String, dynamic> dataBody = {};
  dataBody["target_uuid"] = uuid;
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/contact/unblock", data: dataBody);
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<Map<String, dynamic>> getBlockList() async {
  try {
    final ResponseData res =
        await CustomRequest.doGet("/app/api/contact/block-list");
    return res.data;
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<MassUnblockModel> unblockAll(List<String> uuidList) async {
  try {
    Map<String, dynamic> dataBody = {};
    dataBody["target_uuids"] = uuidList;
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/contact/mass-unblock",
        data: dataBody);
    if (res.success()) {
      return MassUnblockModel.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<InstallInfo> getDownloadUrl({int? chatId}) async {
  final Map<String, dynamic> dataBody = {};
  if (chatId != null) {
    dataBody["group_id"] = chatId;
  }

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/contact/get-open-install-secret',
      data: dataBody,
    );
    if (res.success()) {
      return InstallInfo.fromJson(res.data);
    } else {
      throw ('${res.message}(${res.code})');
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}
