import 'dart:collection';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/utility.dart';

class FriendListBottomSheetController extends GetxController {
  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;
  FocusNode searchFocus = FocusNode();

  RxList<User> userList = <User>[].obs;
  RxList<AZItem> azFilterList = <AZItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    getFriendList();
    updateAZFriendList();
  }

  /// ==================== 搜索功能 ===================///
  void onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => searchLocal());
  }

  void searchLocal() {
    userList.value = objectMgr.userMgr.friendWithoutBlacklist
        .where((User user) => objectMgr.userMgr
            .getUserTitle(user)
            .toLowerCase()
            .contains(searchParam.value.toLowerCase()))
        .toList();
    updateAZFriendList();
  }

  void clearSearching() {
    searchController.clear();
    isSearching.value = false;
    searchParam.value = '';
    searchLocal();
  }

  /// ==================== 朋友列表 ===================///
  void getFriendList() {
    userList.value = objectMgr.userMgr.filterFriends;
  }

  void updateAZFriendList() {
    azFilterList.value = userList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();

    SuspensionUtil.setShowSuspensionStatus(azFilterList);
  }

  List<String> filterIndexBar() {
    if (isSearching.value || searchParam.isNotEmpty) {
      return [];
    }
    List<String> indexList = [];

    for (AZItem item in azFilterList) {
      String tag = item.tag;
      bool startChar = tag.startsWith(RegExp(r'[a-zA-Z]'));
      if (startChar) {
        indexList.add(tag);
      }
    }
    List<String> resultList = LinkedHashSet<String>.from(indexList).toList();
    resultList.add('#');
    return resultList;
  }
}
