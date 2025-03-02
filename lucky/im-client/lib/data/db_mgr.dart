import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_red_packet.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/log.dart';
import 'package:path/path.dart';
import 'package:jxim_client/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synchronized/synchronized.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

import 'db_call_log.dart';
import 'db_chat.dart';
import 'db_interface.dart';
import 'db_message.dart';
import 'db_user.dart';

class DBManager extends EventDispatcher
    with
        DBChat,
        DBMessage,
        DBUser,
        DBGroup,
        DBRedPacket,
        /*DBReactEmoji*/
        DBCallLog
    implements
        DBInterface {
  MDataBase? _db;
  final List<String> _tablesSql = [];

  MDataBase? getMDataBase() {
    return _db;
  }

  /// 注册创建表sql
  @override
  void registerTable(String? sql) {
    if (sql == null || sql.isEmpty) {
      return;
    }
    _tablesSql.add(sql);
  }

  // 初始化
  @override
  Future<void> init(int userID, bool clean) async {
    var dbName = "data_v014_" + userID.toString() + '.db';
    _db = MDataBase();
    void Function(String?) registerTableFunc = (String? sql) {
      registerTable(sql);
    };
    initUserDB(_db);
    initChatDB(_db);
    initMessageDB(_db);
    initGroupDB(_db, registerTableFunc);
    initRedPacketDB(_db, registerTableFunc);
    initCallLogDB(_db);
    // initReactEmojiDB(_db, registerTableFunc);
    await _db?.init(dbName, userID, clean, _tablesSql);
  }

  @override
  Future<int?> replace(String table, Map<String, Object?> values) async {
    return await _db?.replace(table, values);
  }

  @override
  Future<int?> update(String table, Map<String, Object?> values) async {
    MyLog.info("db update, table: ${table}, values: ${values}");
    return await _db?.update(table, values);
  }

  // @override
  // Future<int?> batchInsert(String table, List<Map<String, Object?>> listValues1, List<Map<String, Object?>> listValues2) async {
  //   return await _db?.batchInsert(table, listValues1, listValues2);
  // }

  /// 插入数据
  @override
  Future<int?> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final int? result =
        await _db!.delete(table, where: where, whereArgs: whereArgs);
    MyLog.info(
        "db delete, table: ${table}, where: ${where}, whereArgs: ${whereArgs}");
    return result;
  }

  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    MyLog.info(
        "db query, table: ${table}, where: ${where}, columns: ${columns}, limit: ${limit}, whereArgs: ${whereArgs}, orderBy: ${orderBy}, groupBy: ${groupBy}, having: ${having}");
    return await _db!.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  // 释放
  @override
  Future<void> destroy() async {
    await _db?.destroy();
    _db = null;
    _tablesSql.clear();
  }

  @override
  Future<int> exist(String table, int id) async {
    var res = await _db!
        .rawQuery("select count(*) as count from $table where id == $id");
    return 0;
  }
}

class MDataBase {
  Database? _db;
  final Map<String, List<String>> _tableColumns = {};
  final List<String> _tables = [];
  static String currentVersion = "0.0.0";
  static String latestVersion = "";

  /// 锁
  final _lock = Lock();

  Database? getDatabase() {
    return _db;
  }

