import 'dart:convert';

import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';

mixin class DBMessage implements MessageInterface {
  static const String tableName = 'message';

  @override
  void initMessageDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS message (
        id INTEGER PRIMARY KEY,
        message_id INTEGER,
        chat_id INTEGER,
        chat_idx INTEGER,
        send_id INTEGER,
        content TEXT,
        typ INTEGER,
        send_time INTEGER,
        expire_time INTEGER,
        create_time INTEGER,
        at_users TEXT,
        emojis TEXT DEFAULT "[]",
        edit_time INTEGER DEFAULT 0,
        ref_typ INTEGER DEFAULT 0,
        flag INTEGER DEFAULT 0,
        cmid TEXT DEFAULT ""
        );
      ''');

    registerTableFunc('''
        CREATE INDEX IF NOT EXISTS `chat_id_read_num_idx_index` on message (
        chat_id,
        chat_idx
        );
      ''');

    registerTableFunc('''
        CREATE INDEX IF NOT EXISTS `chat_typ_delete_expire_index` on message (
        chat_id,
        chat_idx,
        typ,
        expire_time
        );
      ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessages(
    int chatID,
    int? lastIdx,
    int? count,
    int? hideMsgIdx,
  ) async {
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
      var rows = await DatabaseHelper.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'id, create_time DESC',
        limit: count,
      );
      return rows;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> loadMessage(int chatId, int messageId) async {
    var res = await DatabaseHelper.query(
      tableName,
      where: "chat_id = ? and message_id = ?",
      whereArgs: [chatId, messageId],
    );
    return res.isNotEmpty ? res[0] : null;
  }

  @override
  Future<int?> clearMessages(int chatID, {int? chatIdx}) async {
    List<String> tables = await getColdMessageTables(0, 0);
    for (var element in tables) {
      clearMessagesSub(element, chatID, chatIdx: chatIdx);
    }
    return clearMessagesSub("message", chatID, chatIdx: chatIdx);
  }

  Future<int?> clearMessagesSub(
    String tbName,
    int chatID, {
    int? chatIdx,
  }) async {
    List<String> tables = await getColdMessageTables(0, 0);
    tables.add("message");
    var where = "chat_id = ?";
    var whereArgs = [chatID];
    if (chatIdx != null) {
      where += " and chat_idx <= ?";
      whereArgs.add(chatIdx);
    }
    return await DatabaseHelper.delete(tbName,
        where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, dynamic>>> searchMessage(
    String content, {
    String tbname = "",
    int chat_id = -1,
  }) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (tbname == "") {
      tbname = "message";
    }
    String chatId = "";
    if (chat_id != -1) {
      chatId = " chat_id = $chat_id and";
    }
    return await DatabaseHelper.rawQuery(
      "SELECT * FROM $tbname WHERE $chatId (expire_time = 0 OR expire_time >= $nowTime) and content LIKE '%$content%'",
    );
  }

  @override
  Future<List<Map<String, dynamic>>> searchUserMessage(
    int userId, {
    String tbname = "",
    int chat_id = -1,
  }) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (tbname == "") {
      tbname = "message";
    }
    String id = "and send_id = $userId ";
    String chatId = "";
    if (chat_id != -1) {
      chatId = " chat_id = $chat_id and";
    }
    List<Map<String, dynamic>> res = await DatabaseHelper.rawQuery(
      "SELECT * FROM $tbname WHERE $chatId (expire_time = 0 OR expire_time >= $nowTime) $id",
    );
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> loadReSendMessage(
      int uid, int reSendTime) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final res = await DatabaseHelper.query(
      tableName,
      where:
          "send_id = ? and message_id == 0 and ((send_time/1000 > ($nowTime - $reSendTime) and (expire_time == 0 or expire_time > $nowTime)) or typ=$messageTypeReqSignChat or typ=$messageTypeCommandFileOperate)",
      whereArgs: [uid],
      orderBy: "(chat_idx*10000 + create_time*10 + send_time/100) asc",
    );

    return res.isNotEmpty ? res : [];
  }

  @override
  Future<List<Map<String, dynamic>>> findMessage(int type) async {
    var res = await DatabaseHelper.query(tableName,
        where: "typ = ?", whereArgs: [type]);
    return res;
  }

  @override
  Future<Map<String, dynamic>?> findLatestMessage(
    int chatId,
    int hideChatIdx,
  ) async {
    var res = await DatabaseHelper.query(
      tableName,
      where:
          "chat_id = ? and chat_idx > ? and (expire_time == 0 or expire_time > (SELECT strftime('%s', 'now'))) and typ < 12000",
      whereArgs: [chatId, hideChatIdx],
      limit: 1,
      orderBy: "(chat_idx*10000 + create_time*10 + send_time/100) desc",
    );
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMessagesAfter(
    int chatId,
    int chatIdx,
  ) async {
    var res = await DatabaseHelper.query(
      tableName,
      where: "chat_id = ? and chat_idx > ?",
      whereArgs: [chatId, chatIdx],
      orderBy: "chat_idx desc",
    );
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessagesByWhereClause(
    String where,
    List clauses,
    String? order,
    int? limit,
    int? offset, {
    String tbname = "",
    String orderBy = "chat_idx",
  }) async {
    if (tbname == "") {
      tbname = tableName;
    }
    final res = await DatabaseHelper.query(
      tbname,
      where: where,
      whereArgs: clauses,
      orderBy: "$orderBy ${notBlank(order) ? order : 'desc'}",
      limit: limit,
      offset: offset,
    );

    return res.isNotEmpty ? res : [];
  }

  @override
  Future<Map<String, dynamic>?> getMyLastSendMessage(int chatId) async {
    var res = await DatabaseHelper.query(
      tableName,
      where: "chat_id = ? and send_id = ?",
      whereArgs: [chatId, objectMgr.userMgr.mainUser.uid],
      limit: 1,
      orderBy: "chat_idx desc",
    );
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> findLatestMessages() async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var res = await DatabaseHelper.rawQuery(
      "select *, max(chat_idx*10000 + create_time*10 + send_time/100) as create_t from message where (expire_time = 0 OR expire_time >= $nowTime) and typ != $messageTypeDeleted and typ != $messageStartCall and typ < 12000 group by chat_id order by create_t asc",
    );
    return res;
  }

  @override
  Future<int> getUnreadNum(int chatId, int lastReadIdx) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final result = await DatabaseHelper.rawQuery(
      'select count(*) from $tableName where chat_id = $chatId  and (expire_time = 0 OR expire_time > $nowTime) and typ < 10000 and chat_idx > $lastReadIdx',
    );
    if (result.isNotEmpty) {
      final count = result.first['count(*)'] as int;
      return count;
    }
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getListOfUnreadChats() async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select c.id, count(*) as unreadTotal
        from $tableName m left join ${DBChat.tableName} c on c.id = m.chat_id 
        WHERE (c.flag_my & 32) != 32
        AND m.typ < 10000
        AND m.chat_idx > c.read_chat_msg_idx
        AND (expire_time = 0 OR expire_time > $nowTime) 
        AND m.send_id != ${objectMgr.userMgr.mainUser.uid}
        group by m.chat_id;
    ''';
    final result = await DatabaseHelper.rawQuery(sql);
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getChatMentionChatIdx() async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select *
        from ${DBMessage.tableName} m left join ${DBChat.tableName} c on c.id = m.chat_id 
        WHERE (c.flag_my & 32) != 32
        AND m.typ < 10000
        AND m.chat_idx > c.read_chat_msg_idx
        AND (expire_time = 0 OR expire_time > $nowTime) 
        AND m.send_id != ${objectMgr.userMgr.mainUser.uid}
        AND at_users != "[]";
    ''';
    final result = await DatabaseHelper.rawQuery(sql);
    return result;
  }

  @override
  String getColdMessageTableName(int createTime) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    int year = date.year;
    int month = date.month;
    month = month ~/
            MessageMgr.COLD_MESSAGE_SUB_MONTH *
            MessageMgr.COLD_MESSAGE_SUB_MONTH +
        (month % MessageMgr.COLD_MESSAGE_SUB_MONTH > 0 ? 1 : 0);
    return "message_$year${month < 10 ? "0$month" : month.toString()}";
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
    List<Map<String, dynamic>> tables = await DatabaseHelper.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$codeTableName'",
    );
    return tables.isNotEmpty;
  }

  @override
  Future<List<String>> getColdMessageTables(int fromTime, int forward) async {
    String sort = "desc";
    if (forward == 1) {
      sort = "asc";
    }
    List<Map<String, dynamic>> tables = await DatabaseHelper.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'message_%'  order by name $sort",
    );

    List<String> findTbnames = [];
    String tbname = getColdMessageTableName(fromTime);
    var tbnames = tables.map((map) => map['name'] as String).toList();
    bool flag = false;
    for (int i = 0; i < tbnames.length; i++) {
      if (tbnames[i] == tbname) {
        flag = true;
      }
      if (!flag) {
        continue;
      }
      findTbnames.add(tbnames[i]);
    }
    if (fromTime == 0) {
      findTbnames = tbnames;
    }

    return findTbnames;
  }

  @override
  Future<void> adjustHotMessageTable(
    int chatId,
    int readChatMsgIdx,
    int hideChatMsgIdx,
    int count,
  ) async {
    if (count <= 0) {
      return;
    }
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String sql = '''select * from
        (select chat_idx
        from $tableName
        WHERE chat_id = $chatId 
        AND chat_idx < $readChatMsgIdx
        AND chat_idx > $hideChatMsgIdx
        AND typ != $messageTypeAddReactEmoji
        AND typ != $messageTypeRemoveReactEmoji
        AND (expire_time = 0 OR expire_time >= $nowTime) order by chat_idx desc limit $count) order by chat_idx asc limit 1;
    ''';

    final List<Map<String, Object?>> result =
        await DatabaseHelper.rawQuery(sql);
    List<int> chatIdxList = result.isNotEmpty
        ? result.map<int>((e) => int.parse(e['chat_idx'].toString())).toList()
        : [];

    if (chatIdxList.isNotEmpty) {
      DatabaseHelper.rawQuery(
        "delete FROM message WHERE chat_id = $chatId and (chat_idx < ${chatIdxList.first} or (expire_time > 0 and expire_time <= $nowTime))",
      );
    }
  }

  Future<Map<String, dynamic>?> findMessageByID(int id) async {
    var res = await DatabaseHelper.query(
      tableName,
      where: "id = ?  ",
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateMessageSub(Message message, {String tname = ""}) async {
    if (tname == "") {
      tname = tableName;
    }
    String sql = '''
      UPDATE $tableName SET message_id = ?, chat_idx = ?, content = ?, expire_time = ?, flag = ? WHERE id = ?''';
    return await DatabaseHelper.rawUpdate(
      sql,
      [
        message.message_id,
        message.chat_idx,
        message.content,
        message.expire_time,
        message.flag,
        message.id,
      ],
    );
  }

  Future<int> saveMessageSub(Message message, {String tname = ""}) async {
    if (tname == "") {
      tname = tableName;
    }
    String sql = '''
    INSERT OR REPLACE INTO $tname (id, message_id, chat_id, chat_idx, create_time, content, send_time, send_id, typ, at_users, emojis, expire_time, flag, cmid)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?)
  ''';

    return await DatabaseHelper.rawInsert(sql, [
      message.id,
      message.message_id,
      message.chat_id,
      message.chat_idx,
      message.create_time,
      message.content,
      message.send_time,
      message.send_id,
      message.typ,
      jsonEncode(message.atUser).toString(),
      jsonEncode(message.emojis).toString(),
      message.expire_time,
      message.flag,
      message.cmid
    ]);
  }

  @override
  Future<int> saveMessage(Message message) async {
    Map<String, dynamic>? msg = await findMessageByID(message.id);
    if (msg != null) {
      await updateMessageSub(message);
      String coldName = getColdMessageTableName(message.create_time);
      if (await isTableExists(coldName) == false) {
        await DatabaseHelper.execute(
            ChatMgr.getCreateMessageTableSql(coldName));
      }
      return await updateMessageSub(message, tname: coldName);
    } else {
      await saveMessageSub(message);
      String coldName = getColdMessageTableName(message.create_time);
      if (await isTableExists(coldName) == false) {
        await DatabaseHelper.execute(
            ChatMgr.getCreateMessageTableSql(coldName));
      }
      return await saveMessageSub(message, tname: coldName);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatExpireMessages(int expire) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int needTime = nowTime + expire;
    String sql = '''select * from ${DBMessage.tableName}
        WHERE expire_time != 0
        AND (expire_time >= $nowTime AND expire_time < $needTime) 
    ''';
    final List<Map<String, Object?>> result =
        await DatabaseHelper.rawQuery(sql);
    return result.isNotEmpty ? result : [];
  }

  @override
  Future<int> updateMessageContent(Message message) async {
    await updateTranslationSub(message);
    String coldName = getColdMessageTableName(message.create_time);
    if (await isTableExists(coldName) == false) {
      await DatabaseHelper.execute(ChatMgr.getCreateMessageTableSql(coldName));
    }
    return await updateTranslationSub(message, tname: coldName);
  }

  Future<int> updateTranslationSub(Message message, {String tname = ""}) async {
    if (tname == "") {
      tname = tableName;
    }
    String sql = '''
      UPDATE $tname SET content = ? WHERE id = ? ''';
    return await DatabaseHelper.rawUpdate(
      sql,
      [message.content, message.id],
    );
  }

  @override
  Future<int> getMessageCount(List<int> types, String? searchText) async {
    String sql =
        "select count(*) as count from ${DBMessage.tableName} WHERE (expire_time == 0 OR expire_time >= ${DateTime.now().millisecondsSinceEpoch ~/ 1000}) AND ref_typ == 0";

    if (types.isNotEmpty) {
      sql += " AND typ IN (${types.join(',')})";
    }

    if (searchText != null) {
      sql += " AND content LIKE '%$searchText%'";
    }

    final List<Map<String, Object?>> result =
        await DatabaseHelper.rawQuery(sql);

    return result.first['count'] as int;
  }
}
