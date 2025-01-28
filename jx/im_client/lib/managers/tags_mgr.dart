import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_tags.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/object/edit_friend.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tags/api/tags_api.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:uuid/uuid.dart';

/// 標籤使用方式：
/// allTags: 所有標籤，包含uuid, tagName, updated_at..etc.
/// allTagByGroup: 標籤分組，key為標籤，value為List<User>被標籤的好友.
/// 若只是要選取並顯示標籤不需要顯示多少人，可直接使用allTags，若需要顯示標籤內多少好友，
/// 請配合allTagByGroup使用。
class TagsMgr extends BaseMgr implements TemplateMgrInterface {
  static const String TAGS_CREATE = 'TAGS_CREATE';
  static const String TAGS_UPDATE = 'TAGS_UPDATE';
  static const String TAGS_DELETE = 'TAGS_DELETE';

  static const String TAGS_NOTIFY_UPDATE = 'TAGS_NOTIFY_UPDATE';

  static const int TAG_TYPE_MOMENT = 0;
  static const int TAG_TYPE_COLLECTION = 1;

  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;

  ///所有標籤
  List<Tags> allTags = [];

  ///Tags分組
  Map<int, List> allTagByGroup = {};

  @override
  Future<void> initialize() async {
    if (!_sharedDB.hasListener("$blockOptReplace:${DBTags.tableName}")) {
      _sharedDB.on("$blockOptReplace:${DBTags.tableName}", _onTagsUpdate);
    }

    if (!_sharedDB.hasListener("$blockOptUpdate:${DBTags.tableName}")) {
      _sharedDB.on("$blockOptUpdate:${DBTags.tableName}", _onTagsUpdate);
    }

    if (!_sharedDB.hasListener("$blockOptDelete:${DBTags.tableName}")) {
      _sharedDB.on("$blockOptDelete:${DBTags.tableName}", _onTagsUpdate);
    }

    if (!objectMgr.socketMgr.hasListener(SocketMgr.updateTagsBlock)) {
      objectMgr.socketMgr.on(SocketMgr.updateTagsBlock, _onTagsNotifyUpdate);
    }

    await syncTags();
  }

  void _onTagsNotifyUpdate(_, __, Object? data) async {
    await syncTags();
  }

  ///Follow server status.
  Future<bool> syncTags({List<Tags>? serverTags}) async {
    bool isSyncSuccess = true;

    if (serverTags == null) {
      try {
        serverTags ??= await retrieveFriendTags();
      } catch (e) {
        serverTags = null;
      }
    }

    var tempTags = await _localDB.loadAllTags();

    /// 不同裝置同步，一啟動根據ServerTags改動localTags資料庫：
    /// 1. 刪除localTags不存在於serverTags的資料
    /// 2. 新增serverTags不存在於localTags的資料
    if (serverTags != null && serverTags.isNotEmpty) {
      List<Tags> allTag = tempTags.map((e) => Tags.fromJson(e)).toList();
      List<Tags> onServer = List.from(serverTags); // should add
      if (allTag.isNotEmpty) {
        List<Tags> onLocal = List.from(allTag); // should delete

        // Remove tags from onLocal that are present in serverTags
        onLocal.retainWhere((localTag) =>
            !serverTags!.any((serverTag) => serverTag.uid == localTag.uid));

        // Remove tags from onServer that are present in allTags
        onServer.retainWhere((serverTag) => !allTag.any((localTag) =>
            localTag.uid == serverTag.uid &&
            localTag.tagName == serverTag.tagName));

        // Delete local tags that are not in serverTags
        if (onLocal.isNotEmpty) {
          for (var tag in onLocal) {
            //delete local only
            await deleteTags(tag.uid);
          }
        }

        // Add server tags that are not in allTags
        if (onServer.isNotEmpty) {
          //add to local only
          List<Map<String, dynamic>> tags =
              onServer.map((tag) => tag.toJson()).toList();
          await _localDB.addTags(tags);
        }
      } else {
        // Add server tags that are not in allTags
        if (onServer.isNotEmpty) {
          //add to local only
          List<Map<String, dynamic>> tags =
              onServer.map((tag) => tag.toJson()).toList();
          await _localDB.addTags(tags);
        }
      }
    } else {
      if (serverTags != null && tempTags.isNotEmpty) {
        List<Tags> allTag = tempTags.map((e) => Tags.fromJson(e)).toList();
        for (var tag in allTag) {
          //delete local only
          await deleteTags(tag.uid);
        }
      }
    }

    var alTag = await _localDB.loadAllTags();
    allTags = alTag.map((e) => Tags.fromJson(e)).toList();

    int lastUpdateTime = objectMgr.localStorageMgr
            .read(LocalStorageMgr.CONTACT_LAST_UPDATE_TIME) ??
        0;

    List<User> users = [];
    try {
      final res =
          await getUserList(start: lastUpdateTime, ignore_blacklist_check: 1);
      users = res.map((item) => User.fromJson(item)).toList();

      ///這邊要同步user的值
      await objectMgr.userMgr.onUserChanged(users);
    } catch (e) {
      pdebug(e);
    }

    await getAllTagByGroup();
    event(
      this,
      TAGS_NOTIFY_UPDATE,
      data: [],
    );
    return isSyncSuccess;
  }

