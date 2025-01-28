import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart' as account_api;
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/register/components/themedAlertDialog.dart';
import 'package:jxim_client/managers/interface.dart';

/// 主玩家的一些方法实现
///
/// USERMANGER
class UserMgr extends EventDispatcher
    implements MgrInterface, TemplateMgrInterface, SqfliteMgrInterface {
  static const String eventFriendSecret = 'eventFriendSecret';
  static const String eventMessageSound = 'eventMessageSound';

  final String socketContentFriend = 'friend';
  final String socketContentRequest = 'friend_request';
  final String socketContentAuth = 'auth';
  final String socketLogout = "kick";
  final String socketFriendOnline = "user_last_online";
  final String socketFriendSecret = "friend_secret";

  //辨认弹窗是否已存在
  bool hasPopDialog = false;

  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;
  SharedTable? _userTable;

  User get mainUser => objectMgr.loginMgr.account?.user ?? User();

  List<User> allUsers = [];

  List<User> get friends {
    List<User>? userList = allUsers
        .where((user) => user.relationship == Relationship.friend || user.relationship == Relationship.blocked)
        .toList();
    //如果没有备注名就用用户名来对比
    userList.sort(
          (a, b) => multiLanguageSort(
        getUserTitle(a).toLowerCase(),
        getUserTitle(b).toLowerCase(),
      ),
    );
    return userList;
  }

  List<User> get friendWithoutBlacklist {
    List<User>? userList = allUsers
        .where((user) => user.relationship == Relationship.friend)
        .toList();
    //如果没有备注名就用用户名来对比
    userList.sort(
      (a, b) => multiLanguageSort(
        getUserTitle(a).toLowerCase(),
        getUserTitle(b).toLowerCase(),
      ),
    );
    return userList;
  }

  /// 移除delete account
  List<User> get filterFriends {
    List<User>? userList = allUsers
        .where((user) => user.relationship == Relationship.friend)
        .where((user) => user.deletedAt == 0)
        .toList();
    //如果没有备注名就用用户名来对比
    userList.sort(
      (a, b) => multiLanguageSort(
        getUserTitle(a).toLowerCase(),
        getUserTitle(b).toLowerCase(),
      ),
    );
    return userList;
  }

  List<User> get requestFriends {
    List<User>? userList = allUsers
        .where((user) => user.relationship == Relationship.receivedRequest)
        .toList();
    userList.sort(
      (a, b) {
        if (a.requestTime != null && b.requestTime != null) {
          ///使用好友请求的时间
          return b.requestTime- a.requestTime;
        } else {
          ///使用名字
          return multiLanguageSort(getUserTitle(a), getUserTitle(b));
        }
      },
    );
    return userList;
  }

  /// 根據用戶名取得用戶資訊
  User? getUserByUserName (String userName) {
    List<User>? userList = allUsers
        .where((user) => user.username == userName)
        .toList();
    return userList.length > 0 ? userList[0] : null;
  }

  List<User> get appliedFriends {
    List<User>? userList = allUsers
        .where((user) => user.relationship == Relationship.sentRequest)
        .toList();
    userList.sort(
      (a, b) {
        if (a.requestTime != null && b.requestTime != null) {
          ///使用好友请求的时间
          return b.requestTime- a.requestTime;
        } else {
          ///使用名字
          return multiLanguageSort(getUserTitle(a), getUserTitle(b));
        }
      },
    );
    return userList;
  }

  final friendOnline = RxMap<int, bool>();
  final friendOnlineTime = Map<int, int>();

  @override
  Future<void> register() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;
    registerModel();
    registerSqflite();
  }

  /// 注册模版
  @override
  Future<void> registerModel() async {
    _sharedDB.registerModel(
        DBUser.tableName, JsonObjectPool<User>(User.creator));
  }

  @override
  Future<void> init() async {
    _userTable = _sharedDB.getTable(DBUser.tableName);
    _sharedDB.on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    _sharedDB.on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);

    final tempUsers = await _localDB.loadAllUsers();
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBUser.tableName,
        tempUsers,
      ),
      save: false,
      notify: false,
    );
    allUsers = tempUsers.map((e) => User.fromJson(e)).toList();
  }

  Future<User> loadUser() async {
    try {
      final User user = await account_api.getUser();
      _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
              blockOptReplace, DBUser.tableName, [user.toJson()]),
          save: true,
          notify: true);

      return user;
    } catch (e) {
      throw e;
    }
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      final user = data;
      if (isMe(user.uid)) {
        updateMainUser(user);
      }
    }
  }

  updateMainUser(User user) async {
    await objectMgr.loginMgr.setUserOfAccount(user);
  }

  @override
  Future<void> logout() async {
    allUsers.clear();
    requestFriends.clear();
    filterFriends.clear();
    friendWithoutBlacklist.clear();
    _sharedDB.off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    _sharedDB.off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
  }

  @override
  Future<void> registerSqflite() async {
    _localDB.registerTable('''
        CREATE TABLE IF NOT EXISTS  user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER,
        uuid TEXT,
        last_online INTEGER,
        profile_pic TEXT,
        nickname TEXT,
        contact TEXT,
        country_code TEXT,
        username TEXT,
        relationship INTEGER,
        bio TEXT,
        user_alias TEXT,
        request_at INTEGER,
        deleted_at INTEGER,
        email TEXT,
        __add_index INTEGER
        );
        ''');
  }

  /// Add/Replace user to local
  onUserChanged(List<User> users, {bool notify = false}) {
    updateAllUsersList(users);
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptReplace, DBUser.tableName,
          users.map((e) => e.toJson()).toList()),
      save: true,
      notify: notify,
    );

    if (users.isNotEmpty) updateSingleChat(users);
  }

  /// Add/Replace user to local
  onUserUpdate(List<Map<String, dynamic>> users, {bool notify = false}) {
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBUser.tableName,
        users.map((e) => User.fromGroupMember(e).groupMemberToJson()).toList(),
      ),
      save: true,
      notify: notify,
    );
  }

  /// Get user from local/remote
  Future<User?> loadUserById(int uid,
      {bool remote = false, bool notify = true}) async {
    if (!remote) {
      User? user = getUserById(uid);
      if (user != null) {
        return user;
      }
      final userData = await _localDB.loadUser(uid);
      if (userData != null) {
        /// 装载到_userTable里面
        await _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(
                blockOptReplace, DBUser.tableName, [userData]),
            save: false,
            notify: false);

        user = getUserById(uid);
        return user;
      }
    }

    User? user = await getRemoteUser(uid, notify: notify);
    return user;
  }

  Future<User?> loadUserById2(int userId, {bool notify = false}) async {
    final userData = await _localDB.loadUser(userId);
    if (userData != null) {
      _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(blockOptReplace, DBUser.tableName, [userData]),
        save: false,
        notify: notify,
      );
    } else {
      await getRemoteUser(userId, notify: true);
    }

    return getUserById(userId);
  }

  User? getUserById(int uid) {
    if(uid == 0){
      User user = new User();
      user.uid = 0;
      user.nickname = localized(homeSystemMessage);
      return user;
    }
    RowObject? obj = _userTable?.getRow(uid);
    if (obj is User) {
      return obj;
    } else {
      if (obj != null) {
        try {
          User user = User()..init(obj.toJson());
          return user;
        } catch (e) {
          pdebug(
              'getUserById error fail to create User = $e , obj = ${obj.toJson()}');
          return null;
        }
      }
    }
    return null;
  }

  /// Get user remotely and update
  Future<User?> getRemoteUser(int uid, {bool notify = true}) async {
    if (uid == null || uid == 0) return null;
    final List<User> users = await getUsersByUID(uidList: [uid]);
    if (users.length > 0) {
      User user = users.first;
      onUserChanged(users, notify: notify);
      return user;
    }
    return null;
  }

  ///获取手机联系人列表
  Future<List<Contact>> getLocalContacts() async {
    bool isGranted = await Permission.contacts.status.isGranted;
    if (!isGranted) {
      isGranted = await Permission.contacts.request().isGranted;
    }
    if (isGranted) {
      return await FastContacts.getAllContacts();
    }
    return [];
  }

  ///获取手机联系人列表
  Future<List<Map<String, Object>>?> getContactsList() async {
    try {
      List<Contact> contacts = await getLocalContacts();
      return contacts.map((contact) {
        return {
          'name': contact.displayName,
          'phone_number': contact.phones.map((phone) {
            return {'number': phone.number.replaceAll(' ', '')};
          }).toList()
        };
      }).toList();
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
    }
    return null;
  }

  bool isMe(int uid) {
    return objectMgr.loginMgr.account?.user?.uid == uid;
  }



  ///Object Manager 长链接更新 -> 更新数据库
  Future<void> doUserChange(UpdateBlockBean block) async {
    User? user;
    if (block.ctl == socketContentFriend) {
      user = await getUser(block);
      if (user == null) return;

      ///好友更新
      if (block.opt == blockOptReplace) {
        ///对方接受好友申请
        user.relationship = Relationship.friend;
        Chat? _chat = objectMgr.chatMgr.getChatById(block.data[0]['chat_id']);
        final payload = {
          'chat': _chat,
          'typ': 1,
          'notification_type': 1,
        };
        if (!block.data[0]['is_acceptor']) {
          if (Get.currentRoute != RouteName.friendRequestView ||
              Get.currentRoute != RouteName.chatInfo) {
            objectMgr.pushMgr.showNotification(
              1,
              body:
                  '${user.nickname} ${localized(contactAcceptFriendNotification)}',
              payLoad: jsonEncode(payload),
            );
          }
        }
        user.username = block.data.first["username"];
        user.profilePicture = block.data.first["profile_pic"];
        user.contact = block.data.first["contact"];
        user.countryCode = block.data.first["country_code"];
        user.lastOnline = block.data.first["last_seen"];
      } else if (block.opt == blockOptDelete) {
        ///删除好友
        user.relationship = Relationship.stranger;
        user.username = block.data["username"];
        user.profilePicture = block.data["profile_pic"];
        user.contact = block.data["contact"];
        user.countryCode = block.data["country_code"];
        user.lastOnline = block.data["last_seen"];
      }
    } else if (block.ctl == socketContentRequest) {
      user = await getUser(block);
      if (user == null) return;

      ///好友申请更新
      if (block.opt == blockOptReplace) {
        ///接收到好友申请
        user.relationship = Relationship.receivedRequest;
        user.requestTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final payload = {
          'typ': 2,
          'notification_type': 2,
        };
        if (Get.currentRoute != RouteName.friendRequestView) {
          objectMgr.pushMgr.showNotification(
            3,
            title: localized(contactFriendRequest),
            body:
                '${user.nickname} ${localized(contactFriendRequestsNotification)}',
            payLoad: jsonEncode(payload),
          );
        }
      } else if (block.opt == blockOptDelete) {
        ///对方拒绝好友申请
        user.relationship = Relationship.stranger;
      }
    }

    if (user != null) {
      ///删除好友或被删除时，匿名就会被删掉了
      if (user.relationship == Relationship.stranger) user.alias = '';
      onUserChanged([user], notify: true);
    }
  }

  ///长链接更新使用的获取用户信息
  Future<User?> getUser(UpdateBlockBean block) async {
    User? user;
    int uid =
        (block.data is List ? block.data.first["uid"] : block.data["uid"]) ??
            -1;
    if (uid != -1) {
      user = await loadUserById(uid);
    } else {
      pdebug("Retrieve user error");
    }
    return user;
  }

  /// 好友管理使用的方法（因为很多页面使用，所以搬迁到这里）
  ///添加好友
  void addFriend(User user) async {
    try {
      final res = await sendFriendRequest(uuid: user.accountId);
      if (res) {
        user.relationship = Relationship.sentRequest;
        user.requestTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        objectMgr.userMgr.onUserChanged([user], notify: true);
        ImBottomToast(Routes.navigatorKey.currentContext!,
            title: localized(friendRequestSent),
            icon: ImBottomNotifType.add_friend);
      }
    } on CodeException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_FRIEND_QUOTA_EXCEED) {
        ImBottomToast(Routes.navigatorKey.currentContext!,
            title: localized(
                yourFriendLimitHAsReachedPleaseUnfriendOthersToAddThisUser),
            icon: ImBottomNotifType.warning);
      } else {
        pdebug('${e.getPrefix()}: ${e.getMessage()}');
      }
    }
  }

  ///接受好友请求
  Future<void> acceptFriend(User user, {String? secretUrl}) async {
    try {
      final res =
          await acceptFriendRequest(uuid: user.accountId, secretUrl: secretUrl);
      if (res) {
        user.relationship = Relationship.friend;
        Get.find<ContactController>().updateFriendRequest(user, 1);
      } else {
        pdebug(
            "*Error* acceptFriend(search_contact_controller) - API return false");
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_FRIEND_QUOTA_EXCEED) {
        Toast.showToast(
          localized(yourFriendLimitHAsReachedPleaseUnfriendOthersToAddThisUser),
          duration: const Duration(seconds: 2),
        );
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_TARGET_USER_FRIEND_QUOTA_EXCEED) {
        user.relationship = Relationship.stranger;
        Toast.showToast(
          "${user.nickname}${localized(sFriendLimitHasReachedFailedToAccept)} ${user.nickname}${localized(sFriendRequest)}",
          duration: const Duration(seconds: 2),
        );
      } else {
        Toast.showToast(e.getMessage());
      }
    }
    objectMgr.userMgr.onUserChanged([user], notify: true);
  }

  ///拒绝好友请求
  Future<void> rejectFriend(User user) async {
    try {
      final res = await rejectFriendRequest(uuid: user.accountId);
      if (res) {
        user.relationship = Relationship.stranger;
        Get.find<ContactController>().updateFriendRequest(user, 2);
        objectMgr.userMgr.onUserChanged([user], notify: true);
      } else {
        pdebug(
            "*Error* rejectFriend(search_contact_controller) - API return false");
      }
    } on CodeException catch (e) {
      pdebug('${e.getPrefix()}: ${e.getMessage()}');
    }
  }

  ///获取显示的好友名称
  String getUserTitle(User? user, {bool allowEmptyString = true}) {
    if (user == null) return '';
    if (user.alias.trim() != '') {
      return user.alias;
    } else {
      if (user.nickname.trim() != '') {
        return user.nickname;
      } else {
        return allowEmptyString ? '' : 'this user';
      }
    }
  }

  ///长链接更新，判断是否推出登入
  void doUserLogout(UpdateBlockBean block) {
    if (block.opt == blockOptReplace) {
      final String action = block.data.first["action"];
      final String code = block.data.first["code"];
      if (action == socketLogout) {
        String message = localized(otherReasonLogout);

        if (code == "DUPLICATE_LOGIN") {
          message = localized(anotherDeviceDetectedProceedToLogin);
        } else if (code == "APP_LOGOUT") {
          message = localized(accountLoggedOutFromAllDevice);
        } else if (code == "DEVICE_LOGOUT") {
          message = localized(accountLoggedOutFromThisDevice);
        } else if (code == "ACCOUNT_DELETED") {
          message = localized(accountHasBeenDeleted);
        } else if (code == "ACCOUNT_BLOCKED") {
          message = localized(accountHasBeenBlocked);
        } else if (code == "OTHER_REASON") {
          message = localized(otherReasonLogout);
        }
        popLogoutDialog(
          displayMessage: message,
        );
      }
    }
  }

  //把用户踢出登入的弹窗
  void popLogoutDialog({String displayMessage = ''}) {
    if (!hasPopDialog) {
      hasPopDialog = true;
      objectMgr.logout(tologin: false).then(
            (value) => Get.dialog(
              WillPopScope(
                onWillPop: () async => false,
                child: ThemedAlertDialog(
                  title: displayMessage.isEmpty
                      ? localized(otherReasonLogout)
                      : displayMessage,
                  overallButtonText: localized(mySettingLogout),
                  overallButtonCallback: () {
                    hasPopDialog = false;
                    Get.offNamedUntil(
                        objectMgr.loginMgr.isDesktop
                            ? RouteName.desktopBoarding
                            : RouteName.boarding,
                        (route) => false);
                  },
                ),
              ),
              barrierDismissible: false,
            ),
          );
    }
  }

  //当网络恢复/app重新激活时，获取所有好友以及好友列表信息
  @override
  Future<void> reloadData() async {
    loadUser();
    if (Get.isRegistered<ContactController>()) {
      final ContactController controller = Get.find<ContactController>();
      controller.getFriendList();
      controller.getFriendRequestList();
      controller.getFriendSentList();
    }
  }

  //更新allUser列表里对象
  void updateAllUsersList(List<User> users) {
    for (User user in users) {
      final int existingIndex =
          allUsers.indexWhere((item) => item.uid == user.uid);
      if (existingIndex == -1)
        allUsers.add(user);
      else
        allUsers[existingIndex] = user;
    }
  }

  Future<void> updateSingleChat(List<User> users) async {
    ///更新Chat里的头像以及名字
    for (User user in users) {
      /// 更新所有关于此user id的chat资料
      final List<Chat> chats = objectMgr.chatMgr.getChatListByUserId(user.uid);
      if (chats.isNotEmpty) {
        for (Chat chat in chats) {
          if (chat.icon == user.profilePicture &&
              chat.name == getUserTitle(user)) continue;

          chat.icon = user.profilePicture;
          chat.name = getUserTitle(user);
          _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptUpdate,
              DBChat.tableName,
              chat.toJson(),
            ),
            save: true,
            notify: true,
          );
        }
      }
    }
  }

  Future<void> blockUser(User user) async {
    try {
      if (user.relationship == Relationship.sentRequest) {
        await withdrawFriendRequest(user: user);
      } else if (user.relationship == Relationship.receivedRequest) {
        await rejectFriendRequest(uuid: user.accountId);
      }
      final res = await doBlockUser(user.accountId);
      if (res) {
        user.relationship = Relationship.blocked;
        objectMgr.userMgr.onUserChanged([user], notify: true);
      } else {
        pdebug("*Error* blockUser - API return false");
      }
    } on CodeException catch (e) {
      pdebug('${e.getPrefix()}: ${e.getMessage()}');
    }
  }

  Future<bool> unblockUser(User user) async {
    try {
      final res = await doUnblockUser(user.accountId);
      if (res) {
        getRemoteUser(user.uid);
      } else {
        pdebug("*Error* unblockUser - API return false");
      }
      return res;
    } on CodeException catch (e) {
      pdebug('${e.getPrefix()}: ${e.getMessage()}');
      return false;
    }
  }
}
