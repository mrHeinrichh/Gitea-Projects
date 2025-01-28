import 'package:jxim_client/utils/debug_info.dart';

import 'db_interface.dart';
import 'db_mgr.dart';

mixin class DBChat implements ChatInterface {
  static const String tableName = 'chat';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbChat;

  @override
  void initChatDB(MDataBase? db) {
    _dbChat = db;
  }

  @override
  Future<List<Map<String, dynamic>>> loadChatList() async {
    mypdebug('~~~~~~~~~~~~~locaChatList');
    return await _dbChat!.query(tableName);
  }

  Future<bool> isChatEmpty() async {
    List<Map<String, dynamic>> result =
        await _dbChat!.rawQuery('select count(*) from $tableName');
    int? count = result.first.values.firstOrNull;
    return count == null || count == 0;
  }

  @override
  Future<int?> clearChat(int chatID) async {
    var where = "chat_id = ${chatID}";
    return await _dbChat!.delete(tableName, where: where);
  }

  @override
  Future<Map<String, dynamic>?> getChatById(int chatID) async {
    var where = "chat_id = ${chatID}";
    List<Map<String, dynamic>> chatMapList =
        await _dbChat!.query(tableName, where: where);
    return chatMapList.length > 0 ? chatMapList.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getChatByFriendId(int friendId) async {
    var where = "friend_id = ${friendId}";
    List<Map<String, dynamic>> chatMapList =
        await _dbChat!.query(tableName, where: where);
    return chatMapList.length > 0 ? chatMapList.first : null;
  }

  @override
  Future<void> updateChatMsgIdx(int chat_id, int msg_idx) async {
    _dbChat!
        .rawQuery("UPDATE chat SET msg_idx=${msg_idx} WHERE chat_id = ${chat_id} and ${msg_idx} > last_pos");
  }
  
}
