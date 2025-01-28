import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/db_call_log.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_chat_category.dart';
import 'package:jxim_client/data/db_favourite.dart';
import 'package:jxim_client/data/db_favourite_detail.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/data/db_mini_app.dart';
import 'package:jxim_client/data/db_red_packet.dart';
import 'package:jxim_client/data/db_retry.dart';
import 'package:jxim_client/data/db_sound.dart';
import 'package:jxim_client/data/db_tags.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class DBManager extends EventDispatcher
    with
        DBChat,
        DBMessage,
        DBUser,
        DBGroup,
        DBRedPacket,
        DBCallLog,
        DBSound,
        DBTags,
        DBFavourite,
        DBFavouriteDetail,
        DBRetry,
        DBChatCategory,
        DBExploreMiniApp,
        DBRecentMiniApp,
        DBFavoriteMiniApp,
        DBDiscoverMiniApp
    implements DBInterface {
  final List<String> tablesSql = [];

  @override
  void registerTable(String? sql) {
    if (sql == null || sql.isEmpty) {
      return;
    }
    tablesSql.add(sql);
  }

  @override
  Future<void> init(int userID, bool clean) async {
    tablesSql.clear();
    initCallLogDB(registerTable);
    initUserDB(registerTable);
    initChatDB(registerTable);
    initMessageDB(registerTable);
    initGroupDB(registerTable);
    initRedPacketDB(registerTable);
    initSoundDB(registerTable);
    initFavouriteDB(registerTable);
    initFavouriteDetailDB(registerTable);
    initRetryDB(registerTable);
    initTagsDB(registerTable);
    initChatCategoryDB(registerTable);
    initExploreMiniAppDB(registerTable);
    initRecentMiniAppDB(registerTable);
    initFavoriteMiniAppDB(registerTable);
    initDiscoverMiniAppDB(registerTable);
    await DatabaseThread.initDBThread(userID, tablesSql);
  }

  @override
  Future<int?> replace(String table, Map<String, Object?> values) async {
    return await DatabaseHelper.replace(table, values);
  }

  @override
  Future<int?> update(String table, Map<String, Object?> values) async {
    return await DatabaseHelper.update(table, values);
  }

  /// 插入数据
  @override
  Future<int?> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final int? result =
        await DatabaseHelper.delete(table, where: where, whereArgs: whereArgs);
    return result;
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
    return await DatabaseHelper.query(
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

  @override
  Future<void> reset() async {}

  // 释放
  @override
  Future<void> destroy() async {
    await objectMgr.messageManager.dbSendPortClose();
    await DatabaseThread.closeDBThread();
  }

  @override
  Future<int> exist(String table, int id) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
        "select count(*) as count from $table where id == $id");
    int? count = result.first.values.firstOrNull;
    return count ?? 0;
  }
}
