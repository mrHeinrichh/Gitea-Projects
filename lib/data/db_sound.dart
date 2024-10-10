import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';

mixin class DBSound implements SoundInterface {
  static const String tableName = 'sound';

  MDataBase? _dbSound;

  @override
  void initSoundDB(MDataBase? db, void Function(String? p1) registerTableFunc) {
    _dbSound = db;
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
    return await _dbSound!.query(tableName);
  }

  @override
  Future<int?> clearSoundTable() async {
    return await _dbSound!.delete(tableName);
  }
}
