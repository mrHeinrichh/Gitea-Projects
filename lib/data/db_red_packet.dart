import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';

mixin class DBRedPacket implements RedPacketInterface {
  static const String tableName = 'red_packet';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbRedPacket;

  @override
  void initRedPacketDB(
    MDataBase? db,
    void Function(String? p1) registerTableFunc,
  ) {
    _dbRedPacket = db;
    // 创建会话成员表
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS red_packet (
        id TEXT PRIMARY KEY,
        message_id INTEGER,
        chat_id INTEGER,
        status INTEGER,
        user_id INTEGER
        );
        ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadRedPacketStatus(int chatId) async {
    return await _dbRedPacket!
        .query(tableName, where: 'chat_id = ?', whereArgs: [chatId]);
  }

  @override
  Future<Map<String, dynamic>> getSingleRedPacketStatus(String rpId) async {
    List<Map<String, dynamic>> result = await _dbRedPacket!
        .query(tableName, where: 'id = ?', whereArgs: [rpId]);
    return result.isNotEmpty ? result.first : {};
  }
}
