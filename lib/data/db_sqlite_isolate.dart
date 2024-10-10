import 'dart:io';

import 'package:jxim_client/utils/debug_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jxim_client/data/db_mgr.dart';


class IsolateDB {
  static Database? _db;

  // 初始化
  Future<void> init(int userID) async {
    var dbName = "data_v014_" + userID.toString() + '.db';
    if (Platform.isWindows) {
      // 获取数据库文件的存储路径
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      var databasesPath = await databaseFactory.getDatabasesPath();
      var dbPath = join(databasesPath, dbName);

      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await databaseFactory.openDatabase(dbPath);
    } else {
      // 获取数据库文件的存储路径
      var databasesPath = "";
      if(Platform.isMacOS){
        final path = await getApplicationSupportDirectory();
        databasesPath = path.path.toString();
      }else{
        databasesPath = await getDatabasesPath();
      }
      var dbPath = join(databasesPath, dbName);

      pdebug("getDatabasesPath:$dbPath");

      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await openDatabase(
        dbPath, version: 1,
      );
    }
  }

  static Future<int?> batchInsert(int userID, String table, List<Map<String, Object?>> addValueList, List<Map<String, Object?>> updateValueList) async {
    int count = 0;
    var dbName = "data_v014_" + userID.toString() + '.db';
    if (Platform.isWindows) {
      // 获取数据库文件的存储路径
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      var databasesPath = await databaseFactory.getDatabasesPath();
      var dbPath = join(databasesPath, dbName);

      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await databaseFactory.openDatabase(dbPath);
    } else {
      // 获取数据库文件的存储路径
      var databasesPath = "";
      if(Platform.isMacOS){
        final path = await getApplicationSupportDirectory();
        databasesPath = path.path.toString();
      }else{
        databasesPath = await getDatabasesPath();
      }
      var dbPath = join(databasesPath, dbName);

      // 根据数据库文件路径和数据库版本号创建数据库表
      _db = await openDatabase(
        dbPath, version: 1,
      );
    }

    if ((addValueList.isEmpty && updateValueList.isEmpty) || _db == null || !_db!.isOpen) {
      return count;
    }

    Batch batch = _db!.batch();
    for(final values in addValueList){
      if(await MDataBase.checkTableColumns(table, values) == false){
        return 0;
      }
      var id = values['id'];
      if (id != null) {
        batch.insert(table, values);
      }
    }

    for(final values in updateValueList){
      if(await MDataBase.checkTableColumns(table, values) == false){
        return 0;
      }
      var id = values['id'];
      if(id != null){
        batch.update(table, values, where: "id = ?", whereArgs: [id]);
      }
    }

    final results = await batch.commit();
    count = results.length;

    return count;
  }

  // 释放
  Future<void> destroy() async {
    await _db?.close();
    _db = null;
  }

}
