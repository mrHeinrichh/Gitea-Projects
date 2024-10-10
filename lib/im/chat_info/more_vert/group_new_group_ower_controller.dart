import 'package:azlistview/azlistview.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';

class SelectNewGroupOwnerController extends GetxController {
  /// ============================== VARIABLES =================================
  /// 群聊信息
  final Group? group;
  final List<User>? membersList;

  /// 可选择用户列表
  RxList<User?> userList = RxList();
  RxList<AZItem> azFilterList = <AZItem>[].obs;

  /// 搜索控制器
  final _debouncer = Debounce(const Duration(milliseconds: 400));
  FocusNode searchFocus = FocusNode();
  TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;

  bool isLoading = false;
  List<User> friends = objectMgr.userMgr.filterFriends;

  /// ============================== METHODS ===================================

  SelectNewGroupOwnerController(this.group, this.membersList);

  SelectNewGroupOwnerController.desktop(this.group, this.membersList) {
    if (membersList != null) {
      userList.value = membersList!.toList();
    } else {
      final List<int> memberList =
          group!.members.map<int>((e) => e['user_id'] as int).toList();
      userList.value =
          friends.where((e) => !memberList.contains(e.uid)).toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (membersList != null) {
      userList.value = sortList(membersList!);
    } else {
      final List<int> memberList =
          group!.members.map<int>((e) => e['user_id'] as int).toList();
      userList.value =
          friends.where((e) => !memberList.contains(e.uid)).toList();
    }

    updateAZFriendList();

    if (group == null) Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => onSearch());
  }

  void onSearch() {
    userList.value = membersList!
        .where(
          (member) => member.nickname
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()),
        )
        .toList();

    updateAZFriendList();
  }

  transferAndLeave(User user) async {
    var isSuccess = await objectMgr.myGroupMgr
        .transferOwnership(group!.id, user.uid, notNeedShowToast: true);
    if (isSuccess) {
      try {
        await objectMgr.myGroupMgr.leaveGroup(group!.id);

        objectMgr.myGroupMgr.leaveGroupPrefix = 'You have left';
        objectMgr.myGroupMgr.leaveGroupName = group!.name;
        // Toast.showToast(localized(groupLeaveGroupSuccessful),
        //     isStickBottom: false);

        Get.back();
      } on AppException catch (e) {
        Toast.showToast(e.getMessage(), isStickBottom: false);
        Get.back();
      }
    }
  }

  ///更新azFriendList列表
  void updateAZFriendList() {
    azFilterList.value = userList
        .map(
          (e) => AZItem(
            user: e!,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();

    SuspensionUtil.setShowSuspensionStatus(azFilterList);
  }

  void clearSearching() {
    isSearching.value = false;
    if (!isSearching.value) {
      searchController.clear();
      searchParam.value = '';
    }
    onSearch();
  }

  List<User?> sortList(List<User> membersList) {
    List<User?> tempList = membersList
        .where((e) => e.deletedAt == 0)
        .map((e) => objectMgr.userMgr.getUserById(e.uid))
        .toList();

    tempList.sort(
      (a, b) => multiLanguageSort(
        objectMgr.userMgr.getUserTitle(a).toLowerCase(),
        objectMgr.userMgr.getUserTitle(b).toLowerCase(),
      ),
    );
    return tempList;
  }

  Future<void> onClickUser(User? user) async {
    if (user == null) return;

    showCustomBottomAlertDialog(
      Get.context!,
      subtitle: localized(chatGroupOwnerLeaveTransferLastCheck),
      confirmText: localized(leaveGroup),
      cancelText: localized(buttonCancel),
      onCancelListener: () {
        Navigator.pop(Get.context!);
      },
      onConfirmListener: () async {
        Get.until((route) => Get.currentRoute == RouteName.home);
        imBottomToast(
          isStickBottom: false,
          Get.context!,
          title: localized(exitTheGroup),
          icon: ImBottomNotifType.timer,
          duration: 5,
          withCancel: true,
          timerFunction: () {
            transferAndLeave(user);
          },
          undoFunction: () {
            BotToast.removeAll(BotToast.textKey);
          },
        );
      },
    );
  }

  List<TextSpan> getTextSpans({
    required String content,
    required TextStyle style,
    bool? isNeedSplit = true,
  }) {
    List<TextSpan> list = [];
    if (isNeedSplit != null && !isNeedSplit) {
      list.add(
        TextSpan(
          text: content,
          style: style,
        ),
      );
      return list;
    }
    List<String> characters = content.split('');
    for (int i = 0; i < characters.length; i++) {
      list.add(
        TextSpan(
          text: characters[i],
          style: style,
        ),
      );
    }
    return list;
  }
}
