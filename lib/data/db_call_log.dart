import 'package:jxim_client/data/db_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';

import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/object/call.dart';

mixin class DBCallLog implements CallLogInterface {
  static const String tableName = 'call_log';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbCallLog;

  @override
  void initCallLogDB(MDataBase? db) {
    _dbCallLog = db;
  }

  @override
  Future<List<Map<String, dynamic>>> loadCallLogs({String? rtcId}) async {
    List<Map<String, dynamic>> callLogMap;
    if (rtcId != null) {
      callLogMap = await _dbCallLog!
          .query(tableName, where: "id = ?", whereArgs: [rtcId]);
    } else {
      callLogMap = await _dbCallLog!.query(tableName, orderBy: "updated_at desc");
    }
    return callLogMap;
  }

  @override
  Future<int> getUnreadCall() async {
    int userID = objectMgr.userMgr.mainUser.uid;
    final result = await _dbCallLog!.rawQuery(
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
    return await _dbCallLog!.getDatabase()!.rawInsert(sql, [
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
    return await _dbCallLog!.delete(tableName, where: where, whereArgs: whereArgs);
  }

  @override
  Future<bool> isExist(String channelID) async {
    final result = await _dbCallLog!
        .rawQuery('select * from $tableName where id = "$channelID"');
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

    var res = await _dbCallLog!.rawUpdate(sql);
    return res;
  }
}
