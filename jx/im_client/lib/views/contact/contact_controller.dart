import 'dart:convert';

import 'package:azlistview/azlistview.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_view.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

  RxList<FriendShipItem> requestFriendUserList = <FriendShipItem>[].obs;

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
  final showSearchOverlay = false.obs;

  RxList<String> selectedList = <String>[].obs;

  static const int REJECT_COLLECTION = 1;
  static const int ACCEPT_COLLECTION = 2;
  static const int WITHDRAW_COLLECTION = 3;

  RxBool showSelectIcon = true.obs;
  TabController? tabController;
  List<Tab> friendReqTabs = [
    Tab(text: localized(received)),
    Tab(text: localized(sent)),
  ];

  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();

  final ItemScrollController itemScrollController = ItemScrollController();

  /// 悬浮小窗参数
  OverlayEntry? floatWindowOverlay;
  Widget? overlayChild;
  final LayerLink layerLink = LayerLink();
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;
  GlobalKey moreVertKey = GlobalKey();
  GlobalKey notificationKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.onlineMgr.on(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    tabController = TabController(length: friendReqTabs.length, vsync: this);
    tabController?.addListener(() {
      isSelectMode.value = false;
      selectedList.clear();
      checkIsAbleToSelect();
      showSelectIcon.value = tabController?.index == 0 ? true : false;
    });
  }

  @override
  onClose() {
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.onlineMgr.off(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    super.onClose();
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
          .where(
            (element) => objectMgr.userMgr
                .getUserTitle(element)
                .toLowerCase()
                .contains(searchParam.toLowerCase()),
          )
          .toList();
      showSearchOverlay.value = false;
    } else {
      friendList.value = objectMgr.userMgr.friends;
      if (isSearching.value) {
        showSearchOverlay.value = true;
      }
    }

    updateAZFriendList();
  }

  ///获取朋友列表（线上）
  Future<void> getFriendList() async {
    await objectMgr.userMgr.getRemoteFriendList(ignore_blacklist_check: 1);
    friendList.value = objectMgr.userMgr.friends;
    updateAZFriendList();
  }

  /// 获取朋友所有请求的数据，包括我请求的 对方请求的等等
  Future<void> getFriendAllRequestList() async {
    await objectMgr.userMgr.getRemoteFriendRequestList();
    refreshFriendRequestPage();
  }

  /// 未读的好友请求数
  int unreadCount() {
    var count = requestFriendUserList
        .where((entry) => entry.state == MessageState.recievedFriendRequest)
        .length;
    return count;
  }

  /// 刷新请求页面的所有数据状态
  refreshFriendRequestPage() {
    Map<String, Map<User, MessageState>> result =
        FriendShipUtils.getRequestUserPageData();
    var verifyingUserList = result['verifying']!;
    var verifiedUserList = result['verified']!;
    List<FriendShipItem> tempListVerifying = [];
    List<FriendShipItem> tempListVerified = [];

    for (var element in verifyingUserList.entries) {
      var friendShipItem = FriendShipItem(
        user: element.key,
        isUser: true,
        title: "",
        state: element.value,
      );
      tempListVerifying.add(friendShipItem);
    }
    if (tempListVerifying.isNotEmpty) {
      tempListVerifying
          .sort((a, b) => b.user.requestTime.compareTo(a.user.requestTime));
      tempListVerifying.insert(
        0,
        FriendShipItem(
          user: User(),
          isUser: false,
          title: localized(contactVerifying),
          state: MessageState.unKnown,
        ),
      );
    }

    for (var element in verifiedUserList.entries) {
      var friendShipItem = FriendShipItem(
        user: element.key,
        isUser: true,
        title: "",
        state: element.value,
      );
      tempListVerified.add(friendShipItem);
    }
    if (tempListVerified.isNotEmpty) {
      tempListVerified
          .sort((a, b) => b.user.requestTime.compareTo(a.user.requestTime));
      tempListVerified.insert(
        0,
        FriendShipItem(
          user: User(),
          isUser: false,
          title: localized(contactVerified),
          state: MessageState.unKnown,
        ),
      );
    }

    tempListVerifying.addAll(tempListVerified);
    requestFriendUserList.value = tempListVerifying;
    Get.find<HomeController>().requestCount.value = unreadCount();
  }

  ///检查相机权限
  checkCameraPermission() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }
    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;
    Get.toNamed(RouteName.qrCodeScanner);
  }

  ///取消已发出的好友请求
  Future<void> withdrawRequest(User user) async {
    objectMgr.userMgr.withdrawFriend(user);
    updateFriendRequest(user, 1, isFriendRequest: false);
    checkIsAbleToSelect();
  }

  ///删除
  Future<void> deleteFriendRequestPageFriend(User user) async {
    objectMgr.userMgr.deleteCheckedMessage(user);
    checkIsAbleToSelect();
  }

  void clearProcessedFriendRequest() {
    newFriendReqList.removeWhere((user, value) => value != 0);
    newFriendSentList.removeWhere((user, value) => value != 0);
  }

  updateFriendRequest(User user, int status, {bool isFriendRequest = true}) {
    if (isFriendRequest) {
      for (User userReq in newFriendReqList.keys) {
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
            duration: 1,
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
            "$rejectedAmount $friendHasNotBeenAddedListFull",
            duration: 1,
          );
          await Future.delayed(const Duration(seconds: 1));
        }

        if (excessAmount > 0) {
          Toast.showToast(
            "${localized(yourFriendListIsFull)}, $excessAmount ${localized(friendHasNotBeenAdded)}",
            duration: 1,
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
            duration: 1,
          );
        }
      } catch (e) {
        if (e is AppException) {
          Toast.showToast(e.getMessage());
        } else {
          pdebug(e);
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
            duration: 1,
          );
        }
      } catch (e) {
        if (e is AppException) {
          Toast.showToast(e.getMessage());
        } else {
          pdebug(e);
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
    refreshFriendRequestPage();
    updateAZFriendList();
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) async {
    if (data is List<User>) {
      for (var user in data) {
        final existingIndex =
            azFriendList.indexWhere((item) => item.user.uid == user.uid);
        if (existingIndex != -1) {
          friendList[existingIndex].lastOnline = user.lastOnline;
          azFriendList[existingIndex].user.lastOnline = user.lastOnline;
          friendList.refresh();
          azFriendList.refresh();
          //updateAZFriendList();
        }
      }
    }
  }

  ///Desktop Version ====================================================
  final FocusNode focusNode = FocusNode();

  // Rxn<User> selectedUser = Rxn<User>();
  final selectedUserUID = 101010.obs;

  ///更新azFriendList列表 这个就是是更新好友列表
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
    isCheckedOrder.value = index;
    objectMgr.localStorageMgr.write(LocalStorageMgr.CONTACT_SORT, index);
    updateAZFriendList();
  }

  /// 时间排序
  List<User> friendListSortByTime() {
    List<User> friendListCopy = List.from(friendList);
    List<User> list = friendListCopy
      ..sort((a, b) {
        if (a.deletedAt > 0 && b.deletedAt > 0) {
          // Both deleted
          return 0;
        } else if (a.deletedAt > 0) {
          // place after 'b'
          return 1;
        } else if (b.deletedAt > 0) {
          // place after 'a'
          return -1;
        } else {
          // No deleted account, sort by lastOnline
          return b.lastOnline.compareTo(a.lastOnline);
        }
      });
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

    listChars.sort((a, b) => a.nicknameChars.compareTo(b.nicknameChars));

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
            Routes.toChat(chat: chat);
          } else {
            Routes.toChat(
              chat: chat,
              popCurrent: Get.currentRoute != RouteName.home,
            );
          }
        }
      } else {
        Get.toNamed(RouteName.chatInfo, arguments: {"uid": id, "id": id});
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

    //~~~ Josh
    if (res.length > tempFriendRequestList.length) {
      List<User> userRes = res.map((e) => User.fromJson(e)).toList();
      objectMgr.userMgr.onUserChanged(userRes, notify: true);
      tempFriendRequestList = objectMgr.userMgr.requestFriends;
    }

    if (tempFriendRequestList.isNotEmpty) {
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

  void findContact(BuildContext context) async {
    clearSearching();
    Get.toNamed(RouteName.localContactView, preventDuplicates: false);
  }

  /// 从底部弹出一个页面
  void showBottomModal(BuildContext context, Widget myPage) {
    var topSafeHeight = MediaQuery.of(context).padding.top + 20;
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(top: topSafeHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            height: MediaQuery.of(context).size.height - topSafeHeight,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: myPage,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
    );
  }

  showPopUpMenu(BuildContext context) {
    floatWindowRender =
        notificationKey.currentContext!.findRenderObject() as RenderBox;

    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
    } else {
      final List<ToolOptionModel> menuOptions = [
        ToolOptionModel(
          title: localized(lastOnline),
          optionType: ContactPageMenu.lastOnline.optionType,
          isShow: true,
          tabBelonging: 7,
          imageUrl: isCheckedOrder.value == 0 ? 'assets/svgs/check1.svg' : null,
        ),
        ToolOptionModel(
          title: localized(name),
          optionType: ContactPageMenu.name.optionType,
          isShow: true,
          tabBelonging: 7,
          imageUrl: isCheckedOrder.value == 1 ? 'assets/svgs/check1.svg' : null,
        ),
      ];

      vibrate();
      bool isMandarin =
          AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();
      double maxWidth = objectMgr.loginMgr.isDesktop
          ? 300
          : isMandarin
              ? 220
              : 220;
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);
      overlayChild = MoreVertView(
        optionList: menuOptions,
        func: () {
          closeMenu();
        },
      );
      floatWindowOverlay = createOverlayEntry(
        shouldBlurBackground: false,
        context,
        Container(
          width: floatWindowRender!.size.width,
          height: floatWindowRender!.size.height,
          color: colorBackground,
          child: Text(
            localized(sort),
            style: jxTextStyle.headerText(
              color: themeColor,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth, //260
          ),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(
              objectMgr.loginMgr.isDesktop ? 10 : 10.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 0,
                blurRadius: 16,
              ),
            ],
          ),
          child: overlayChild,
        ),
        layerLink,
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 301 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        followerWidgetOffset: const Offset(0, 20.5),
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
          Get.delete<MoreVertController>();
        },
      );
    }
  }

  closeMenu() {
    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;
    Get.delete<MoreVertController>();
  }

  showCallOptionPopup(BuildContext context, User? user) async {
    if (user == null) return;

    String userTitle =
        objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(user.uid));
    Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.uid);
    if (chat != null) {
      showCustomBottomAlertDialog(
        context,
        title: localized(callNow, params: [userTitle]),
        items: [
          CustomBottomAlertItem(
            text: localized(chatVoice),
            onClick: () => objectMgr.callMgr.startCall(chat, true),
          ),
          CustomBottomAlertItem(
            text: localized(chatVideo),
            onClick: () => objectMgr.callMgr.startCall(chat, false),
          ),
        ],
      );
    }
  }

  Future<void> showCallSingleOption(
    BuildContext context,
    Chat? chat,
    bool isVoiceCall,
  ) async {
    if (chat == null) return;

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(attachmentCallVoice),
          onClick: () async {
            objectMgr.callMgr.startCall(chat, true);
          },
        ),
        CustomBottomAlertItem(
          text: localized(attachmentCallVideo),
          onClick: () async {
            objectMgr.callMgr.startCall(chat, false);
          },
        ),
      ],
    );
  }
}

