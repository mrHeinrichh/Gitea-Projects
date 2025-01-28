import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:jxim_client/data/db_base.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/platform_utils.dart';

class DatabaseThread {
  static bool _isInit = false;
  static SendPort? sharedSendPort; // 全局共享的 SendPort
  static Isolate? _databaseIsolate; // 数据库线程

  static ReceivePort? _dbReceivePort;

  /// 初始化数据库线程
  static Future<void> initDBThread(int userId, List<String> tablesSql) async {
    if (_isInit) return; // 避免重复初始化
    _isInit = true;

    if (_databaseIsolate != null) {
      _dbReceivePort?.close();
      _dbReceivePort = null;
      _databaseIsolate?.kill(priority: Isolate.immediate);
      _databaseIsolate = null;
    }

    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    _dbReceivePort = ReceivePort();

    //todo 建表，补充表字段
    var isolateParams = await _prepareIsolateParams(userId, tablesSql);

    // 启动数据库线程
    _databaseIsolate = await Isolate.spawn(databaseIsolate,
        [rootIsolateToken, _dbReceivePort!.sendPort, isolateParams]);

    // 获取数据库线程的 SendPort
    sharedSendPort = await _dbReceivePort!.first as SendPort;

    //版本有变动，进行写内存
    if (isolateParams.hasVersionChange) {
      objectMgr.localStorageMgr
          .write(isolateParams.lastDbVersionName, isolateParams.currentVersion);
    }
  }

  /// 关闭数据库线程
  static Future<void> closeDBThread() async {
    if (sharedSendPort == null || _databaseIsolate == null) {
      return;
    }
    final receivePort = ReceivePort();
    // 向数据库线程发送关闭信号
    sharedSendPort!.send(_DatabaseRequest(
      operation: (db) async {
        // 在数据库线程中执行关闭操作
        db.closeDatabase();
        return 0;
      },
      replyPort: receivePort.sendPort,
      isWriteOperation: true,
    ));

    sharedSendPort = null;
    // 等待确认关闭
    await receivePort.first;
    receivePort.close();

    // 终止线程
    await Future.delayed(const Duration(milliseconds: 1000));
    _dbReceivePort?.close();
    _dbReceivePort = null;
    _databaseIsolate!.kill(priority: Isolate.immediate);
    _databaseIsolate = null;
    _isInit = false;
  }

  static Future<DatabaseIsolateParams> _prepareIsolateParams(
      int userId, List<String> tablesSql) async {
    //若还未初始化完成，最少先准备用户内存数据。
    await objectMgr.localStorageMgr
        .initUser(objectMgr.loginMgr.account!.user!.id);

    String lastDbVersionName = "${LocalStorageMgr.LAST_DB_VERSION}$userId";
    var currentVersion = "0.0.0";
    var latestVersion = "";
    try {
      currentVersion = await PlatformUtils.getAppVersion();
      latestVersion =
          (objectMgr.localStorageMgr.read(lastDbVersionName) != null)
              ? objectMgr.localStorageMgr.read(lastDbVersionName)
              : "0.0.0";
    } catch (e) {
      latestVersion = currentVersion;
    }

    var dbName = "data_v014_" + userId.toString() + '.db';

    return DatabaseIsolateParams(
      dbName: dbName,
      userId: userId,
      hasVersionChange: currentVersion != latestVersion,
      currentVersion: currentVersion,
      clean: Config().cleanSqflite,
      tables: tablesSql,
      lastDbVersionName: lastDbVersionName,
    );
  }

