import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';

mixin class DBRetry implements RetryInterface {
  static const String tableName = 'retry';

  @override
  void initRetryDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS  retry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER, 
        api_type TEXT DEFAULT "",
        end_point TEXT DEFAULT "",
        request_data TEXT DEFAULT "",
        synced INTEGER,
        callback_fun TEXT DEFAULT "",
        expired INTEGER,
        replace INTEGER,
        expire_time INTEGER,
        create_time INTEGER,                
        __add_index INTEGER
        );
        ''');
  }

  @override
  Future<Map<String, dynamic>?> loadRetryItem(int uid) async {
    List<Map<String, dynamic>> groupTagsMapList = await DatabaseHelper
        .query(tableName, where: "uid = ?", whereArgs: [uid]);
    return groupTagsMapList.isNotEmpty ? groupTagsMapList.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> loadRetryItemByEndPoint(
      String endPoint) async {

    return await DatabaseHelper.query(tableName,
        where: "end_point = ? AND synced = ?",
        whereArgs: [endPoint, 0],
        orderBy: "create_time ASC");
  }

  ///@param synced 0:未同步 1:同步 -1:失敗
  @override
  Future<List<Map<String, dynamic>>> loadAllRetryItems(int synced) async {
    ///取得全部Retry
    return await DatabaseHelper.query(tableName,
        where: "synced = ?", whereArgs: [synced], orderBy: "create_time ASC");
  }

  @override
  Future<int?> deleteFinishRetry() async {
    return await DatabaseHelper
        .delete(tableName, where: "synced IN (?, ?, ?, ?)", whereArgs: [
      RetryStatus.SYNCED_SUCCESS,
      RetryStatus.SYNCED_FAILED,
      RetryStatus.SYNCED_CANCEL,
      RetryStatus.SYNCED_REPLACE
    ]);
  }

  @override
  Future<int?> clearRetryItems() async {
    return await DatabaseHelper.delete(tableName);
  }
}