class FriendShipUtils {
  /// 获取好友请求页面的数据
  static Map<String, Map<User, MessageState>> getRequestUserPageData() {
    // 这里是将数据分成 待验证 和 已验证2部分
    Map<String, Map<User, MessageState>> result =
        <String, Map<User, MessageState>>{'verifying': {}, 'verified': {}};
    for (var user in objectMgr.userMgr.allUsers) {
      var userState = getMessageState(user.uid);
      if (userState == MessageState.recievedFriendRequest ||
          userState == MessageState.sentFriendRequest) {
        result['verifying']![user] = userState;
      }
      if (userState == MessageState.acceptedFriendRequestByHer ||
          userState == MessageState.acceptedFriendRequestByMe ||
          userState == MessageState.rejectedFriendRequestByHer ||
          userState == MessageState.rejectedFriendRequestByMe ||
          userState == MessageState.withdrewFriendRequestByMe) {
        result['verified']![user] = userState;
      }
    }
    return result;
  }

  /// 修改用户的状态
  static Future<User> changeUserMessageState(
    User user,
    MessageState state,
  ) async {
    // 这里主要处理删除的逻辑对状态改变的影响
    Map messageStateMap = getMessageStateMap(user.uid);
    if (messageStateMap.isNotEmpty) {
      MessageState localMessageState = messageStateMap['message_state'];
      int localRequestTime = messageStateMap['request_at'];
// 这个说是可以用来区分是不是同一条消息，之前我是用request_at
      // 处理某个请求在本地被用户删除后的状态改变逻辑
      if (localMessageState ==
          MessageState.deletedFriendRequestInTheRequestPage) {
        // 只要某个请求被删除了，就永远别想出来，除非你换设备，requestTime 可以判断是否是同一个请求
        if (localRequestTime != user.requestTime) {
          saveMessageState(user, state);
        }
      } else {
        // 如果这条本地没有标记为删除，那状态随便更改
        saveMessageState(user, state);
      }
    } else {
      // 本地都没有保存状态，那还不随便存
      saveMessageState(user, state);
    }

    // 只有下面2种状态需要保留历史record 收到请求 和 发出请求
    if (state == MessageState.recievedFriendRequest ||
        state == MessageState.sentFriendRequest) {
      var remarkHistory = getHistoryRemark(user.uid);
      var markInfo = {
        'request_at': '${user.requestTime}',
        'remark': user.remark,
      };
      if (state == MessageState.recievedFriendRequest) {
        remarkHistory['received'].add(markInfo);
      } else if (state == MessageState.sentFriendRequest) {
        remarkHistory['sent'].add(markInfo);
      }
      // 对received数组排序并去重
      remarkHistory['received'] = sortAndDeduplicate(remarkHistory['received']);
      // 对sent数组排序并去重
      remarkHistory['sent'] = sortAndDeduplicate(remarkHistory['sent']);
      saveHistoryRemark(user.uid, remarkHistory);
    }

    return user;
  }

