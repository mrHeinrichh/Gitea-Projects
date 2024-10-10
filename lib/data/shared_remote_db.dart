import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/row_object.dart';

const addIndexKey = '__add_index';

class SharedTable {
  late String _tableName;

  String get tableName => _tableName;

  late JsonObjectPool _pool;

  JsonObjectPool get pool => _pool;

  SharedTable(String tbl, JsonObjectPool pool) {
    _tableName = tbl;
    _pool = pool;
  }

  final Map<dynamic, RowObject> _rows = {};

  RowObject? _getRow(dynamic id) {
    return _rows[id];
  }

  T? getRow<T extends RowObject>(dynamic id) {
    var row = _rows[id];
    if (row == null) {
      return null;
    }
    return row as T;
  }

  Map<dynamic, RowObject> get data => _rows;

  Future<int?> addRow(RowObject row, bool save) async {
    row.setValue(addIndexKey, _rows.length);
    _rows[row.id] = row;
    if (save) {
      return await _saveRow(row, false);
    }
    return 0;
  }

  Future<int?> modifyRow(Map<String, dynamic> newRow, bool save) async {
    var oldRow = _getRow(newRow["id"]);
    if (oldRow == null) {
      return null;
    }
    oldRow.updateValue(newRow);

    /// 如果是 Message 类型， 不需要init。 前面初始化的时候已经进行了 id 以及 message_id 的更替
    if (oldRow is Message) {
    } else {
      // 变量也更新一下
      oldRow.init(oldRow.data);
    }
    int? count = 0;
    if (save) {
      count = await _saveRow(oldRow, true);
    }
    return count;
  }

  void forEach<T>(void Function(T obj) f) {
    _rows.forEach((_, value) {
      if (value is T) {
        f(value as T);
      }
    });
  }

  T? find<T>(bool Function(T obj) f) {
    T? obj;
    _rows.forEach((key, value) {
      if (obj == null && value is T && f(value as T)) {
        obj = value as T;
      }
    });
    return obj;
  }

  /// 删除记录
  RowObject? delRow(int id, bool save) {
    if (save) {
      objectMgr.localDB.delete(tableName, where: "id = $id");
    }
    return _rows.remove(id);
  }

  /// 保存数据
  Future<int?> _saveRow(RowObject row, bool isUpdate) async {
    int? count = 0;
    Map<String, dynamic> data = row.data;

    if (tableName == DBGroup.tableName ||
        tableName == DBChat.tableName ||
        tableName == DBMessage.tableName) {
      data = jsonDecode(jsonEncode(data));
    }

    // chat表的last_pos不在这里更新
    if (tableName == DBChat.tableName) {
      data.remove("last_pos");
    }

    if (isUpdate) {
      count = await objectMgr.localDB.update(tableName, data);
    } else {
      count = await objectMgr.localDB.replace(tableName, data);
    }
    return count;
  }

  /// 获取列表按插入顺序
  /// @count 数量
  List<T> getList<T extends RowObject>({int? count}) {
    List<T> list = [];
    for (var item in _rows.values) {
      list.add(item as T);
    }
    list.sort(
      (a, b) => a.getValue(addIndexKey).compareTo(b.getValue(addIndexKey)),
    );
    if (count != null) {
      if (list.length > count) {
        list.removeRange(count, list.length);
      }
    }
    return list;
  }

  List<dynamic> toJson() {
    return _rows.values.toList();
  }

  @override
  String toString() {
    return _rows.toString();
  }
}

/// 远程共享数据表
class SharedRemoteDB extends EventDispatcher {
  /// 新的记录来自长链接的对象更新
  static String eventDoVibrate = 'eventDoVibrate';

  /// 所有的数据表格
  static final Map<String, SharedTable> _tables = {};

  /// 根据表名获得表
  SharedTable? getTable(String tableName) {
    return _tables[tableName];
  }

  static setTable(SharedTable table) {
    _tables[table.tableName] = table;
  }

  static bool get isTableEmpty => _tables.isEmpty;

  /// 根据表名获得表,如果不存在则创建,私有,外面不可用.
  static SharedTable _getTable(String tableName, [JsonObjectPool? pool]) {
    var table = _tables[tableName];
    if (table == null) {
      pool ??= JsonObjectPool(RowObject.creator);
      table = SharedTable(tableName, pool);
      _tables[tableName] = table;
    }
    return table;
  }

  final Map<String, JsonObjectPool?> _pools = {};

  /// 注册模型类
  SharedTable registerModel<T extends Poolable>(
    String tableName, [
    JsonObjectPool<T>? pool,
  ]) {
    if (_pools.containsKey(tableName)) {
      pool = _pools[tableName] as JsonObjectPool<T>?;
    } else {
      _pools[tableName] = pool;
    }
    //创建空表
    return _getTable(tableName, pool);
  }

