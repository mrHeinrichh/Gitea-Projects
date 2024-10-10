import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';

mixin class DBGroup implements GroupInterface {
  static const String tableName = 'chat_group';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbGroup;

  @override
  void initGroupDB(MDataBase? db, void Function(String? p1) registerTableFunc) {
    _dbGroup = db;
    // 创建会话成员表
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS chat_group (
        id INTEGER PRIMARY KEY,
        user_join_date INTEGER,
        name TEXT,
        profile TEXT,
        icon TEXT,
        permission INTEGER,
        admin INTEGER,
        members TEXT,
        owner INTEGER,
        admins TEXT,
        visible INTEGER,
        speak_interval INTEGER,
        group_type INTEGER,
        room_type INTEGER,
        max_number INTEGER,
        channel_id INTEGER,
        channel_group_id INTEGER,
        create_time INTEGER,
        update_time INTEGER,
        __add_index INTEGER,
        max_member INTEGER,
        expire_time INTEGER
        );
        ''');
  }

  @override
  Future<int?> clearGroup() => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>?> loadGroups() async {
    return await _dbGroup?.query(tableName);
  }

  @override
  Future<Map<String, dynamic>?> loadGroupById(int id) async {
    var where = "id = $id";
    List<Map<String, Object?>>? list =
        await _dbGroup?.query(tableName, where: where);
    return list == null
        ? null
        : list.isNotEmpty
            ? list.first
            : null;
  }

  @override
  Future<List<Map<String, dynamic>>?> getGroupWithSlowMode() async {
    var where = "speak_interval != 0";
    List<Map<String, Object?>>? list =
        await _dbGroup?.query(tableName, where: where);
    return list;
  }
}
