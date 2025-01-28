import 'dart:convert';
import 'dart:io';

import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MDataBase {
  static Database? db;
  static final Map<String, List<String>> _tableColumns = {};
  static String currentVersion = "0.0.0";
  static String latestVersion = "";

  Database? getDatabase() {
    return db;
  }
  closeDatabase() {
    db?.close();
    db = null;
  }

  Future<void> initWith({required DatabaseIsolateParams params}) async {
    if (Platform.isWindows) {
      // 获取数据库文件的存储路径
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      var databasesPath = await databaseFactory.getDatabasesPath();
      var dbPath = join(databasesPath, params.dbName);
      pdebug("getDatabasesPath:$dbPath");
      // 清理数据
      if (params.clean) {
        await databaseFactory.deleteDatabase(dbPath);
      }
      // 根据数据库文件路径和数据库版本号创建数据库表
      db ??= await databaseFactory.openDatabase(dbPath);
    } else {
      // 获取数据库文件的存储路径
      var databasesPath = "";
      if (Platform.isMacOS) {
        //独立线程所生成的必须自己算路径
        var applicationSupportDirectory =
            await getApplicationSupportDirectory();
        databasesPath = applicationSupportDirectory.path;
      } else {
        databasesPath = await getDatabasesPath();
      }
      var dbPath = join(databasesPath, params.dbName);
      pdebug("getDatabasesPath:$dbPath");
      // 清理数据
      if (params.clean) {
        await deleteDatabase(dbPath);
      }
      // 根据数据库文件路径和数据库版本号创建数据库表
      for (int i = 1; i <= 5; i++) {
        try {
          db ??= await openDatabase(dbPath, version: 1);
          if (db != null) {
            break;
          }
        } catch (e) {
          await Future.delayed(Duration(milliseconds: 200 * i));
        }
      }
    }

    if (db == null) {
      return;
    }

    for (var sql in params.tables) {
      if (params.hasVersionChange) {
        final tableName = extractTableName(sql);
        if (tableName == "message") {
          await ensureTableSchema(db!, sql, tableName);
          var codeMessagesList = await getColdMessageTables(0, 0);
          for (int i = 0; i < codeMessagesList.length; i++) {
            await ensureTableSchema(db!, sql, codeMessagesList[i]);
          }
        } else {
          await ensureTableSchema(db!, sql, tableName);
        }
      } else {
        await db?.execute(sql);
      }
    }
  }

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

  Future<List<String>> getColdMessageTables(int fromTime, int forward) async {
    String sort = "desc";
    if (forward == 1) {
      sort = "asc";
    }
    List<Map<String, dynamic>> tables = await db!.rawQuery(
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

  String? extractTableName(String createStatement) {
    final pattern =
        RegExp(r'\s*CREATE TABLE IF NOT EXISTS\s+([a-zA-Z_][a-zA-Z0-9_]*)');
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
    String? tableName,
  ) async {
    if (tableName == null) {
      await db.execute(sql);
    } else {
      bool tableExists = await doesTableExist(db, tableName);
      if (!tableExists) {
        await db.execute(sql);
      } else {
        String createStatementTmp = sql.replaceAll('\n', '');
        final expectedColumns = extractColumns(createStatementTmp);
        final existingColumns =
            await db.rawQuery('PRAGMA table_info($tableName)');
        final existingColumnNames =
            existingColumns.map((col) => col['name']).toSet();
        for (var column in expectedColumns) {
          if (!existingColumnNames.contains(column['name'])) {
            await db.execute(
              'ALTER TABLE $tableName ADD COLUMN ${column['definition']}',
            );
          }
        }
      }
    }
  }

  /// 获取表字段
  static Future<List<String>> _getTableColumns(String table) async {
    List<String> keys = [];
    if (db == null || !db!.isOpen) {
      return keys;
    }
    var res = await db?.rawQuery('PRAGMA table_info($table)');
    if (res != null) {
      for (dynamic row in res) {
        keys.add(row.row[1]);
      }
    }
    return keys;
  }

  /// 校验表字段 todo这边好像有点问题 异步扩展字段 跟插入等等
  static Future<bool> checkTableColumns(
    String table,
    Map<String, Object?> values,
  ) async {
    var keys = _tableColumns[table];
    if (keys == null) {
      keys = (await _getTableColumns(table)).toList();
      _tableColumns[table] = keys;
    }
    if (db == null || !db!.isOpen) {
      return false;
    }
    for (var key in values.keys) {
      if (values[key] is List) {
        values[key] = jsonEncode(values[key]);
      }
    }
    values.removeWhere((key, value) => !keys!.contains(key));
    return true;
  }

  // 等待插入
  Map<String, bool?> insertWait = {};

  Future<int?> replace(String table, Map<String, Object?> values) async {
    var id = values['id'];
    if (id == null || db == null || !db!.isOpen) {
      return 0;
    }
    if (await checkTableColumns(table, values) == false) {
      return 0;
    }
    try {
      // 插入锁
      var key = "$table$id";
      while (insertWait.containsKey(key)) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      insertWait.addEntries(<String, bool>{key: true}.entries);
      var res = await update(table, values);
      if (res != 1) {
        res = await db?.insert(table, values);
      }
      insertWait.remove(key);
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Object?>> batchReplace(String table, List<Map<String, Object?>> values) async {
    if(values.isEmpty){
      return [];
    }
    var id = values[0]['id'];
    if (id == null || db == null || !db!.isOpen) {
      return [];
    }
    if (await checkTableColumns(table, values[0]) == false) {
      return [];
    }
    try {
      Batch batch = db!.batch();
      for(var value in values){
        batch.insert(table, value, conflictAlgorithm:ConflictAlgorithm.replace);
      }
      return await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<int?> update(String table, Map<String, Object?> values) async {
    var id = values['id'];
    if (id == null || db == null || !db!.isOpen) {
      return 0;
    }
    if (await checkTableColumns(table, values) == false) {
      return 0;
    }
    var res = db?.update(table, values, where: "id = ?", whereArgs: [id]);

    return res;
  }

  static Future<int?> batchInsert(
    Database db,
    String table,
    List<Map<String, Object?>> addValueList,
    List<Map<String, Object?>> updateValueList,
  ) async {
    int count = 0;

    if ((addValueList.isEmpty && updateValueList.isEmpty) || !db.isOpen) {
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

    db.transaction((txn) async {
      Batch batch = txn.batch();

      for (final values in addValueList) {
        if (await checkTableColumns(table, values) == false) {
          break;
        }
        var id = values['id'];
        if (id != null) {
          batch.insert(table, values);
        }
      }

      for (final values in updateValueList) {
        if (await checkTableColumns(table, values) == false) {
          break;
        }
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

  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (db == null || !db!.isOpen) {
      return [];
    }
    return db!.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (db == null || !db!.isOpen) {
      return [];
    }
    return db!.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    if (db == null || !db!.isOpen) {
      return 0;
    }
    return db!.rawUpdate(sql, arguments);
  }

  Future<int?> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (db == null || !db!.isOpen) {
      return 0;
    }
    return db?.delete(table, where: where, whereArgs: whereArgs);
  }

  // 释放
  Future<void> destroy() async {
    await db?.close();
    db = null;
    _tableColumns.clear();
  }
}

class DatabaseIsolateParams {
  String dbName;
  int userId;
  bool hasVersionChange;
  bool clean;
  List<String> tables;
  String currentVersion;
  String lastDbVersionName;

  DatabaseIsolateParams({
    required this.dbName,
    required this.userId,
    required this.hasVersionChange,
    required this.currentVersion,
    required this.clean,
    required this.tables,
    required this.lastDbVersionName,
  });

  // Deserialize from JSON (handle non-serializable fields)
  factory DatabaseIsolateParams.fromJson(Map<String, dynamic> json) {
    return DatabaseIsolateParams(
      dbName: json['dbName'],
      userId: json['userId'],
      hasVersionChange: json['hasVersionChange'],
      currentVersion: json['currentVersion'],
      clean: json['clean'],
      tables: List<String>.from(json['tables']),
      lastDbVersionName: json['lastDbVersionName'],
    );
  }

  // Serialize to JSON (handle non-serializable fields)
  Map<String, dynamic> toJson() {
    return {
      'dbName': dbName,
      'userId': userId,
      'hasVersionChange': hasVersionChange,
      'currentVersion': currentVersion,
      'clean': clean,
      'tables': tables,
      'lastDbVersionName': lastDbVersionName,
    };
  }
}
