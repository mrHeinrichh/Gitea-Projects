import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';

mixin class DBFavourite implements FavouriteInterface {
  static const String tableName = 'favourite';

  @override
  void initFavouriteDB(
    void Function(String? p1) registerTableFunc,
  ) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY,
        parent_id TEXT DEFAULT "",
        data TEXT DEFAULT "",
        created_at INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        deleted_at INTEGER DEFAULT 0,
        source INTEGER,
        user_id INTEGER,
        author_id INTEGER,
        typ TEXT DEFAULT "[]",
        tag TEXT DEFAULT "[]",
        is_pin INTEGER DEFAULT 0,
        chat_typ INTEGER DEFAULT 0,
        is_uploaded INTEGER DEFAULT 1,
        urls TEXT DEFAULT "[]"
        );
        ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadFavouriteList() async {
    return await DatabaseHelper.query(
      tableName,
      where: 'deleted_at = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getNotUploadedFavourites() async {
    return await DatabaseHelper.query(
      tableName,
      where: 'is_uploaded = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getDataByID(int id) async {
    return await DatabaseHelper.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
