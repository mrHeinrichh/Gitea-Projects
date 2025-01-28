import 'package:jxim_client/data/db_mgr.dart';
import 'package:jxim_client/main.dart';

import '../managers/call_mgr.dart';
import 'db_interface.dart';

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
      callLogMap = await _dbCallLog!.query(tableName);
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
