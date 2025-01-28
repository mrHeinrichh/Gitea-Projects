// import 'package:jxim_client/data/db_mgr.dart';
//
// import 'db_interface.dart';
//
// class DBReactEmoji implements ReactEmojiInterface {
//   static const String tableName = 'react_emoji';
//
//   // 名称不一样 方便查找问题 其实都是同一个db
//   MDataBase? _dbReactEmoji;
//
//   @override
//   void initReactEmojiDB(
//       MDataBase? db, void Function(String? p1) registerTableFunc) {
//     _dbReactEmoji = db;
//     // 创建会话成员表
//     registerTableFunc('''
//         CREATE TABLE IF NOT EXISTS react_emoji (
//         id INTEGER PRIMARY KEY,
//         chat_id INTEGER,
//         message_id INTEGER,
//         user_id INTEGER,
//         emoji TEXT,
//         chat_idx INTEGER
//         );
//         ''');
//   }
//
//   @override
//   Future<List<Map<String, dynamic>>?> loadEmojis(
//       int messageId, int chatId) async {
//     return await _dbReactEmoji?.rawQuery(
//       'SELECT count(*) as count, emoji FROM react_emoji WHERE chat_id = ? AND message_id = ? GROUP BY emoji',
//       [chatId, messageId],
//     );
//   }
// }
