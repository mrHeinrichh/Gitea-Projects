import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';

class GroupAddMemberController extends GetxController {
  /// ============================== VARIABLES =================================
  /// 群聊信息
  Group? group;
  Chat? chat;
  List<User> membersList = [];

  final isMultiplePick = true.obs;

  /// 可选择用户列表
  RxList<User?> userList = RxList();
  RxList<AZItem> azFilterList = <AZItem>[].obs;

  /// 搜索控制器
  final _debouncer = Debounce(const Duration(milliseconds: 400));
  FocusNode searchFocus = FocusNode();
  TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;

  /// 选择成员滚动控制器
  final ScrollController selectedUsersController = ScrollController();

  /// 选中的用户
  RxList<User> selectedUser = <User>[].obs;

  bool isLoading = false;
  List<User> friends = objectMgr.userMgr.filterFriends;

  /// ============================== METHODS ===================================

  GroupAddMemberController();

  GroupAddMemberController.desktop({Group? group, List<User>? membersList}) {
    if (group != null) {
      this.group = group;
    }

    if (membersList != null) {
      this.membersList = membersList;
      userList.value = membersList.toList();
      isMultiplePick.value = false;
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
    final argument = Get.arguments;
    if (argument != null) {
      if (argument['group'] != null) {
        group = argument['group'];
      }

      if (argument['chat'] != null) {
        chat = argument['chat'];
      }

      if (argument['memberList'] != null) {
        membersList = argument['memberList'];
        userList.value = sortList(membersList);

        isMultiplePick.value = false;
      } else {
        final List<int> memberList =
            group!.members.map<int>((e) => e['user_id'] as int).toList();
        userList.value =
            friends.where((e) => !memberList.contains(e.uid)).toList();
      }
    }

    updateAZFriendList();

    if (group == null) Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => onSearch());
  }

  void onSearch() {
    if (isMultiplePick.value) {
      final List<int> memberList =
          group!.members.map<int>((e) => e['user_id'] as int).toList();

      userList.value = friends
          .where((e) => !memberList.contains(e.uid))
          .where((User user) => objectMgr.userMgr
              .getUserTitle(user)
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()))
          .toList();
    } else {
      userList.value = membersList
          .where((member) => member.nickname
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()))
          .toList();
    }

    updateAZFriendList();
  }

  void onSelect(User user) {
    final indexList = selectedUser
        .indexWhere((element) => element.accountId == user.accountId);
    if (indexList > -1) {
      selectedUser.removeWhere(
          (User selectedUser) => selectedUser.accountId == user.accountId);
      selectedUsersController.animateTo(
        selectedUsersController.position.maxScrollExtent - 20,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      int groupMembers = selectedUser.length + group!.members.length;
      if (groupMembers >= 200) {
        Toast.showToast(localized(groupMembersAreLimitedTo200));
        return;
      }
      selectedUser.add(user);
      if (selectedUser.length > 1) {
        selectedUsersController.animateTo(
          selectedUsersController.position.maxScrollExtent + 70,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    // clearSearching();
  }

  void nextButton() {
    if (isMultiplePick.value) {
      onAddMember();
    }
  }

  void onAddMember() async {
    if (selectedUser.isEmpty || isLoading) return;

    isLoading = true;

    try {
      await objectMgr.encryptionMgr.createChatEncryption(selectedUser.map((element) => element.uid).toList(), group!.id, chatKey: chat?.chat_key ?? "");
      final res = await objectMgr.myGroupMgr.addMember(group!.id, selectedUser);
      if (res == 'OK') {
        isLoading = false;
        //must return List of User
        Get.back(
            result: selectedUser, id: objectMgr.loginMgr.isDesktop ? 1 : null);
      } else {
        Toast.showToast(localized(failedToAdd));
        isLoading = false;
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  transferAndLeave(User user) async {
    var isSuccess =
        await objectMgr.myGroupMgr.transferOwnership(group!.id, user.uid);
    if (isSuccess) {
      try {
        await objectMgr.myGroupMgr.leaveGroup(group!.id);

        objectMgr.myGroupMgr.leaveGroupPrefix = 'You have left';
        objectMgr.myGroupMgr.leaveGroupName = group!.name;
        Toast.showToast(localized(groupLeaveGroupSuccessful),
            isStickBottom: false);

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

  void onClickUser(User? user) {
    if (user == null) return;
    if (isMultiplePick.value) {
      onSelect(user);
    } else {
      showDialog(
        context: Get.context!,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: '${localized(warning)}！',
            content: Text(
              '${localized(groupTransferAndLeaveGroup, params: [
                    (user.nickname)
                  ])} ?',
              style: jxTextStyle.textDialogContent(),
              textAlign: TextAlign.center,
            ),
            confirmText: localized(buttonConfirm),
            cancelText: localized(buttonCancel),
            confirmCallback: () {
              transferAndLeave(user);
            },
          );
        },
      );
    }
  }
}
