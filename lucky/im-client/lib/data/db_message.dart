import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'db_interface.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db_mgr.dart';

mixin class DBMessage implements MessageInterface {
  static const String tableName = 'message';

  // 名称不一样 方便查找问题 其实都是同一个db
  MDataBase? _dbMessage;

  @override
  void initMessageDB(MDataBase? db) {
    _dbMessage = db;
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessages(
      int chatID, int? lastIdx, int? count, int? hideMsgIdx) async {
    var where = "chat_id = ?";
    var whereArgs = [chatID];

    if (lastIdx != null) {
      where += " and chat_idx <= ?";
      whereArgs.add(lastIdx);
    }

    if (hideMsgIdx != null) {
      where += " and chat_idx > ?";
      whereArgs.add(hideMsgIdx);
    }

    try {
      var rows = await _dbMessage!.query(tableName,
          where: where,
          whereArgs: whereArgs,
          orderBy: 'id, create_time DESC',
          limit: count);
      return rows;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> loadMessage(int chatId, int messageId) async {
    var res = await _dbMessage!.query(tableName,
        where: "chat_id = ? and message_id = ?",
        whereArgs: [chatId, messageId]);
    return res.isNotEmpty ? res[0] : null;
  }

  @override
  Future<int?> clearMessages(int chatID, {int? chatIdx}) async {
    var where = "chat_id = ?";
    var whereArgs = [chatID];
    if (chatIdx != null) {
      where += " and chat_idx <= ?";
      whereArgs.add(chatIdx);
    }
    return await _dbMessage!
        .delete(tableName, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, dynamic>>> searchMessage(String content,  {String tbname = "", int chat_id = -1}) async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if(tbname == ""){
      tbname = "message";
    }
    String chatId = "";
    if(chat_id != -1) {
      chatId = " chat_id = ${chat_id} and";
    }
    return await _dbMessage!
        .rawQuery("SELECT * FROM $tbname WHERE ${chatId} (expire_time = 0 OR expire_time >= $now_time) and content LIKE '%$content%'");
  }

  @override
  Future<List<Map<String, dynamic>>> findMessage(int type) async {
    var res =
        await _dbMessage!.query(tableName, where: "typ = ?", whereArgs: [type]);
    return res;
  }

  @override
  Future<Map<String, dynamic>?> findLatestMessage(
      int chatId, int hideChatIdx) async {
    var res = await _dbMessage!.query(tableName,
        where:
            "chat_id = ? and deleted != 1 and chat_idx > ? and (expire_time == 0 or expire_time > (SELECT strftime('%s', 'now')))",
        whereArgs: [chatId, hideChatIdx],
        limit: 1,
        orderBy: "(chat_idx * 1000 + create_time) desc");
    return res.length > 0 ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMessagesAfter(
      int chatId, int chatIdx) async {
    var res = await _dbMessage!.query(tableName,
        where: "chat_id = ? and chat_idx > ?",
        whereArgs: [chatId, chatIdx],
        orderBy: "chat_idx desc");
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessagesByWhereClause(
    String where, List clauses, String? order, int? limit, {String tbname = ""}) async {
    if(tbname == ""){
      tbname =  tableName;
    }
    final res = await _dbMessage!.query(
      tbname,
      where: where,
      whereArgs: clauses,
      orderBy: "chat_idx ${notBlank(order) ? order : 'desc'}",
      limit: limit,
    );

    return res.isNotEmpty ? res : [];
  }

  @override
  Future<Map<String, dynamic>?> getMyLastSendMessage(int chatId) async {
    var res = await _dbMessage!.query(tableName,
        where: "chat_id = ? and deleted != 1 and send_id = ?",
        whereArgs: [chatId, objectMgr.userMgr.mainUser.uid],
        limit: 1,
        orderBy: "chat_idx desc");
    return res.length > 0 ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> findLatestMessages() async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var res = await _dbMessage!.rawQuery(
        "select *, max(chat_idx * 1000 + create_time) as create_t from message where (expire_time = 0 OR expire_time >= $now_time) and deleted == 0 and typ != $messageTypeDeleted and typ != $messageStartCall group by chat_id order by create_t asc");
    return res;
  } 

  @override
  Future<int> batchSetReadNum(int chatId, int endIdx) async {
    String sql = '''
      UPDATE $tableName
      SET read_num = 1
      WHERE chat_id = $chatId AND read_num = 0 AND chat_idx <= $endIdx
    ''';

    var res = await _dbMessage!.rawUpdate(sql);
    return res;
  }

  @override
  Future<int> getUnreadNum(int chatId, int lastReadIdx) async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final result = await _dbMessage!.rawQuery(
        'select count(*) from $tableName where chat_id = $chatId and read_num = 0 and (expire_time = 0 OR expire_time > $now_time) and typ < 10000 and chat_idx > $lastReadIdx');
    if (result.isNotEmpty) {
      final count = result.first['count(*)'] as int;
      return count;
    }
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getListOfUnreadChats() async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select c.id, count(*) as unreadTotal
        from $tableName m left join ${DBChat.tableName} c on c.id = m.chat_id 
        WHERE (c.flag_my & 32) != 32
        AND m.typ < 10000
        AND m.read_num = 0
        AND m.deleted = 0
        AND m.chat_idx > c.read_chat_msg_idx
        AND (expire_time = 0 OR expire_time > $now_time) 
        AND m.send_id != ${objectMgr.userMgr.mainUser.uid}
        group by m.chat_id;
    ''';
    final result = await _dbMessage!.rawQuery(sql);
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getChatMentionChatIdx() async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select * from ${DBMessage.tableName}
        WHERE deleted = 0 
        AND read_num = 0 
        AND (expire_time = 0 OR expire_time >= $now_time) 
        AND send_id != ${objectMgr.userMgr.mainUser.uid}
        AND content != "[]";
    ''';
    final List<Map<String, Object?>> result = await _dbMessage!.rawQuery(sql);
    return result.isNotEmpty? result: [];
  }

  @override
  String getColdMessageTableName(int createTime){
      DateTime date = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    int year = date.year;
    int month = date.month;
    month = month ~/ MessageMgr.COLD_MESSAGE_SUB_MONTH * MessageMgr.COLD_MESSAGE_SUB_MONTH + (month % MessageMgr.COLD_MESSAGE_SUB_MONTH > 0 ? 1 : 0);
    return "message_" + year.toString() + (month < 10 ? "0" + month.toString() : month.toString());
  }

  @override
  String getNextColdMessageTableName(String coldMessageTableName) {
    // 提取年份和月份
    String yearString = coldMessageTableName.substring(8, 12);
    String monthString = coldMessageTableName.substring(12);

    int year = int.parse(yearString);
    int month = int.parse(monthString);

    // 计算新的年份和月份
    int newYear = year;
    int newMonth = month - MessageMgr.COLD_MESSAGE_SUB_MONTH;
    if (newMonth <= 0) {
      // 如果月份小于等于0，需要调整年份
      newYear -= 1;
      newMonth = 12 + newMonth; // 计算出正确的月份
    }

    // 创建新的日期对象
    DateTime currentDate = DateTime(year, month);
    DateTime nextDate = DateTime(newYear, newMonth, currentDate.day);

    // 格式化下一个日期字符串
    String nextDateString =
        'message_${nextDate.year}${nextDate.month.toString().padLeft(2, '0')}';

    return nextDateString;
  }

  @override
  Future<bool> isTableExists(String codeTableName) async {
     List<Map<String, dynamic>> tables = await _dbMessage!.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$codeTableName'");
    return tables.isNotEmpty;
  }

  @override
  Future<List<String>> getColdMessageTables(int fromTime, int forward) async {
    String sort = "desc";
    if(forward == 1){
      sort = "asc";
    }
    List<Map<String, dynamic>> tables = await _dbMessage!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'message_%'  order by name ${sort}");

    List<String> find_tbnames = [];
    String tbname =  getColdMessageTableName(fromTime);
    var tbnames = tables.map((map) => map['name'] as String).toList();
    bool flag = false;
    for(int i = 0; i < tbnames.length; i++) {
      if(tbnames[i] == tbname){
        flag = true;
      }
      if(!flag){
        continue;
      }
      find_tbnames.add(tbnames[i]);
    }
    if(fromTime == 0){
      find_tbnames = tbnames;
    }

    return find_tbnames;
  }

  @override
  Future<void> adjustHotMessageTable(int chat_id, int read_chat_msg_idx, int hide_chat_msg_idx, int count) async {
    if(count <= 0){
      return;
    }
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select * from
        (select chat_idx
        from $tableName
        WHERE chat_id = $chat_id 
        AND chat_idx < $read_chat_msg_idx
        AND chat_idx > $hide_chat_msg_idx
        AND typ != $messageTypeAddReactEmoji
        AND typ != $messageTypeRemoveReactEmoji
        AND (expire_time = 0 OR expire_time >= $now_time) order by chat_idx desc limit $count) order by chat_idx asc limit 1;
    ''';

    final List<Map<String, Object?>> result = await _dbMessage!.rawQuery(sql);
    List<int> chat_idx_list = result.isNotEmpty
        ? result.map<int>((e) => int.parse(e['chat_idx'].toString())).toList()
        : [];

    if (chat_idx_list.isNotEmpty) {
      _dbMessage!
        .rawQuery("delete FROM message WHERE chat_id = ${chat_id} and (chat_idx < ${chat_idx_list.first} or (expire_time > 0 and expire_time <= $now_time))");
    }
  }

  Future<Map<String, dynamic>?> findMessageByID(int id) async {
    var res = await _dbMessage!.query(tableName,
        where:"id = ?  ",
        whereArgs: [id],
        limit: 1);
    return res.length > 0 ? res.first : null;
  }

  Future<int> updateMessageSub(Message message, {String tname = ""}) async{
    if(tname == ""){
      tname = tableName;
    }
    String sql = '''
      UPDATE $tableName
      SET message_id = ${message.message_id}, chat_idx = ${message.chat_idx}, create_time = ${message.create_time}, content = '${message.content}'
      WHERE id = ${message.id}
    ''';
    return await _dbMessage!.rawUpdate(sql);
  }

  Future<int> saveMessageSub(Message message, {String tname = ""}) async{
    if(tname == ""){
      tname = tableName;
    }
    var jsonData = message.toJson();
    List<String> columns = jsonData.keys.toList();
    List<dynamic> values = jsonData.values.toList();
    String sql = '''
      INSERT INTO $tname (${columns.join(', ')})
      VALUES (${List.filled(columns.length, '?').join(', ')})
      ON CONFLICT(id) DO UPDATE SET
      ${columns.where((col) => col != 'id').map((col) => '$col = excluded.$col').join(', ')}
    ''';
    return await _dbMessage!.getDatabase()!.rawInsert(sql, values);
  }

  @override
  Future<int> saveMessage(Message message) async{
    Map<String, dynamic>? msg = await findMessageByID(message.id);
    if(msg != null) {
      await updateMessageSub(message);
      String coldName = getColdMessageTableName(message.create_time);
      if(await isTableExists(coldName) == false){
        await _dbMessage!.getDatabase()!.execute(ChatMgr.GetCreateMessageTableSql(coldName));
      }
      return await updateMessageSub(message, tname: coldName);
    }else{
      await saveMessageSub(message);
      String coldName = getColdMessageTableName(message.create_time);
      if(await isTableExists(coldName) == false){
        await _dbMessage!.getDatabase()!.execute(ChatMgr.GetCreateMessageTableSql(coldName));
      }
      return await saveMessageSub(message, tname: coldName);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatExpireMessages(int expire) async{
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int need_time = now_time + expire;
    String sql = '''select * from ${DBMessage.tableName}
        WHERE deleted = 0 
        AND read_num = 0 
        AND expire_time != 0
        AND (expire_time >= $now_time AND expire_time < $need_time) 
    ''';
    final List<Map<String, Object?>> result = await _dbMessage!.rawQuery(sql);
    return result.isNotEmpty? result: [];
  }
}