  /// 对比服务器数据和本地数据，并将新的数据和本地状态变动过的数据返回
  static Future<List<User>> compareServiceJsonWithLocalJson(
    serviceUserInfo,
  ) async {
    List<User> serviceRequestList = [];
    List serviceHistoryMapList = [];
    if (serviceUserInfo is Map) {
      if ((serviceUserInfo['request_list'] is Map) &&
          (serviceUserInfo['request_list']['users'] is List) &&
          (serviceUserInfo['request_list']['users'].length > 0)) {
        serviceRequestList = List<User>.from(
          serviceUserInfo['request_list']['users'].map((e) => User.fromJson(e)),
        );
      }
      if ((serviceUserInfo['history_records'] is Map) &&
          (serviceUserInfo['history_records']['record'] is List) &&
          (serviceUserInfo['history_records']['record'].length > 0)) {
        serviceHistoryMapList = serviceUserInfo['history_records']['record'];
      }
    }

    for (var recordUser in serviceHistoryMapList) {
      User user = User.fromJson(recordUser);
      // serviceRequestList 里面是最新的请求状态，所以只修改不在这个列表中的用户状态
      if (serviceRequestList.every((element) => element.uid != user.uid)) {
        int status = recordUser['status'];
        if (status == 1) {
          // 我已接受
          changeUserMessageState(user, MessageState.acceptedFriendRequestByMe);
        } else if (status == 2) {
          // 对方接受
          changeUserMessageState(user, MessageState.acceptedFriendRequestByHer);
        } else if (status == -1) {
          // 我已拒绝
          changeUserMessageState(user, MessageState.rejectedFriendRequestByMe);
        } else if (status == -2) {
          // 对方拒绝
          changeUserMessageState(user, MessageState.rejectedFriendRequestByHer);
        } else if (status == -3) {
          // 我方撤销
          changeUserMessageState(user, MessageState.withdrewFriendRequestByMe);
        } else if (status == -4) {
          // 对方撤销
          changeUserMessageState(user, MessageState.withdrewFriendRequestByHer);
        }
      }
    }

    // 遍历服务器的所有用户信息，并对比本地的信息，进行数据更新
    for (var serviceUser in serviceRequestList) {
      // *** 表示服务器返回的数据，可以在本地找到
      // 只看收到的请求和发出的请求，并记录
      if (serviceUser.relationship == Relationship.sentRequest) {
        changeUserMessageState(serviceUser, MessageState.sentFriendRequest);
      } else if (serviceUser.relationship == Relationship.receivedRequest) {
        changeUserMessageState(serviceUser, MessageState.recievedFriendRequest);
      }
    }
    return serviceRequestList;
  }

