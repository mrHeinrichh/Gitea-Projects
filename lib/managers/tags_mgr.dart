import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/db_tags.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:uuid/uuid.dart';

class TagsMgr extends EventDispatcher
    implements MgrInterface, TemplateMgrInterface, SqfliteMgrInterface {
  static const String TAGS_CREATE = 'TAGS_CREATE';
  static const String TAGS_UPDATE = 'TAGS_UPDATE';
  static const String TAGS_DELETE = 'TAGS_DELETE';

  static const int TAG_TYPE_MOMENT = 0;
  static const int TAG_TYPE_COLLECTION = 1;

  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;

  List<Tags> allTags = [];

  ///Tags對應的好友，如果標籤uid找不到對應的key，代表此標籤沒有好友
  Map<int, List<User>> tagsBindingFriend = {};

  @override
  Future<void> init() async {
    _sharedDB.on("$blockOptReplace:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.on("$blockOptUpdate:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.on("$blockOptDelete:${DBTags.tableName}", _onTagsUpdate);

    final tempTags = await _localDB.loadAllTags();
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBTags.tableName,
        tempTags,
      ),
      save: false,
      notify: false,
    );

    allTags = tempTags.map((e) => Tags.fromJson(e)).toList();
    loadAllTagsBindingFriend();
  }

  Future<void> loadAllTagsBindingFriend() async {
    for (int i = 0; i < allTags.length; i++) {
      List<User> temp =
          await _localDB.loadFriendsBindingTag(tagUid: allTags[i].uid);
      if (temp.isNotEmpty) {
        tagsBindingFriend[allTags[i].uid] = temp;
      }
    }
  }

  Future<List<User>> loadFriendsBindingTagById(int tagUid) async {
    return await _localDB.loadFriendsBindingTag(tagUid: tagUid);
  }

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
      DBTags.tableName,
      JsonObjectPool<Tags>(Tags.creator),
    );
  }

  @override
  Future<void> registerSqflite() async {
    _localDB.registerTable('''
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
  Future<void> reloadData() async {}

  @override
  Future<void> logout() async {
    allTags.clear();
    _sharedDB.off("$blockOptReplace:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.off("$blockOptUpdate:${DBTags.tableName}", _onTagsUpdate);
    _sharedDB.off("$blockOptDelete:${DBTags.tableName}", _onTagsUpdate);
  }

  void _onTagsUpdate(Object sender, Object type, Object? data) {
    if (type == "$blockOptReplace:${DBTags.tableName}") //新增
    {
      if (data is Tags) {
        event(this, TAGS_CREATE, data: data);
      }
    } else if (type == "$blockOptUpdate:${DBTags.tableName}") //修改
    {
      if (data is Tags) {
        event(this, TAGS_UPDATE, data: data);
      }
    } else if (type == "$blockOptDelete:${DBTags.tableName}") //刪除
    {
      //data = tag.uid.
      if (data is int) {
        event(this, TAGS_DELETE, data: data);
      }
    }
  }

  //新增Tags
  Future<bool> addTags(Tags tags) async {
    //不能新增相同標籤名稱，但應在進入此function前就先做過檢查.
    if (allTags.any((element) => element.tagName == tags.tagName)) {
      return false;
    }

    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBTags.tableName,
        [tags.toJson()],
      ),
      save: true,
      notify: true,
    );

    allTags.add(tags);
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
      notify: true,
    );
  }

  //刪除Tags的方法
  Future<void> deleteTags(int uid) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptDelete,
        DBTags.tableName,
        uid,
      ),
      save: true,
      notify: true,
    );
    allTags.removeWhere((element) => element.uid == uid);
  }

  ///@param type -1:全部(預設) 1:朋友圈 2:收藏
  ///取得所有Tags的方法
  Future<void> getAllTags({int type = -1}) async {
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
  }

  Future<void> getAllTagByGroup() async {}

  //取得特定的Tag
  Future<Map<String, dynamic>?> getTagsById(int uid) async {
    return await _localDB.loadTags(uid);
  }

  static int generateNumericUUID() {
    String uuid = const Uuid().v4();
    String numericUUID = uuid.replaceAll(RegExp(r'[^0-9]'), '');
    //32位數改取16位數避免後端陣列溢位
    return int.parse(numericUUID.substring(0, 16));
  }

  ///測試用
  void createFakeTag(String name) {
    Tags tags = Tags();
    tags.uid = 123;
    tags.tagName = "1";
    tags.type = TAG_TYPE_MOMENT;
    tags.createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    tags.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    objectMgr.tagsMgr.addTags(tags);

    tags = Tags();
    tags.uid = 345;
    tags.tagName = "2";
    tags.type = TAG_TYPE_MOMENT;
    tags.createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    tags.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    objectMgr.tagsMgr.addTags(tags);

    tags = Tags();
    tags.uid = 789;
    tags.tagName = "3";
    tags.type = TAG_TYPE_COLLECTION;
    tags.createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    tags.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    objectMgr.tagsMgr.addTags(tags);
  }
}