  Future<int?> applyUpdateBlock(
    UpdateBlockBean block, {
    bool save = true,
    bool notify = true,
    bool vibrate = false,
  }) async {
    String blockCtl = block.ctl;
    String blockOpt = block.opt;
    var blockData = block.data;
    var table = _getTable(blockCtl);
    int? count = 0;
    if (blockOpt == blockOptReplace) {
      List allRow = blockData;
      // 根据json生成每行记录插入
      // List<RowObject> newRowData = [];
      for (int i = 0; i < allRow.length; i++) {
        var it = allRow[i];
        final id = it['id'] ?? it['uid'];
        count = await _addRow(table, id, it, save: save, notify: notify);
        if (vibrate && blockCtl == DBMessage.tableName) {
          event(this, eventDoVibrate, data: it['chat_id']);
        }
      }
    } else if (blockOpt == blockOptUpdate) {
      // 更新是单条记录
      count = await _updateRow(table, blockData, save: save, notify: notify);
    } else if (blockOpt == blockOptDelete) {
      //并非所有的数据都回r下来,但是有d一定会下来
      // 删除记录
      if (blockData is int || blockData is String) {
        _delRow(table, blockData, save: save, notify: notify);
      } else if (blockData is List) {
        for (dynamic id in blockData) {
          if (id is int || id is String) {
            _delRow(table, id, save: save, notify: notify);
          }
        }
      }
      count = 1;
    }
    return count;
  }

  Future<int?> _addRow(
    SharedTable table,
    dynamic id,
    dynamic data, {
    bool save = true,
    bool notify = true,
  }) async {
    int? count = 0;
    RowObject? obj = table._getRow(id);
    if (obj == null) {
      obj = table._pool.fetch();
      if (obj != null) {
        obj.init(data);
        count = await table.addRow(obj, save);
        if (count != null && notify) {
          event(this, "$blockOptReplace:${table.tableName}", data: obj);
        }
        return count;
      }
    } else {
      count = await _replaceRow(table, obj, data, save: save, notify: notify);
    }
    return count;
  }

  void _delRow(
    SharedTable table,
    dynamic id, {
    bool save = true,
    bool notify = true,
  }) {
    var obj = table.delRow(id, save);
    // 回收到内存池
    if (obj != null) {
      table._pool.discard(obj);
      if (notify) {
        event(this, "$blockOptDelete:${table.tableName}", data: id);
      }
    }
  }

  Future<int?> _updateRow(
    SharedTable table,
    dynamic data, {
    bool save = true,
    bool notify = true,
  }) async {
    int? count = 0;
    if (data is Map<String, dynamic>) {
      count = await table.modifyRow(data, save);
    } else {
      count = await table.modifyRow(data.toJson(), save);
    }

    if (count != null && notify) {
      event(this, "$blockOptUpdate:${table.tableName}");
    }
    return count;
  }

  Future<int?> _replaceRow(
    SharedTable table,
    RowObject row,
    dynamic data, {
    bool save = true,
    bool notify = true,
  }) async {
    int? count = 0;
    count = await table.modifyRow(data, save);
    if (count != null && notify) {
      event(this, "$blockOptUpdate:${table.tableName}", data: row);
    }
    return count;
  }

  void clearTable(String tableName, {bool save = true, bool notify = true}) {
    var table = _getTable(tableName);
    List<int> ids = [];
    for (var id in table.data.keys) {
      ids.add(id);
    }
    for (var id in ids) {
      _delRow(table, id, save: save, notify: notify);
    }
  }

  /// 根据ID取得单条记录
  RowObject? findObj(String tableName, dynamic id) {
    var tbl = getTable(tableName);
    if (tbl == null) return null;
    return tbl._getRow(id);
  }

  /// 取得符合条件记录
  T? findOne<T>(
    String tableName,
    Map<String, dynamic> wheres, {
    FilterFunc? f,
  }) {
    var tbl = getTable(tableName);
    if (tbl == null) return null;

    for (var item in tbl.data.values) {
      if (item.isMatch(wheres, f)) {
        return item as T;
      }
    }

    return null;
  }

  /// 取得符合条件记录
  List<RowObject>? findAll(
    String tableName,
    Map<String, dynamic> wheres, {
    FilterFunc? f,
  }) {
    List<RowObject> temps = [];
    var tbl = getTable(tableName);
    if (tbl == null) return null;

    for (var item in tbl.data.values) {
      if (item.isMatch(wheres, f)) {
        temps.add(item);
      }
    }
    if (temps.isNotEmpty) {
      return temps;
    }

    return null;
  }

  /// 计算符合条件的数量
  int? count(String tableName, Map<String, dynamic> wheres, [FilterFunc? f]) {
    var tbl = getTable(tableName);
    if (tbl == null) return null;

    int count = 0;
    for (var item in tbl.data.values) {
      if (item.isMatch(wheres, f)) {
        count++;
      }
    }
    return count;
  }

  //清空所有数据
  @override
  clear() {
    pdebug("===============SharedRemoteDB.clear========================");
    _tables.clear();
  }

  Future<void> removeDB(int uid) async {
    var dbName = "data_v014_$uid.db";
    var databasesPath = "";
    if (Platform.isMacOS) {
      final path = await getApplicationSupportDirectory();
      databasesPath = path.path.toString();
    } else {
      databasesPath = await getDatabasesPath();
    }
    var dbPath = join(databasesPath, dbName);
    File dbFile = File(dbPath);

    if (dbFile.existsSync()) {
      deleteDatabase(dbPath);
    }
  }
}
