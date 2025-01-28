import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';

mixin class DBSound implements SoundInterface {
  static const String tableName = 'sound';

  @override
  void initSoundDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS sound (
        id INTEGER PRIMARY KEY,
        file_path TEXT DEFAULT "",
        typ INTEGER,
        name TEXT DEFAULT "",
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER DEFAULT 0,
        channel_group_id INTEGER,
        is_default INTEGER
        );
        ''');
  }

  @override
  Future<List<Map<String, dynamic>>> loadSoundTrackList() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> clearSoundTable() async {
    return await DatabaseHelper.delete(tableName);
  }
}
