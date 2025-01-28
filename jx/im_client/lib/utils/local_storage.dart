import 'dart:convert';

import 'package:jxim_client/utils/debug_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  // 构建sp类
  late final SharedPreferences _sp;
  bool _isInited = false;

  LocalStorage.create([SharedPreferences? value]) {
    if (value != null) {
      _sp = value;
      pdebug("=============LocalStorage.create======");
    }
  }

  // 初始化
  Future<void> init() async {
    if (!_isInited) {
      _sp = await SharedPreferences.getInstance();
      _isInited = true;
    }
  }

  // 写入本地存储
  Future<bool> write<T>(String key, T value) async {
    if (_sp == null) {
      return false;
    }

    pdebug('===========本地存储write========$key======$value');

    if (value is int) {
      return await _sp.setInt(key, value);
    } else if (value is double) {
      return await _sp.setDouble(key, value);
    } else if (value is String) {
      return await _sp.setString(key, value);
    } else if (value is List<String>) {
      return await _sp.setStringList(key, value);
    } else if (value is List<dynamic>) {
      List<String> dataList = value.map((value) {
        return jsonEncode(value);
      }).toList();
      return await _sp.setStringList(key, dataList);
    } else if (value is bool) {
      return await _sp.setBool(key, value);
    } else if (value is Object) {
      return await _sp.setString(key, jsonEncode(value));
    }
    if (value == null) {
      return await _sp.remove(key);
    }
    return false;
  }

  // 读取本地存储
  T? read<T>(String key) {
    if (_sp == null) {
      return null;
    }
    var type = T.toString();
    if (type == "List<String>") {
      var value = _sp.get(key);
      if (value == null) return null;
      List<Object?> values = value as List<Object?>;
      List<String> list = [];
      for (int i = 0; i < values.length; i++) {
        list.add(values[i] as String);
      }
      return list as T;
    } else if (type == "List<dynamic>") {
      List<String> dataLis = _sp.getStringList(key) ?? [];
      return dataLis.map((value) {
        Map dataMap = json.decode(value);
        return dataMap;
      }).toList() as T;
    } else if (type == "Map<String, dynamic>" ||
        type == "Map<dynamic, dynamic>") {
      var value = _sp.get(key);
      if (value is String) {
        return jsonDecode(value);
      }
      return null;
    } else {
      var value = _sp.get(key);
      if (value != null) {
        return value as T;
      }
      return null;
    }
  }

  bool containsKey(String key) {
    if (_sp == null) {
      return false;
    }
    return _sp.containsKey(key);
  }

  Set<String>? getKeys() {
    if (_sp == null) {
      return null;
    }
    return _sp.getKeys();
  }

  Future<bool> remove(String key) async {
    if (_sp == null) {
      return false;
    }
    return await _sp.remove(key);
  }

  Future<bool> cleanAll() async {
    if (_sp == null) {
      return false;
    }
    pdebug('===========本地存储 清除所有==============');
    return await _sp.clear();
  }

  Future<void> reload() async {
    if (_sp == null) {
      return;
    }
    return await _sp.reload();
  }
}
