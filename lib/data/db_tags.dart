import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';
import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/object/user.dart';

mixin class DBTags implements TagsInterface {
  static const String tableName = 'tags';

  MDataBase? _dbGroupTags;

  @override
  void initTagsDB(MDataBase? db) {
    _dbGroupTags = db;
  }

  @override
  Future<Map<String, dynamic>?> loadTags(int id) async {
    List<Map<String, dynamic>> groupTagsMapList =
        await _dbGroupTags!.query(tableName, where: "id = ?", whereArgs: [id]);
    return groupTagsMapList.isNotEmpty ? groupTagsMapList.first : null;
  }

  ///@param type -1:全部(預設) 1:朋友圈 2:收藏
  @override
  Future<List<Map<String, dynamic>>> loadAllTags({int type = -1}) async {
    if (_dbGroupTags == null) return [];

    ///取得全部Tags
    if (type == -1) {
      return await _dbGroupTags!.query(
        tableName,
        where: 'type IN (?, ?)',
        whereArgs: [TagsMgr.TAG_TYPE_MOMENT, TagsMgr.TAG_TYPE_COLLECTION],
      );
    } else {
      return await _dbGroupTags!
          .query(tableName, where: "type = ?", whereArgs: [type]);
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
    List<Map<String, dynamic>> friends = await _dbGroupTags!.rawQuery('''
        SELECT t.uid, GROUP_CONCAT(u.uid) as users
        FROM tags t
        JOIN user u ON u.group_tags LIKE '%' || t.uid || '%'
        GROUP BY t.uid;
        ''');

    for (Map<String, dynamic> perFriend in friends) {
      var tagUid = perFriend['uid'];
      //perFriend['users']內容為：2317,2625,
      var users = perFriend['users'];
      result[tagUid] = users;
    }

    // List<User> users = [];
    // for (Map<String, dynamic> perFriend in friends) {
    //   users.add(User.fromJson(perFriend));
    // }

    return Future.value(result);
  }

  @override
  Future<int?> clearTags() async {
    return await _dbGroupTags?.delete(tableName);
  }

  ///@param tags 要新增的Tags
  @override
  Future<List<User>> loadFriendsBindingTag({required int tagUid}) async {
    List<Map<String, dynamic>> friends = await _dbGroupTags!.rawQuery(
      '''
        SELECT user.*
        FROM user
        INNER JOIN tags ON user.group_tags LIKE '%' || tags.uid || '%'
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
