import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/call.dart';

mixin class DBCallLog implements CallLogInterface {
  static const String tableName = 'call_log';

  @override
  void initCallLogDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
               CREATE TABLE IF NOT EXISTS call_log (
        id TEXT PRIMARY KEY,
        caller_id INTEGER,
        receiver_id INTEGER,
        chat_id INTEGER,
        duration INTEGER,
        video_call INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        ended_at INTEGER,
        status INTEGER,
        is_deleted INTEGER,
        deleted_at INTEGER,
        is_read INTEGER
        );
      ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadCallLogs({String? rtcId}) async {
    List<Map<String, dynamic>> callLogMap;
    if (rtcId != null) {
      callLogMap = await DatabaseHelper.query(tableName,
          where: "id = ?", whereArgs: [rtcId]);
    } else {
      callLogMap =
          await DatabaseHelper.query(tableName, orderBy: "updated_at desc");
    }
    return callLogMap;
  }

  @override
  Future<int> getUnreadCall() async {
    int userID = objectMgr.userMgr.mainUser.uid;
    final result = await DatabaseHelper.rawQuery(
        'select count(*) from $tableName where is_read = 0 and caller_id != $userID and '
        '(status = ${CallEvent.CallOptBusy.event} OR status = ${CallEvent.CallOptCancel.event} '
        'OR status = ${CallEvent.CallOptEnd.event} OR status = ${CallEvent.CallTimeOut.event})');
    if (result.isNotEmpty) {
      final count = result.first['count(*)'] as int;
      return count;
    }
    return 0;
  }

  @override
  Future<int> saveCallLog(Call call) async {
    String sql = '''
    INSERT OR REPLACE INTO $tableName (id, caller_id, receiver_id, chat_id, duration, created_at, updated_at, ended_at, status, is_read, video_call)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';
    return await DatabaseHelper.rawInsert(sql, [
      call.channelId,
      call.callerId,
      call.receiverId,
      call.chatId,
      call.duration,
      call.createdAt,
      call.updatedAt,
      call.endedAt,
      call.status,
      call.isRead,
      call.isVideoCall,
    ]);
  }

  @override
  Future<int?> removeCallLog(String id) async {
    var where = "id = ?";
    var whereArgs = [id];
    return await DatabaseHelper.delete(tableName,
        where: where, whereArgs: whereArgs);
  }

  @override
  Future<bool> isExist(String channelID) async {
    final result = await DatabaseHelper.rawQuery(
        'select * from $tableName where id = "$channelID"');
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<int> updateCallRead() async {
    String sql = '''
      UPDATE $tableName
      SET is_read = 1
    ''';

    var res = await DatabaseHelper.rawUpdate(sql);
    return res;
  }
}
