import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';

mixin class DBRetry implements RetryInterface {
  static const String tableName = 'retry';

  MDataBase? _dbGroupRetry;

  @override
  void initRetryDB(MDataBase? db) {
    _dbGroupRetry = db;
  }

  @override
  Future<Map<String, dynamic>?> loadRetryItem(int uid) async {
    List<Map<String, dynamic>> groupTagsMapList =
    await _dbGroupRetry!.query(tableName, where: "uid = ?", whereArgs: [uid]);
    return groupTagsMapList.isNotEmpty ? groupTagsMapList.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> loadRetryItemByEndPoint(String endPoint) async
  {
    if (_dbGroupRetry == null) return [];

    return await _dbGroupRetry!
        .query(tableName, where: "end_point = ? AND synced = ?", whereArgs: [endPoint,0],orderBy: "create_time ASC");
  }

  ///@param synced 0:未同步 1:同步 -1:失敗
  @override
  Future<List<Map<String, dynamic>>> loadAllRetryItems(int synced) async {
    if (_dbGroupRetry == null) return [];

    ///取得全部Retry
    return await _dbGroupRetry!
        .query(tableName, where: "synced = ?", whereArgs: [synced],orderBy: "create_time ASC");
  }

  @override
  Future<int?> clearRetryItems() async {
    return await _dbGroupRetry?.delete(tableName);
  }
}