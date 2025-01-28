import 'package:azlistview/azlistview.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../api/friends.dart';
import '../../data/db_user.dart';
import '../../home/home_controller.dart';
import '../../managers/call_mgr.dart';
import '../../managers/chat_mgr.dart';
import '../../object/chat/chat.dart';
import '../../object/user.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../component/custom_alert_dialog.dart';

class ContactController extends GetxController
    with GetSingleTickerProviderStateMixin, StateMixin {
  static const String socketContentFriend = 'friend';
  static const String socketContentRequest = 'friend_request';
  CustomPopupMenuController orderController =
      Get.find<CustomPopupMenuController>();
  RxList<User> friendList = <User>[].obs;
  RxList<AZItem> azFriendList = <AZItem>[].obs;
  final newFriendReqList = <User, int>{}.obs;
  final newFriendSentList = <User, int>{}.obs;

  RxBool isChecked = false.obs;
  RxBool isSelectMode = false.obs;
  double previousPixels = 0;
  RxInt isCheckedOrder = 1.obs;
  final isAbleToSelect = true.obs;

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  RxBool showSearchingBar = false.obs;
  RxBool isSearching = false.obs;
  RxString searchParam = ''.obs;

  RxList<String> selectedList = <String>[].obs;

  static const int REJECT_COLLECTION = 1;
  static const int ACCEPT_COLLECTION = 2;
  static const int WITHDRAW_COLLECTION = 3;

  RxBool showSelectIcon = true.obs;
  TabController? tabController;
  List<Tab> friendReqTabs = [
    Tab(text: localized(received)),
    Tab(text: localized(sent))
  ];

  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();

  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  void onInit() {
    super.onInit();
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
    tabController = TabController(length: friendReqTabs.length, vsync: this);
    tabController?.addListener(() {
      isSelectMode.value = false;
      selectedList.clear();
      checkIsAbleToSelect();
      if (tabController?.index == 0)
        showSelectIcon.value = true;
      else
        showSelectIcon.value = false;
    });
  }

  onClose() {
    super.onClose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
  }

  void checkIsAbleToSelect() {
    if (tabController?.index == 0) {
      isAbleToSelect.value = newFriendReqList.values.contains(0);
    } else {
      isAbleToSelect.value = newFriendSentList.values.contains(0);
    }
  }

  ///搜索本地好友列表

  void onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => searchLocal());
  }

  void searchLocal() {
    if (searchParam.value.isNotEmpty) {
      friendList.value = objectMgr.userMgr.friends
          .where((element) => objectMgr.userMgr
              .getUserTitle(element)
              .toLowerCase()
              .contains(searchParam.toLowerCase()))
          .toList();
    } else {
      friendList.value = objectMgr.userMgr.friends;
    }

    updateAZFriendList();
  }

  ///获取朋友列表（线上）
  Future<void> getFriendList() async {
    try {
      final res = await getUserList();
      //  update list from api to localdb
      objectMgr.userMgr
          .onUserChanged(res.map((item) => User.fromJson(item)).toList());
    } catch (e) {
      pdebug(e);
    } finally {
      friendList.value = objectMgr.userMgr.friends;
      updateAZFriendList();
    }
  }

  ///获取朋友申请列表（线上）
  Future<void> getFriendRequestList() async {
    try {
      final res = await friendRequestList();
      List<User> filterFriendList = getFilterFriendRequestList(res);
      objectMgr.userMgr.onUserChanged(filterFriendList);
    } catch (e) {
      pdebug(e);
    } finally {
      refreshFriendRequestList();
    }
  }

  ///获取已发送请求列表（线上）
  Future<void> getFriendSentList() async {
    try {
      final res = await friendAppliedList();
      //  update list from api to localdb
      objectMgr.userMgr
          .onUserChanged(res.map((item) => User.fromJson(item)).toList());
    } catch (e) {
      pdebug(e);
    } finally {
      refreshFriendSentList();
    }
  }

  refreshFriendRequestList() {
    List<User> reqList = objectMgr.userMgr.requestFriends;
    List<int> uidList = reqList.map((user) => user.uid).toList();

    for (User stranger in reqList) {
      bool strangerExist = false;
      for (User user in newFriendReqList.keys) {
        if (user.uid == stranger.uid) {
          newFriendReqList[user] = 0;
          strangerExist = true;
          break;
        }
      }

      if (!strangerExist) {
        newFriendReqList[stranger] = 0;
      }
    }
    newFriendReqList.removeWhere((user, status) => status == 0 && !uidList.contains(user.uid));

    Get.find<HomeController>().requestCount.value = newFriendReqList.entries
        .where((entry) => entry.value == 0)
        .length;
  }

  refreshFriendSentList() {
    List<User> sentList = objectMgr.userMgr.appliedFriends;
    List<int> uidList = sentList.map((user) => user.uid).toList();

    for (User stranger in sentList) {
      bool strangerExist = false;
      for (User user in newFriendSentList.keys) {
        if (user.uid == stranger.uid) {
          if (stranger.relationship == Relationship.sentRequest){
            newFriendSentList[user] = 0;
          }
          strangerExist = true;
          break;
        }
      }

      if (!strangerExist) {
        newFriendSentList[stranger] = 0;
      }
    }

    /// remove invalid request
    newFriendSentList.removeWhere((user, status) => status == 0 && !uidList.contains(user.uid));
  }

  ///检查相机权限
  checkCameraPermission() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }
    final PermissionStatus status = await Permission.camera.status;
    if (status.isGranted) {
      Get.toNamed(RouteName.qrCodeScanner);
    } else {
      final bool rationale = await Permission.camera.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied)
        openAppSettings();
      else {
        final PermissionStatus status = await Permission.camera.request();
        if (status.isGranted) Get.toNamed(RouteName.qrCodeScanner);
        if (status.isPermanentlyDenied) openAppSettings();
      }
    }
  }

  ///单个接受好友
  Future<void> acceptFriend(User user) async {
    objectMgr.userMgr.acceptFriend(user);
    updateFriendRequest(user, 1);
    checkIsAbleToSelect();
  }

  ///单个拒绝好友
  Future<void> rejectFriend(User user) async {
    objectMgr.userMgr.rejectFriend(user);
    updateFriendRequest(user, 2);
    checkIsAbleToSelect();
  }

  ///取消已发出的好友请求
  Future<void> withdrawRequest(User user) async {
    withdrawFriendRequest(user: user);
    updateFriendRequest(user,1, isFriendRequest: false);
    checkIsAbleToSelect();
  }

  void clearProcessedFriendRequest() {
    newFriendReqList.removeWhere((user, value) => value != 0);
    newFriendSentList.removeWhere((user, value) => value != 0);
  }

  updateFriendRequest(User user, int status, {bool isFriendRequest = true}) {
    if (isFriendRequest) {
      for(User userReq in newFriendReqList.keys){
        if (userReq.uid == user.uid) {
          newFriendReqList[userReq] = status;
          break;
        }
      }
    } else {
      for (User userReq in newFriendSentList.keys) {
        if (userReq.uid == user.uid) {
          newFriendSentList[userReq] = status;
          break;
        }
      }
    }
  }

  ///更换选择模式
  void changeSelectMode() {
    isSelectMode(!isSelectMode.value);
    if (!isSelectMode.value) {
      selectedList.clear();
    }
  }

  ///在多选模式，选择对象
  void selectUser(String uuid) {
    if (selectedList.contains(uuid)) {
      selectedList.remove(uuid);
    } else {
      selectedList.add(uuid);
    }
  }

  /// 好友申请列表多选择
  Future<void> friendListAction(int type) async {
    /// 先update view 以防user 看到灰圈圈
    isSelectMode(false);
    ///被选择的对象
    final List<User> selectedFriendReqList = newFriendReqList.keys
        .where((friend) => selectedList.contains(friend.accountId))
        .toList();

    ///成功对象的数量
    int successAmount = 0;

    ///失败对象的数量
    int rejectedAmount = 0;

    ///超出好友的名额
    int excessAmount = 0;
    ///接受所有被选择对象
    if (type == ACCEPT_COLLECTION) {
      try {
        final res = await acceptFriendList(userList: selectedList);

        successAmount = res["success_count"];
        rejectedAmount = res["rejected_uuids"].length;
        excessAmount = res["friend_list_full_count"];

        ///如果有接受成功的用户
        if (successAmount > 0) {
          for (String uuid in res["success_uuids"]) {
            final int index = selectedFriendReqList
                .indexWhere((element) => element.accountId == uuid);
            //更改指定用户的关系为好友
            selectedFriendReqList[index].relationship = Relationship.friend;
            for (User user in newFriendReqList.keys) {
              if (user.uid == selectedFriendReqList[index].uid) {
                newFriendReqList[user] = 1;
                break;
              }
            }
          }
          Toast.showToast(
            "${localized(contactYouHaveAccepted)} $successAmount ${successAmount > 1 ? localized(moreFriendRequest) : localized(friendRequest)}",
            duration: const Duration(milliseconds: 1000),
          );
          await Future.delayed(const Duration(seconds: 1));
        }

        ///如果有接受失败的用户
        if (rejectedAmount > 0) {
          for (String uuid in res["rejected_uuids"]) {
            final int index = selectedFriendReqList
                .indexWhere((element) => element.accountId == uuid);
            //更改指定用户关系为陌生人
            selectedFriendReqList[index].relationship = Relationship.stranger;
            for (User user in newFriendReqList.keys) {
              if (user.uid == selectedFriendReqList[index].uid) {
                newFriendReqList[user] = 0;
                break;
              }
            }
          }
          Toast.showToast(
            "$rejectedAmount ${friendHasNotBeenAddedListFull}",
            duration: const Duration(milliseconds: 1000),
          );
          await Future.delayed(const Duration(seconds: 1));
        }

        if (excessAmount > 0) {
          Toast.showToast(
            "${localized(yourFriendListIsFull)}, $excessAmount ${localized(friendHasNotBeenAdded)}",
            duration: const Duration(milliseconds: 1000),
          );
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        if (e is AppException) {
          Toast.showToast(e.getMessage());
        } else {
          pdebug(e);
        }
      }
    }

    ///拒绝所有被选择对象
    else if (type == REJECT_COLLECTION) {
      try {
        final res = await rejectFriendList(userList: selectedList);

        successAmount = res["success_count"];

        ///有成功拒绝的用户
        if (successAmount > 0) {
          for (String uuid in res["success_uuids"]) {
            final int index = selectedFriendReqList
                .indexWhere((element) => element.accountId == uuid);
            //更改指定用户的关系为陌生人
            selectedFriendReqList[index].relationship = Relationship.stranger;
            for (User user in newFriendReqList.keys) {
              if (user.uid == selectedFriendReqList[index].uid) {
                newFriendReqList[user] = 2;
                break;
              }
            }
          }
          Toast.showToast(
            "${localized(youHaveRejected)} $successAmount ${successAmount > 1 ? localized(moreFriendRequest) : localized(friendRequest)}",
            duration: const Duration(milliseconds: 1000),
          );
        }
      } catch (e) {
        if (e is AppException) {
          Toast.showToast(e.getMessage());
        } else {
          mypdebug(e);
        }
      }
    } else if (type == WITHDRAW_COLLECTION) {
      try {
        List<User> selectedFriendReqList = newFriendSentList.keys
            .where((friend) => selectedList.contains(friend.accountId))
            .toList();
        final res = await withdrawFriendList(userList: selectedList);

        successAmount = res["success_count"];

        ///有成功拒绝的用户
        if (successAmount > 0) {
          for (String uuid in res["success_uuids"]) {
            final int index = selectedFriendReqList
                .indexWhere((element) => element.accountId == uuid);
            //更改指定用户的关系为陌生人
            selectedFriendReqList[index].relationship = Relationship.stranger;
            for (User user in newFriendSentList.keys) {
              if (user.uid == selectedFriendReqList[index].uid) {
                newFriendSentList[user] = 1;
                break;
              }
            }
          }
          Toast.showToast(
            "${localized(youHaveWithdraw)} $successAmount ${successAmount > 1 ? localized(moreFriendRequest) : localized(friendRequest)}",
            duration: const Duration(milliseconds: 1000),
          );
        }
      } catch (e) {
        if (e is AppException) {
          Toast.showToast(e.getMessage());
        } else {
          mypdebug(e);
        }
      }
    }
    selectedList.clear();
    checkIsAbleToSelect();

    ///因为没有socket更新，所以需要直接更改本地数据库
    objectMgr.userMgr.onUserChanged(selectedFriendReqList, notify: true);

    if (newFriendReqList.isEmpty) {
      isSelectMode.value = false;
    }
    selectedList.value = [];
  }

  ///清空搜索的flag
  void clearSearching() async {
    isSearching.value = false;
    if (!isSearching.value) {
      searchController.clear();
      searchParam.value = '';
    }
    searchLocal();
  }

  ///更新数据库通知
  void _onUserUpdate(Object sender, Object type, Object? data) {
    friendList.value = objectMgr.userMgr.friends;
    refreshFriendRequestList();
    refreshFriendSentList();
    updateAZFriendList();
    checkIsAbleToSelect();
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (data is List<User>) {
      data.forEach((dataUser) {
        final existingIndex =
            azFriendList.indexWhere((item) => item.user.uid == dataUser.uid);

        if (existingIndex != -1) {
          friendList[existingIndex].lastOnline = dataUser.lastOnline;
          azFriendList[existingIndex].user.lastOnline = dataUser.lastOnline;
          friendList.refresh();
          azFriendList.refresh();
        }
      });
      updateAZFriendList();
    }
  }

  ///Desktop Version ====================================================
  final FocusNode focusNode = FocusNode();

  // Rxn<User> selectedUser = Rxn<User>();
  final selectedUserUID = 101010.obs;

  ///更新azFriendList列表
  void updateAZFriendList() {
    /// 排序
    int? index = isCheckedOrder.value;
    if (index == 0) {
      //时间排序
      friendList.value = friendListSortByTime();
    } else {
      //姓名排序
      friendList.value = friendListSortByName();
    }
    azFriendList.value = friendList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(azFriendList);
  }

  void contactSortClick(int index) {
    objectMgr.localStorageMgr.write(LocalStorageMgr.CONTACT_SORT, index);
    updateAZFriendList();
  }

  /// 时间排序
  List<User> friendListSortByTime() {
    List<User> friendListCopy = List.from(friendList);
    List<User> list = friendListCopy
      ..sort((a, b) => b.lastOnline.compareTo(a.lastOnline));
    return list;
  }

  /// 名字排序
  List<User> friendListSortByName() {
    List<User> friendListCopy = List.from(friendList);
    List<User> listChars = [];
    List<User> listOther = [];

    for (var usr in friendListCopy) {
      if (usr.nicknameStartWithChar) {
        listChars.add(usr);
      } else {
        listOther.add(usr);
      }
    }

    listChars..sort((a, b) => a.nicknameChars.compareTo(b.nicknameChars));

    List<User> list = [];
    list.addAll(listChars);
    list.addAll(listOther);
    return list;
  }

  /// redirect to chat room
  Future<void> redirectToChat(BuildContext context, int id) async {
    try {
      Chat? chat = await objectMgr.chatMgr.getChatByFriendId(id);
      if (chat != null) {
        if (Get.isRegistered<SingleChatController>(tag: chat.id.toString())) {
          Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
        } else {
          if (objectMgr.loginMgr.isDesktop) {
            Routes.toChatDesktop(chat: chat);
          } else {
            Routes.toChat(
              chat: chat,
              popCurrent: Get.currentRoute != RouteName.home,
            );
          }
        }
      } else {
        Get.toNamed(RouteName.chatInfo,
            arguments: {"uid": id, "id": id});
      }
    } catch (e) {
      pdebug(e);
    }
  }

  void getSortType() {
    isCheckedOrder.value =
        objectMgr.localStorageMgr.read(LocalStorageMgr.CONTACT_SORT) ?? 1;
    updateAZFriendList();
  }

  /// 获取好友请求
  List<User> getFilterFriendRequestList(List res) {
    List<User> tempFriendRequestList = objectMgr.userMgr.requestFriends;
    List<User> list = [];
    List<int> idList = [];

    if (tempFriendRequestList.length > 0) {
      for (var item in res) {
        User user = User.fromJson(item);
        idList.add(user.id);
      }

      for (User user in tempFriendRequestList) {
        if (!idList.contains(user.id)) {
          /// 移除被离线撤回的好友请求
          user.relationship = Relationship.stranger;
          list.add(user);
        } else {
          final tempList = res.map((item) => User.fromJson(item)).toList();
          final tempUser = tempList.where((item) => item.uid == user.id).first;
          list.add(tempUser);
        }
      }
    } else {
      list = res.map((item) => User.fromJson(item)).toList();
    }

    return list;
  }

  Future<void> findContact(BuildContext context) async {
    clearSearching();
    final permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      if (await Permission.contacts.isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: localized(contactAccessContacts),
              content: Text(
                localized(contactAccessDesc),
                style: jxTextStyle.textDialogContent(),
                textAlign: TextAlign.center,
              ),
              confirmText: localized(homeSetting),
              cancelText: localized(buttonCancel),
              confirmColor: accentColor,
              confirmCallback: () => openAppSettings(),
            );
          },
        );
      } else {
        await Permission.contacts.request().isGranted;
        if (await Permission.contacts.isGranted) {
          Get.toNamed(RouteName.localContactView);
        }
      }
    } else {
      Get.toNamed(RouteName.localContactView);
    }
  }
}