  // 初始化
  Future<void> init(String dbName, int userID,  bool clean, List<String> tablesSql) async {
    if (Platform.isWindows) {
      // 获取数据库文件的存储路径
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      var databasesPath = await databaseFactory.getDatabasesPath();
      var dbPath = join(databasesPath, dbName);
      mypdebug("getDatabasesPath:" + dbPath);
      // 清理数据
      if (clean) {
        await databaseFactory.deleteDatabase(dbPath);
      }
      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await databaseFactory.openDatabase(dbPath);
    } else {
      // 获取数据库文件的存储路径
      var databasesPath = "";
      if (Platform.isMacOS) {
        final path = await getApplicationSupportDirectory();
        databasesPath = path.path.toString();
      } else {
        databasesPath = await getDatabasesPath();
      }
      var dbPath = join(databasesPath, dbName);
      mypdebug("getDatabasesPath:" + dbPath);
      // 清理数据
      if (clean) {
        await deleteDatabase(dbPath);
      }
      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await openDatabase(
        dbPath, version: 1,
        // onUpgrade: (Database db, int oldVersion, int newVersion) async {
        //   // 支持动态扩展不需要更新了
        // }
      );
    }
    if(_db == null){
      return;
    }
    String last_db_version_name = LocalStorageMgr.LAST_DB_VERSION + "${userID}";
    if(currentVersion == "0.0.0"){
      try{
        currentVersion = await PlatformUtils.getAppVersion();
        latestVersion = (objectMgr.localStorageMgr.read(last_db_version_name) != null) ? 
                            objectMgr.localStorageMgr.read(last_db_version_name) : "0.0.0";
      }catch(e){
        latestVersion = currentVersion;
      }
    }
    for (var sql in tablesSql) {
      if(currentVersion != latestVersion){
        final tableName = extractTableName(sql);
        if(tableName == "message"){
          await ensureTableSchema(_db!, sql, tableName);
          var codeMessagesList =  await objectMgr.localDB.getColdMessageTables(0,0);
          for(int i = 0; i < codeMessagesList.length; i++){
            await ensureTableSchema(_db!, sql, codeMessagesList[i]);
          }
        }else{
          await ensureTableSchema(_db!, sql, tableName);
        }
      }else{
        await _db?.execute(sql);
      }   
    }
    if(currentVersion != latestVersion){
      objectMgr.localStorageMgr.write(last_db_version_name, currentVersion);
    }
    var res = await _db?.rawQuery(
        "SELECT name FROM sqlite_master where type='table' order by name");
    res?.forEach((element) => _tables.add(element["name"].toString()));
  }

  String? extractTableName(String createStatement) {
    final pattern = RegExp(r'\s*CREATE TABLE IF NOT EXISTS\s+([a-zA-Z_][a-zA-Z0-9_]*)');
    final match = pattern.firstMatch(createStatement);
    return match?.group(1);
  }

  List<Map<String, String>> extractColumns(String createStatement) {
    final pattern = RegExp(r'\((.*?)\)', multiLine: true);
    final match = pattern.firstMatch(createStatement);
    final columns = <Map<String, String>>[];

    if (match != null) {
      final columnDefinitions = match.group(1)!.split(',');
      for (var definition in columnDefinitions) {
        final parts = definition.trim().split(' ');
        if (parts.length >= 2) {
          columns.add({
            'name': parts[0],
            'definition': definition,
          });
        }
      }
    }
    return columns;
  }