  /// 对数据 按照request_at 进行排序 和 去重
  static List sortAndDeduplicate(List list) {
    // 根据request_at进行排序
    list.sort(
      (a, b) => int.parse(a['request_at'] ?? '0')
          .compareTo(int.parse(b['request_at'] ?? '0')),
    );

    // 去重
    List deduplicatedList = [];
    String? lastRequestAt;

    for (var item in list) {
      if (item['request_at'] != lastRequestAt) {
        deduplicatedList.add(item);
        lastRequestAt = item['request_at'];
      }
    }
    return deduplicatedList;
  }

  static saveHistoryRemark(int userId, Map historyRemark) {
    var uid = objectMgr.userMgr.mainUser.uid;
    if (uid > 0) {
      var historyRemarkString = json.encode(historyRemark);
      objectMgr.localStorageMgr
          .write<String>('${uid}_${userId}_remark', historyRemarkString);
    }
  }

  /// 返回的Map格式说明
  /// {
  ///       'received':[
  ///         {
  ///           'request_at': '${user.requestTime}', // 这里存的是字符串
  ///           'remark': user.remark // 这里存的是字符串
  ///         }
  ///       ],
  ///       'sent':[]
  ///     }
  static Map getHistoryRemark(int userId) {
    var uid = objectMgr.userMgr.mainUser.uid;
    Map defaultMap = {'received': [], 'sent': []};
    if (uid > 0) {
      var historyRemarkString =
          objectMgr.localStorageMgr.read<String>('${uid}_${userId}_remark') ??
              "";
      if (historyRemarkString.isEmpty) {
        return defaultMap;
      } else {
        var historyRemark = json.decode(historyRemarkString);
        return historyRemark;
      }
    } else {
      return defaultMap;
    }
  }

