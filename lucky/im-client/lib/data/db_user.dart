import 'db_interface.dart';
import 'db_mgr.dart';

mixin class DBUser implements UserInterface {
  static const String tableName = 'user';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbUser;

  @override
  void initUserDB(MDataBase? db) {
    _dbUser = db;
  }

  @override
  Future<Map<String, dynamic>?> loadUser(int id) async {
    List<Map<String, dynamic>> userMapList =
        await _dbUser!.query(tableName, where: "id = ?", whereArgs: [id]);
    return userMapList.length > 0 ? userMapList.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> loadAllUsers() async {
    return await _dbUser!.query(tableName);
  }

  @override
  Future<int?> clearUser() async {
    return await _dbUser?.delete(tableName);
  }
}