  Future<bool> doesTableExist(Database db, String tableName) async {
    try {
      var result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> ensureTableSchema(
    Database db,
    String sql,
    String? tableName
  ) async {
    if (tableName == null) {
      await db.execute(sql);
    } else {
      bool tableExists = await doesTableExist(db, tableName);
      if (!tableExists) {
        await db.execute(sql);
      }else {
        String createStatementTmp = sql.replaceAll('\n', ''); 
        final expectedColumns = extractColumns(createStatementTmp);
        final existingColumns = await db.rawQuery('PRAGMA table_info($tableName)');
        final existingColumnNames = existingColumns.map((col) => col['name']).toSet();
        for (var column in expectedColumns) {
          if (!existingColumnNames.contains(column['name'])) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN ${column['definition']}');
          }
        }
      } 
    }
  }

  /// 获取表字段
  Future<List<String>> _getTableColumns(String table) async {
    List<String> keys = [];
    if (_db == null || !_db!.isOpen) {
      return keys;
    }
    var res = await _db?.rawQuery('PRAGMA table_info($table)');
    if (res != null) {
      for (dynamic row in res) {
        keys.add(row.row[1]);
      }
    }
    return keys;
  }

  /// 校验表字段 todo这边好像有点问题 异步扩展字段 跟插入等等
  Future<bool> _checkTableColumns(
      String table, Map<String, Object?> values) async {
    var keys = _tableColumns[table];
    if (keys == null) {
      keys = (await _getTableColumns(table)).toList();
      _tableColumns[table] = keys;
    }
    if (_db == null || !_db!.isOpen) {
      return false;
    }

    var batch = _db?.batch();
    for (var key in values.keys) {
      if (values[key] is List) {
        values[key] = jsonEncode(values[key]);
      }
      if (!keys.contains(key)) {
        var type = values[key] is String ? 'TEXT' : 'INTEGER';
        var sql = 'alter table $table add column $key $type;';
        batch?.execute(sql);
        // pdebug("+++++:$sql");
        keys.add(key);
      }
    }
    try {
      await batch?.commit();
      return true;
    } catch (e) {
      pdebug(e);
      return false;
    }
  }

  // 等待插入
  Map<String, bool?> insertWait = {};

  Future<int?> replace(String table, Map<String, Object?> values) async {
    MyLog.info("db replace, table: ${table}, values: ${values}");
    var id = values['id'];
    if (id == null || _db == null || !_db!.isOpen || !_tables.contains(table)) {
      return 0;
    }
    var b = await _lock.synchronized(() async {
      return await _checkTableColumns(table, values);
    });
    if (!b) {
      return 0;
    }
    try {
      // 插入锁
      var key = "${table}${id}";
      while (insertWait.containsKey(key)) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      insertWait.addEntries(<String, bool>{key: true}.entries);
      var res = await update(table, values);
      if (res != 1) {
        res = await _db?.insert(table, values);
      }
      insertWait.remove(key);
      return res;
    } catch (e) {}
    return 0;
  }

  Future<int?> update(String table, Map<String, Object?> values) async {
    MyLog.info("db update, table: ${table}, values: ${values}");
    var id = values['id'];
    if (id == null || _db == null || !_db!.isOpen || !_tables.contains(table)) {
      return 0;
    }
    var b = await _lock.synchronized(() async {
      return await _checkTableColumns(table, values);
    });
    if (!b) {
      return 0;
    }
    var res = _db?.update(table, values, where: "id = ?", whereArgs: [id]);

    return res;
  }

  static Future<int?> batchInsert(
      Database _db,
      String table,
      List<Map<String, Object?>> addValueList,
      List<Map<String, Object?>> updateValueList) async {
    int count = 0;

    if ((addValueList.isEmpty && updateValueList.isEmpty) || !_db.isOpen) {
      return count;
    }

    // var b = await _lock.synchronized(() async {
    //   final value = addValueList.isEmpty ? updateValueList.first : addValueList.first;
    //   return await _checkTableColumns(table, value);
    // });
    //
    // if (!b) {
    //   return count;
    // }

    _db.transaction((txn) async {
      Batch batch = txn.batch();

      for (final values in addValueList) {
        var id = values['id'];
        if (id != null) {
          batch.insert(table, values);
        }
      }

      for (final values in updateValueList) {
        var id = values['id'];
        if (id != null) {
          batch.update(table, values, where: "id = ?", whereArgs: [id]);
        }
      }

      final results = await batch.commit();
      count = results.length;
      pdebug("Result============> $count");
    });

    return count;
  }

  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    if (_db == null || !_db!.isOpen || !_tables.contains(table)) {
      return [];
    }
    MyLog.info(
        "table: ${table}, where: ${where}, columns: ${columns}, limit: ${limit}, whereArgs: ${whereArgs}, orderBy: ${orderBy}, groupBy: ${groupBy}, having: ${having}");
    return _db!.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    MyLog.info("db rawQuery, sql: ${sql}, arguments: ${arguments}");
    if (_db == null || !_db!.isOpen) {
      return [];
    }
    return _db!.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    MyLog.info("db rawUpdate, sql: ${sql}, arguments: ${arguments}");
    if (_db == null || !_db!.isOpen) {
      return 0;
    }
    return _db!.rawUpdate(sql, arguments);
  }

  Future<int?> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    MyLog.info(
        "db delete, table: ${table}, where: ${where}, whereArgs: ${whereArgs}");
    if (_db == null || !_db!.isOpen) {
      return 0;
    }
    return _db?.delete(table, where: where, whereArgs: whereArgs);
  }

  // 释放
  Future<void> destroy() async {
    await _db?.close();
    _db = null;
    _tables.clear();
    _tableColumns.clear();
  }
}
