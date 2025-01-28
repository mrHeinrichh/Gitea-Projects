import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';

mixin class DBRedPacket implements RedPacketInterface {
  static const String tableName = 'red_packet';

  @override
  void initRedPacketDB(
    void Function(String? p1) registerTableFunc,
  ) {
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
    return await DatabaseHelper
        .query(tableName, where: 'chat_id = ?', whereArgs: [chatId]);
  }

  @override
  Future<Map<String, dynamic>> getSingleRedPacketStatus(String rpId) async {
    List<Map<String, dynamic>> result = await DatabaseHelper
        .query(tableName, where: 'id = ?', whereArgs: [rpId]);
    return result.isNotEmpty ? result.first : {};
  }
}
