import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';

mixin class DBExploreMiniApp implements ExploreMiniAppInterface {
  static const String tableName = 'explore_mini_app';

  @override
  void initExploreMiniAppDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        openuid TEXT,
        dev_id TEXT,
        icon TEXT,
        icon_gaussian TEXT,
        download_url TEXT,
        description TEXT,
        version INTEGER,
        typ INTEGER,
        flag INTEGER,
        review_status INTEGER,
        favorite_at INTEGER,
        is_active INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER,
        score REAL,
        channels TEXT，
        dev_name TEXT,
        picture_gaussian TEXT,
        picture TEXT,
        comment_num INTEGER,
        last_login_at INTEGER
        );
        ''');
  }

  @override
  Future<int?> insertExploreMiniApp(Map<String, dynamic> data) async {
    return await DatabaseHelper.insert(tableName, data);
  }

  @override
  Future<Map<String, dynamic>?> findExploreMiniAppById(String id) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      "SELECT id FROM $tableName WHERE app_id = ?",
      [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadExploreMiniApps() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> clearExploreMiniAppTable() async {
    return await DatabaseHelper.delete(tableName);
  }
}

mixin class DBRecentMiniApp implements RecentMiniAppInterface {
  static const String tableName = 'recent_mini_app';

  @override
  void initRecentMiniAppDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        openuid TEXT,
        dev_id TEXT,
        icon TEXT,
        icon_gaussian TEXT,
        download_url TEXT,
        description TEXT,
        version INTEGER,
        typ INTEGER,
        flag INTEGER,
        review_status INTEGER,
        favorite_at INTEGER,
        is_active INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER,
        score REAL,
        channels TEXT,
        dev_name TEXT,
        picture_gaussian TEXT,
        picture TEXT,
        comment_num INTEGER,
        last_login_at INTEGER
        );
        ''');
  }

  @override
  Future<int?> insertRecentMiniApp(Map<String, dynamic> data) async {
    return await DatabaseHelper.insert(tableName, data);
  }

  @override
  Future<int?> removeRecentMiniApp(String id) async {
    final where = "id = $id";
    return await DatabaseHelper.delete(tableName, where: where);
  }

  @override
  Future<Map<String, dynamic>?> findRecentMiniAppById(String id) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      "SELECT id FROM $tableName WHERE app_id = ?",
      [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadRecentMiniApps() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> clearRecentMiniAppTable() async {
    return await DatabaseHelper.delete(tableName);
  }
}

mixin class DBFavoriteMiniApp implements FavoriteMiniAppInterface {
  static const String tableName = 'favorite_mini_app';

  @override
  void initFavoriteMiniAppDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        openuid TEXT,
        dev_id TEXT,
        icon TEXT,
        icon_gaussian TEXT,
        download_url TEXT,
        description TEXT,
        version INTEGER,
        typ INTEGER,
        flag INTEGER,
        review_status INTEGER,
        favorite_at INTEGER,
        is_active INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER,
        score REAL,
        channels TEXT,
        dev_name TEXT,
        picture_gaussian TEXT,
        picture TEXT,
        comment_num INTEGER,
        last_login_at INTEGER
        );
        ''');
  }

  @override
  Future<int?> insertFavoriteMiniApp(Map<String, dynamic> data) async {
    return await DatabaseHelper.insert(tableName, data);
  }

  @override
  Future<int?> removeFavoriteMiniApp(String id) async {
    final where = "id = $id";
    return await DatabaseHelper.delete(tableName, where: where);
  }

  @override
  Future<Map<String, dynamic>?> findFavoriteMiniAppById(String id) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      "SELECT id FROM $tableName WHERE app_id = ?",
      [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadFavoriteMiniApps() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> clearFavoriteMiniAppTable() async {
    return await DatabaseHelper.delete(tableName);
  }
}


mixin class DBDiscoverMiniApp implements DiscoverMiniAppInterface {
  static const String tableName = 'discover_mini_app';

  @override
  void initDiscoverMiniAppDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        openuid TEXT,
        dev_id TEXT,
        icon TEXT,
        icon_gaussian TEXT,
        download_url TEXT,
        description TEXT,
        version INTEGER,
        typ INTEGER,
        flag INTEGER,
        review_status INTEGER,
        favorite_at INTEGER,
        is_active INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER,
        score REAL,
        channels TEXT,
        dev_name TEXT,
        picture_gaussian TEXT,
        picture TEXT,
        comment_num INTEGER,
        last_login_at INTEGER
        );
        ''');
  }

  @override
  Future<int?> insertDiscoverMiniApp(Map<String, dynamic> data) async {
    return await DatabaseHelper.insert(tableName, data);
  }


  @override
  Future<List<Map<String, dynamic>>> loadDiscoverMiniApps() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> clearDiscoverMiniAppTable() async {
    return await DatabaseHelper.delete(tableName);
  }
}
