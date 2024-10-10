import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/debug_info.dart';

import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';

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
    pdebug('~~~~~~~~~~~~~locaChatList');
    return await _dbChat!.query(tableName);
  }

  @override
  Future<bool> isChatEmpty() async {
    List<Map<String, dynamic>> result =
        await _dbChat!.rawQuery('select count(*) from $tableName');
    int? count = result.first.values.firstOrNull;
    return count == null || count == 0;
  }

  @override
  Future<int?> clearChat(int chatID) async {
    var where = "chat_id = $chatID";
    return await _dbChat!.delete(tableName, where: where);
  }

  @override
  Future<Map<String, dynamic>?> getChatById(int chatID) async {
    var where = "chat_id = $chatID";
    List<Map<String, dynamic>> chatMapList =
        await _dbChat!.query(tableName, where: where);
    return chatMapList.isNotEmpty ? chatMapList.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getChatByFriendId(int friendId) async {
    var where = "friend_id = $friendId";
    List<Map<String, dynamic>> chatMapList =
        await _dbChat!.query(tableName, where: where);
    return chatMapList.isNotEmpty ? chatMapList.first : null;
  }

  @override
  Future<void> updateChatMsgIdx(int chatId, int msgIdx) async {
    _dbChat!.rawQuery(
      "UPDATE chat SET msg_idx=$msgIdx WHERE chat_id = $chatId and $msgIdx > last_pos",
    );
  }

  @override
  Future<void> updateChatTranslation(Chat chat) async {
    List<String> updates = [];

    if (chat.translate_outgoing != '' && chat.translate_outgoing.isNotEmpty) {
      updates.add("translate_outgoing = '${chat.translate_outgoing}'");
    }

    if (chat.translate_incoming != '' && chat.translate_incoming.isNotEmpty) {
      updates.add("translate_incoming = '${chat.translate_incoming}'");
    }

    if (chat.outgoing_idx != 0) {
      updates.add("outgoing_idx = '${chat.outgoing_idx}'");
    }

    if (chat.incoming_idx != 0) {
      updates.add("incoming_idx = '${chat.incoming_idx}'");
    }

    if (updates.isEmpty) {
      // If there's nothing to update, return early
      return;
    }
    String sql = '''
      UPDATE chat 
      SET ${updates.join(', ')}
      WHERE chat_id = ${chat.chat_id}
    ''';

    await _dbChat!.rawUpdate(sql);
  }
}