  /// 返回最近的一条记录，包括收到的 和 发出去的
  /// {
  ///  'received':'最近的一条收到的消息' // 是字符串
  ///   'sent':'最近的一条发出的消息' // 是字符串
  /// }
  static Map getLastestHistoryRemark(int userId) {
    Map historyRemarks = getHistoryRemark(userId);
    Map result = {'received': '', 'sent': ''};
    if (historyRemarks['received'] != null &&
        historyRemarks['received'] is List &&
        historyRemarks['received'].length > 0) {
      result['received'] = historyRemarks['received'].last['remark'];
    }
    if (historyRemarks['sent'] != null &&
        historyRemarks['sent'] is List &&
        historyRemarks['sent'].length > 0) {
      result['sent'] = historyRemarks['sent'].last['remark'];
    }
    return result;
  }

  /// 保存消息状态信息
  /// 这里保存了这条状态的 状态 和 该条状态消息的发起时间，用来判断是否是同一条消息
  /// {
  ///   'request_at':user.requestTime, // 保存的是 int
  ///   'message_state': getMessageStateIntValue(state) // 保存的是 int
  ///   'account_id':user.accountId, // 保存的是 string
  /// }
  static saveMessageState(User user, MessageState state) {
    var myUserId = objectMgr.userMgr.mainUser.uid;
    if (myUserId > 0) {
      Map jsonMap = {
        'request_at': user.requestTime,
        'message_state': state.value,
        'account_id': user.accountId,
      };
      String jsonString = json.encode(jsonMap);
      objectMgr.localStorageMgr
          .write<String>('${myUserId}_${user.uid}_message_state', jsonString);
    }
  }

