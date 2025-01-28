import 'package:jxim_client/data/db_favourite.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';

mixin class DBFavouriteDetail implements FavouriteDetailInterface {
  static const String tableName = 'favourite_detail';


  @override
  void initFavouriteDetailDB(
    void Function(String? p1) registerTableFunc,
  ) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        related_id TEXT DEFAULT "",
        content TEXT DEFAULT "",
        typ INTEGER,
        messageId INTEGER,
        sendId INTEGER,
        chatId INTEGER,
        sendTime INTEGER
        );
        ''');
  }

  @override
  Future<int?> getLatestFavouriteDetailId() async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      "SELECT MAX(id) as maxId FROM $tableName",
    );

    if (result.isNotEmpty && result.first['maxId'] != null) {
      return result.first['maxId'] as int;
    } else {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadFavouriteDetailList() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  Future<int?> getSingleFavouriteDetail(int relatedId, String url) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      "SELECT id FROM $tableName WHERE related_id = ? AND content LIKE ?",
      [relatedId, '%$url%'],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getFavouriteDetailList(
      {int? typ, String? content}) async {
    // if (typ == null && content == null) return null;

    String sql = '''
      SELECT favourite.id,
      favourite.parent_id,
      favourite_detail.content as data,
      favourite.created_at,
      favourite.updated_at,
      favourite.deleted_at,
      favourite.source,
      favourite.author_id,
      favourite_detail.typ as typ,
      favourite.tag,
      favourite.is_pin,
      favourite.is_uploaded,
      favourite.urls,
      favourite.chat_typ,
      favourite_detail.sendTime,
      favourite_detail.sendId,
      favourite_detail.chatId,
      favourite_detail.messageId
      FROM ${DBFavourite.tableName} as favourite
      JOIN $tableName as favourite_detail ON favourite.parent_id = favourite_detail.related_id WHERE favourite.deleted_at = 0
    ''';

    List<dynamic> arguments = [];

    if (typ != null) {
      /// special case for note
      if (typ == FavouriteSourceNote) {
        sql += ' AND favourite.source = ?';
        arguments.add(typ);
      } else if (typ == FavouriteTypeText) {
        /// special case for text and media
        sql += ' AND (favourite_detail.typ = ? OR favourite_detail.typ = ?)';
        arguments.add(FavouriteTypeText);
        arguments.add(FavouriteTypeLink);
      } else if (typ == FavouriteTypeImage) {
        sql += ' AND (favourite_detail.typ = ? OR favourite_detail.typ = ?)';
        arguments.add(FavouriteTypeImage);
        arguments.add(FavouriteTypeVideo);
      } else {
        sql += ' AND favourite_detail.typ = ?';
        arguments.add(typ);
      }
    }

    if (content != null) {
      sql += ' AND favourite_detail.content LIKE ?';
      arguments.add('%$content%');
    }

    sql += ' ORDER BY updated_at DESC';

    List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(
      sql,
      arguments,
    );

    if (result.isNotEmpty) {
      return result;
    } else {
      return null;
    }
  }

  @override
  Future<int?> deleteFavouriteDetailsByParentId(String parentId) async {
    return await DatabaseHelper.delete(
      tableName,
      where: 'related_id = ?',
      whereArgs: [parentId],
    );
  }

  @override
  Future<int?> deleteFavouriteDetailsById(List<int> ids) async {
    String idsString = ids.map((id) => '?').join(', ');

    return await DatabaseHelper.delete(
      tableName,
      where: 'id IN ($idsString)',
      whereArgs: ids,
    );
  }

  @override
  Future<int?> deleteOldFavouriteDetails(String parentId, List<int> ids) async {
    String idsString =
        ids.isNotEmpty ? ids.map((id) => '?').join(', ') : 'NULL';

    return await DatabaseHelper.delete(
      tableName,
      where: 'related_id = ? AND id NOT IN ($idsString)',
      whereArgs: [parentId, ...ids],
    );
  }

  @override
  Future<int?> insertFavouriteDetailAndGetId(Map<String, dynamic> data) async {
    return await DatabaseHelper.insert(tableName, data);
  }
}
