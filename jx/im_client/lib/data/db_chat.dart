import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/debug_info.dart';

mixin class DBChat implements ChatInterface {
  static const String tableName = 'chat';

  @override
  void initChatDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS chat (
        id INTEGER PRIMARY KEY,
        typ INTEGER,
        last_id INTEGER,
        last_typ INTEGER,
        last_msg TEXT,
        last_time INTEGER,
        last_pos INTEGER DEFAULT 0,
        first_pos INTEGER DEFAULT -1,
        msg_idx INTEGER,
        profile Text,
        pin TEXT,
        '''
        // 查询拼接字段
        '''
        icon TEXT,
        icon_gaussian TEXT DEFAULT "",
        name TEXT,
        '''
        // mychat拼接字段
        '''
        user_id  INTEGER,
        chat_id INTEGER,
        friend_id INTEGER,
        sort INTEGER,
        unread_num INTEGER,
        unread_count INTEGER,
        hide_chat_msg_idx INTEGER,
        read_chat_msg_idx INTEGER,
        other_read_idx INTEGER,
        unread_at_msg_idx TEXT,
        delete_time INTEGER,
        '''
        // 查询拼接字段
        '''
        __add_index INTEGER,
        flag INTEGER DEFAULT 0,
        flag_my INTEGER,
        auto_delete_interval INTEGER,
        mute INTEGER,
        verified INTEGER,
        create_time INTEGER,
        start_idx INTEGER,
        is_read_msg INTEGER,
        translate_outgoing TEXT DEFAULT "",
        translate_incoming TEXT DEFAULT "",
        incoming_idx INTEGER DEFAULT 0,
        outgoing_idx INTEGER DEFAULT 0,
        incoming_sound_id INTEGER DEFAULT 0,
        outgoing_sound_id INTEGER DEFAULT 0,
        notification_sound_id INTEGER DEFAULT 0,
        chat_key TEXT DEFAULT "",
        active_chat_key TEXT DEFAULT "",
        cover_idx INTEGER DEFAULT 0,
        round INTEGER DEFAULT 0
        );
        ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadChatList() async {
    pdebug('~~~~~~~~~~~~~locaChatList');
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<bool> isChatEmpty() async {
    List<Map<String, dynamic>> result =
        await DatabaseHelper.rawQuery('select count(*) from $tableName');
    int? count = result.first.values.firstOrNull;
    return count == null || count == 0;
  }

  @override
  Future<int?> clearChat(int chatID) async {
    var where = "chat_id = $chatID";
    return await DatabaseHelper.delete(tableName, where: where);
  }

  @override
  Future<Map<String, dynamic>?> getChatById(int chatID) async {
    var where = "chat_id = $chatID";
    List<Map<String, dynamic>> chatMapList =
        await DatabaseHelper.query(tableName, where: where);
    return chatMapList.isNotEmpty ? chatMapList.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getChatByFriendId(int friendId) async {
    var where = "friend_id = $friendId";
    List<Map<String, dynamic>> chatMapList =
        await DatabaseHelper.query(tableName, where: where);
    return chatMapList.isNotEmpty ? chatMapList.first : null;
  }

  @override
  Future<void> updateChatMsgIdx(int chatId, int msgIdx) async {
    DatabaseHelper.rawQuery(
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

    await DatabaseHelper.rawUpdate(sql);
  }
}