  ///Tags對應的好友，如果標籤uid找不到對應的key，代表此標籤沒有好友
  Future<Map<int, List<User>>> loadAllTagsBindingFriend() async {
    Map<int, List<User>> bindingFriend = {};
    for (int i = 0; i < allTags.length; i++) {
      List<User> temp =
          await _localDB.loadFriendsBindingTag(tagUid: allTags[i].uid);
      if (temp.isNotEmpty) {
        bindingFriend[allTags[i].uid] = temp;
      }
    }
    return bindingFriend;
  }

  Future<List<User>> loadFriendsBindingTagById(int tagUid) async {
    return await _localDB.loadFriendsBindingTag(tagUid: tagUid);
  }

  @override
  Future<void> registerOnce() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;
    registerModel();
  }

  /// 注册模版
  @override
  Future<void> registerModel() async {
    _sharedDB.registerModel(
      DBTags.tableName,
      JsonObjectPool<Tags>(Tags.creator),
    );
  }

  @override
  Future<void> cleanup() async {
    allTags.clear();
    _sharedDB.off("$blockOptReplace:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.off("$blockOptUpdate:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.off("$blockOptDelete:${DBTags.tableName}", _onTagsUpdate);

    objectMgr.socketMgr.off(SocketMgr.updateTagsBlock, _onTagsNotifyUpdate);
    clear();
  }

  void _onTagsUpdate(Object sender, Object type, Object? data) {
    if (type == "$blockOptReplace:${DBTags.tableName}") {
      if (data is Tags) {
        event(this, TAGS_CREATE, data: data);
      }
    } else if (type == "$blockOptUpdate:${DBTags.tableName}") {
      //The shareDB is not going to send modify event.
    } else if (type == "$blockOptDelete:${DBTags.tableName}") {
      //data = tag.uid.
      if (data is int) {
        event(this, TAGS_DELETE, data: data);
      }
    }
  }

  /// Create tags; you can't update the tags to a server in this function.
  /// There are some situations that need to update the tags only locally.
  Future<bool> addTags(Tags tags) async {
    if (allTags.any((element) => element.tagName == tags.tagName)) {
      return false;
    }

    allTags.add(tags);

    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBTags.tableName,
        [tags.toJson()],
      ),
      save: true,
      notify: false,
    );

    event(this, TAGS_CREATE, data: tags);
    return true;
  }

  //更新Tags
  Future<void> updateTags(Tags tags) async {
    if (allTags.isNotEmpty) {
      allTags.firstWhere((element) => element.uid == tags.uid).copyFrom(tags);
    }

    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptUpdate,
        DBTags.tableName,
        tags.toJson(),
      ),
      save: true,
      notify: false,
    );

    event(this, TAGS_UPDATE, data: tags);
  }

  //刪除Tags的方法
  Future<void> deleteTags(int uid) async {
    allTags.removeWhere((element) => element.uid == uid);
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptDelete,
        DBTags.tableName,
        uid,
      ),
      save: true,
      notify: false,
    );
    event(this, TAGS_DELETE, data: uid);
  }

  Future<List<TagResult>?> addTagsToServer(Tags tag) async {
    try {
      Map<String, dynamic>? result = await createFriendTags([tag]);
      if (result == null) return null;

      List<TagResult> tagResults = (result["tags"] as List<dynamic>)
          .map((e) => TagResult(
                isSuccess: true,
                id: e['id'],
                user_id: e['user_id'],
                tagName: e['tag'],
                updated_at: e['created_at'],
              ))
          .toList();

      return tagResults;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deletedTagsToServer(List<Tags> tag) async {
    bool isSuccess = false;
    try {
      return await deleteFriendTags(tag);
    } catch (e) {
      return isSuccess;
    }
  }

  Future<bool> editTagsToServer(List<Tags> tag) async {
    bool isSuccess = false;
    try {
      return await editFriendTags(tag);
    } catch (e) {
      return isSuccess;
    }
  }

  Future<void> deleteAllTags({int type = -1}) async {
    await _localDB.deleteAllTags(type: type);
  }

  ///@param type -1:全部(預設) 1:朋友圈 2:收藏
  ///取得所有Tags的方法
  Future<List<Tags>> getAllTags({int type = -1}) async {
    List<Map<String, dynamic>> tagsList =
        await _localDB.loadAllTags(type: type);

    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBTags.tableName,
        tagsList,
      ),
      save: false,
      notify: false,
    );

    allTags = tagsList.map((e) => Tags.fromJson(e)).toList();
    return allTags;
  }

  Future<Map<int, List<User>>> getAllTagByGroup() async {
    Map<int, List<dynamic>> tagsByGroupList =
        await _localDB.loadAllTagsByGroup();
    allTagByGroup.assignAll(tagsByGroupList);
    return tagsByGroupList
        .map((key, value) => MapEntry(key, value.cast<User>()));
  }

  //取得特定的Tag
  Future<Map<String, dynamic>?> getTagsById(int uid) async {
    return await _localDB.loadTags(uid);
  }

  Future<bool> updateContacts(List<User> users) async {
    final List<EditFriend> editFriendList = users
        .map((user) => EditFriend(
              target_uuid: user.accountId,
              friend_tags: user.friendTags ?? <int>[],
            ))
        .toList();

    for (var editFriend in editFriendList) {
      editFriend.friend_tags =
          LinkedHashSet<int>.from(editFriend.friend_tags!).toList();
    }

    bool isSuccess = false;
    try {
      //update server
      isSuccess = await massEditFriendNickname(editFriend: editFriendList);
      await objectMgr.userMgr.onUserChanged(users, notify: true);
    } catch (e) {
      pdebug("updateContacts failed e:$e");
    }

    return isSuccess;
  }

  int generateNumericUUID() {
    String uuid = const Uuid().v4();
    String numericUUID = uuid.replaceAll(RegExp(r'[^0-9]'), '');
    // Pad with leading zeros if the numeric UUID is less than 16 digits
    numericUUID = numericUUID.padLeft(16, '0');
    // 32位數改取16位數避免後端陣列溢位
    return int.parse(numericUUID.substring(0, 16));
  }

  @override
  Future<void> recover() {
    throw UnimplementedError();
  }
}

class NotifyTask {
  Completer<bool> completer;
  dynamic data;
  NotifyTask(this.completer, this.data);
}

class TagResult {
  bool isSuccess;
  int id;
  int user_id;
  String tagName;
  int updated_at;

  TagResult({
    required this.isSuccess,
    required this.id,
    required this.user_id,
    required this.tagName,
    required this.updated_at,
  });
}