  /// 数据库线程逻辑
  static void databaseIsolate(List<dynamic> args) async {
    RootIsolateToken token = args[0];
    SendPort sendPort = args[1];
    DatabaseIsolateParams isolateParams = args[2];
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final db = MDataBase();
    await db.initWith(params: isolateParams);

    final dbReceivePort = ReceivePort();

    // 将数据库线程的 SendPort 发送给主线程
    sendPort.send(dbReceivePort.sendPort);

    dbReceivePort.listen((message) async {
      if (message is _DatabaseRequest) {
        if (message.isWriteOperation) {
          // 写操作需要写锁
          try {
            final result = await message.operation(db);
            message.replyPort.send(_DatabaseResponse(result: result));
          } catch (e) {
            message.replyPort.send(_DatabaseResponse(error: e.toString()));
          }
        } else {
          // 读操作需要读锁
          try {
            // 通过 Future 使得不同的读操作可以并行执行
            Future(() async {
              final result = await message.operation(db);
              message.replyPort.send(_DatabaseResponse(result: result));
            });
          } catch (e) {
            message.replyPort.send(_DatabaseResponse(error: e.toString()));
          }
        }
      }
    });
  }
}

class _DatabaseRequest {
  final bool isWriteOperation; // 是否为写操作
  final Future<dynamic> Function(MDataBase session) operation;
  final SendPort replyPort;

  _DatabaseRequest({
    required this.operation,
    required this.replyPort,
    this.isWriteOperation = false, // 默认为读操作
  });
}

class _DatabaseResponse {
  final dynamic result;
  final String? error;

  _DatabaseResponse({this.result, this.error});
}

class DatabaseClient {
  /// 执行数据库任务
  static Future<T> execute<T>(
    Future<T> Function(MDataBase db) operation, {
    bool isWriteOperation = false,
  }) async {
    while (DatabaseThread.sharedSendPort == null) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    final receivePort = ReceivePort();

    // 构造任务请求
    DatabaseThread.sharedSendPort?.send(_DatabaseRequest(
      operation: operation,
      replyPort: receivePort.sendPort,
      isWriteOperation: isWriteOperation,
    ));
    if (DatabaseThread.sharedSendPort != null) {
      // 等待结果
      final response = await receivePort.first as _DatabaseResponse;
      receivePort.close();

      if (response.error != null) {
        throw Exception(response.error);
      }
      return response.result as T;
    } else {
      throw Exception("Database thread closed");
    }
  }
}

class DatabaseHelper {
  static Future<List<Map<String, dynamic>>> query(
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
    return await DatabaseClient.execute<List<Map<String, dynamic>>>(
      (session) async => await session.query(
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
      ),
    );
  }

  static Future<int?> insert(String tableName, Map<String, Object?> values) {
    return DatabaseClient.execute<int?>(
        (session) async => await session.replace(tableName, values),
        isWriteOperation: true);
  }

  static Future<int?> update(String table, Map<String, Object?> values) async {
    return await DatabaseClient.execute<int?>(
        (session) async => await session.update(table, values),
        isWriteOperation: true);
  }

  static Future<int?> delete(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return DatabaseClient.execute<int?>(
        (session) async =>
            await session.delete(tableName, where: where, whereArgs: whereArgs),
        isWriteOperation: true);
  }

  static Future<int?> replace(String table, Map<String, Object?> values) {
    return DatabaseClient.execute<int?>(
        (session) async => await session.replace(table, values),
        isWriteOperation: true);
  }

  static Future<List<Object?>> batchReplace(
      String table, List<Map<String, Object?>> values) async {
    return DatabaseClient.execute<List<Object?>>(
        (session) async => await session.batchReplace(table, values),
        isWriteOperation: true);
  }

  static Future<int> rawUpdate(String sql, [List<Object?>? arguments]) {
    return DatabaseClient.execute<int>(
        (session) async =>
            await session.getDatabase()!.rawUpdate(sql, arguments),
        isWriteOperation: true);
  }

  static Future<void> execute(String sql) {
    return DatabaseClient.execute<void>(
        (session) async => await session.getDatabase()!.execute(sql),
        isWriteOperation: true);
  }

  static Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    return DatabaseClient.execute<int>(
        (session) async =>
            await session.getDatabase()!.rawInsert(sql, arguments),
        isWriteOperation: true);
  }

  static Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return await DatabaseClient.execute<List<Map<String, dynamic>>>(
      (session) async => await session.getDatabase()!.rawQuery(sql, arguments),
    );
  }
}
