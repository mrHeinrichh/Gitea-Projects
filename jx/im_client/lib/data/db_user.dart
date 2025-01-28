import 'dart:convert';

import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_thread.dart';


mixin class DBUser implements UserInterface {
  static const String tableName = 'user';

  @override
  void initUserDB(void Function(String? p1) registerTableFunc) {
    registerTableFunc('''
        CREATE TABLE IF NOT EXISTS  user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER,
        uuid TEXT,
        last_online INTEGER,
        profile_pic TEXT,
        profile_pic_gaussian TEXT DEFAULT "",
        nickname TEXT,
        contact TEXT,
        country_code TEXT,
        username TEXT,
        relationship INTEGER,
        bio TEXT,
        user_alias TEXT,
        request_at INTEGER,
        deleted_at INTEGER,
        email TEXT,
        remark TEXT,
        __add_index INTEGER,
        incoming_sound_id INTEGER DEFAULT 0,
        outgoing_sound_id INTEGER DEFAULT 0,
        notification_sound_id INTEGER DEFAULT 0,
        send_message_sound_id INTEGER DEFAULT 0,
        group_notification_sound_id INTEGER DEFAULT 0,
        group_tags TEXT default "[]",
        friend_tags TEXT default "[]",
        public_key TEXT
        );
        ''');
  }

  @override
  Future<Map<String, dynamic>?> loadUser(int id) async {
    List<Map<String, dynamic>> userMapList =
        await DatabaseHelper.query(tableName, where: "id = ?", whereArgs: [id]);
    return userMapList.isNotEmpty ? userMapList.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> loadAllUsers() async {
    return await DatabaseHelper.query(tableName);
  }

  @override
  updateUsers(List<Map<String, dynamic>> users) {
    try {
      for (var user in users) {
        if (user['friend_tags'] is List<int>) {
          user['friend_tags'] = jsonEncode(user['friend_tags']);
        }

        if (user['group_tags'] is List<String>) {
          user['group_tags'] = jsonEncode(user['group_tags']);
        }
      }
      DatabaseHelper.batchReplace("user",users);
    } catch (e) {
      //todo
    }
  }

  @override
  Future<int?> clearUser() async {
    return await DatabaseHelper.delete(tableName);
  }
}
