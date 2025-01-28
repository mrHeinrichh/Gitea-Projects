import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/object/block_list_model.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';

class BlockListController extends GetxController {
  final userList = <User>[].obs;

  @override
  void onInit() {
    super.onInit();
    getList();
  }

  getList() async {
    var res = await getBlockList();
    if (res["total_count"] > 0) {
      userList.addAll((res['users'] as List<dynamic>)
          .map((item) => User.fromJson(item))
          .toList());
    }
  }

  unblockUser(User user) async {
    bool success = await objectMgr.userMgr.unblockUser(user);
    if (success) {
      userList.remove(user);
    }
  }

  unblockAllUsers() async {
    List<String> allUUid = [];
    List<User> unblockUserList = [];
    for (User user in userList) {
      allUUid.add(user.accountId);
      unblockUserList.add(user);
    }

    try {
      MassUnblockModel res = await unblockAll(allUUid);
      if (res.relationships!.isNotEmpty) {
        updateUser(unblockUserList, res.relationships);
        userList.clear();
        getBlockList();
      }
    } catch (e) {
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      }
    }
  }

  void updateUser(
      List<User> unblockUserList, Map<String, dynamic>? relationships) {
    for (User user in unblockUserList) {
      if (relationships!.isNotEmpty &&
          relationships.keys.contains(user.accountId)) {
        objectMgr.userMgr.getRemoteUser(user.uid);
      }
    }
  }
}
