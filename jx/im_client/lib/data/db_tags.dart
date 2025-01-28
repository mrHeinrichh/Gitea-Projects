import 'dart:convert';

import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/utility.dart';

mixin class DBTags implements TagsInterface {
  static const String tableName = 'tags';

  @override
  void initTagsDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS  tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER, 
        name TEXT DEFAULT "",
        type INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        __add_index INTEGER
        );
        ''');
  }

  @override
  Future<Map<String, dynamic>?> loadTags(int id) async {
    List<Map<String, dynamic>> groupTagsMapList =
        await DatabaseHelper.query(tableName, where: "id = ?", whereArgs: [id]);
    return groupTagsMapList.isNotEmpty ? groupTagsMapList.first : null;
  }

  ///@param type -1:全部(預設) 1:朋友圈 2:收藏
  @override
  Future<List<Map<String, dynamic>>> loadAllTags({int type = -1}) async {
    ///取得全部Tags
    if (type == -1) {
      return await DatabaseHelper.query(
        tableName,
        where: 'type IN (?, ?)',
        whereArgs: [TagsMgr.TAG_TYPE_MOMENT, TagsMgr.TAG_TYPE_COLLECTION],
        orderBy: 'updated_at DESC',
      );
    } else {
      return await DatabaseHelper.query(tableName,
          where: "type = ?", whereArgs: [type], orderBy: 'updated_at DESC');
    }
  }

  /// 方法使用情境:
  /// 有兩個Tags uuid，分別是111跟222，而有兩個User，是Ken, Josh，而Ken的Tag欄位是111, Josh是111,222.
  /// 返回的結果已經是分類好的結構：
  /// Map<int,List<User>> result = {111:[Ken,Josh],222:[Josh]}
  @override
  Future<Map<int, List>> loadAllTagsByGroup({int type = -1}) async {
    var result = <int, List<User>>{};

    ///Result: [{uid: 123, users: 2317,2625}, {uid: 345, users: 2317,2137703}]
    List<Map<String, dynamic>> friends = await DatabaseHelper.rawQuery('''
        SELECT t.uid, GROUP_CONCAT(u.uid) as users
        FROM tags t
        JOIN user u ON u.friend_tags LIKE '%' || t.uid || '%'
        GROUP BY t.uid
        ORDER BY u.nickname DESC;
        ''');

    for (Map<String, dynamic> perFriend in friends) {
      var tagUid = perFriend['uid'];
      //perFriend['users']內容為：2317,2625,
      String users = perFriend['users'];
      List<String> usersList = users.split(',');
      List<User> temp = [];
      for (var userUid in usersList) {
        final userData = await objectMgr.localDB.loadUser(int.parse(userUid));
        if (userData == null) {
          continue;
        }
        final editableUser = deepCopy(userData);
        editableUser["friend_tags"] = editableUser["friend_tags"] != null
            ? (editableUser["friend_tags"] is String
                ? List<int>.from(jsonDecode(editableUser["friend_tags"]))
                : List<int>.from(editableUser["friend_tags"]))
            : <int>[];
        User user = User.fromJson(editableUser);
        if (user != null &&
            (user.relationship == Relationship.friend ||
                user.relationship == Relationship.blocked)) {
          temp.add(user);
        }
      }
      result[tagUid] = List.from(temp)
        ..sort((a, b) => a.nickname.compareTo(b.nickname));
    }

    return Future.value(result);
  }

  @override
  Future<int?> addTags(List<Map<String, dynamic>> tags) async {
    for (var tag in tags) {
      await DatabaseHelper.replace(tableName, tag);
    }
    return 0;
  }

  ///@param type -1:全部(預設) 1:朋友圈 2:收藏
  @override
  Future<int?> deleteAllTags({int type = -1}) async {
   
    ///刪除全部Tags
    if (type == -1) {
      return await DatabaseHelper.delete(tableName,
          where: 'type IN (?, ?)',
          whereArgs: [TagsMgr.TAG_TYPE_MOMENT, TagsMgr.TAG_TYPE_COLLECTION]);
    } else {
      return await DatabaseHelper
          .delete(tableName, where: "type = ?", whereArgs: [type]);
    }
  }

  @override
  Future<int?> clearTags() async {
    return await DatabaseHelper.delete(tableName);
  }

  ///@param tags 要新增的Tags
  @override
  Future<List<User>> loadFriendsBindingTag({required int tagUid}) async {
    List<Map<String, dynamic>> friends = await DatabaseHelper.rawQuery(
      '''
        SELECT user.*
        FROM user
        INNER JOIN tags ON user.friend_tags LIKE '%' || tags.uid || '%'
        WHERE tags.uid = ?
        ''',
      [tagUid],
    );

    List<User> users = [];
    for (Map<String, dynamic> perFriend in friends) {
      users.add(User.fromJson(perFriend));
    }

    return users;
  }
}