  /// 获取消息状态

  static MessageState getMessageState(int userId) {
    Map messageStateMap = getMessageStateMap(userId);
    if (messageStateMap.isEmpty) {
      return MessageState.unKnown;
    } else {
      MessageState messageState = messageStateMap['message_state'];
      return messageState;
    }
  }

  /// 获取消息状态信息的Map 里面有时间戳和消息状态
  /// {
  ///   'request_at': user.requestTime, // 返回的是 int
  ///   'message_state':  MessageState // 返回的是 MessageState 的枚举
  ///   'account_id':accountId, // 是string
  /// }
  static Map getMessageStateMap(int userId) {
    var myUserId = objectMgr.userMgr.mainUser.uid;
    if (myUserId > 0) {
      String jsonString = objectMgr.localStorageMgr
              .read<String>('${myUserId}_${userId}_message_state') ??
          "";
      if (jsonString.isEmpty) {
        return {};
      } else {
        Map messageStateMap = json.decode(jsonString);
        int messageStateIntValue = messageStateMap['message_state'];
        String accountId = messageStateMap['account_id'] ?? "";
        MessageState state = MessageState.fromInt(messageStateIntValue);
        if (messageStateMap.isEmpty) {
          return {};
        } else {
          return {
            'request_at': messageStateMap['request_at'],
            'message_state': state,
            'account_id': accountId,
          };
        }
      }
    } else {
      return {};
    }
  }
}

/// 用户展示数据的模型类
class FriendShipItem {
  bool isUser;
  String title;
  User user;
  MessageState state;

  FriendShipItem({
    required this.user,
    required this.isUser,
    required this.title,
    required this.state,
  });
}

// 1.收到的好友请求
// 2.发出的好友请求
// 3.对方拒绝的好友请求
// 4.对方接受的好友请求
// 5.对方撤销的好友请求
// 6.我方拒绝的好友请求
// 7.我方接受的好友请求
// 8.我方撤销的好友请求
// 9.好友请求列表删除
// 10.解除好友关系 我方删除对方
// 11.解除好友关系 对方删除我
// ...是否拉黑的暂时不管，不影响列表数据展示
enum MessageState {
  unKnown(value: 0), //0.未知状态
  recievedFriendRequest(value: 1), //1.收到的好友请求
  sentFriendRequest(value: 2), // 2.发出的好友请求
  rejectedFriendRequestByHer(value: 3), // 3.对方拒绝的好友请求
  acceptedFriendRequestByHer(value: 4), // 4.对方接受的好友请求
  withdrewFriendRequestByHer(value: 5), // 5.对方撤销的好友请求
  rejectedFriendRequestByMe(value: 6), // 6.我方拒绝的好友请求
  acceptedFriendRequestByMe(value: 7), // 7.我方接受的好友请求
  withdrewFriendRequestByMe(value: 8), // 8.我方撤销的好友请求
  deletedFriendRequestInTheRequestPage(value: 9); // 9.好友请求列表删除

  final int value;

  const MessageState({required this.value});

  // 添加一个静态方法用于从整数值生成 MessageState
  static MessageState fromInt(int value) {
    return MessageState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageState.unKnown,
    );
  }
}
