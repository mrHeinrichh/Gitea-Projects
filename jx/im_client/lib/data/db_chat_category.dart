import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';

mixin class DBChatCategory implements ChatCategoryInterface {
  static const String tableName = 'chat_category';

  @override
  void initChatCategoryDB(
    void Function(String? p1) registerTableFunc,
  ) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE,
        included_chat_ids TEXT,
        excluded_chat_ids TEXT,
        seq INTEGER,
        created_at INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        deleted_at INTEGER DEFAULT 0
        );
        ''');
  }

  @override
  Future<List<Map<String, dynamic>>> getChatCategoryList() {
    return DatabaseHelper.query(tableName);
  }

  @override
  Future<bool> isChatCategoryEmpty() async {
    List<Map<String, dynamic>> result =
        await DatabaseHelper.rawQuery('select count(*) from $tableName');
    int? count = result.first.values.firstOrNull;
    return count == null || count == 0;
  }
}
