import 'dart:convert';

import 'package:jxim_client/utils/debug_info.dart';

import 'package:jxim_client/data/object_pool.dart';

typedef FilterFunc = bool Function(RowObject obj);

/// 每行的数据对象
class RowObject extends Poolable {
  // can be int or string
  dynamic _id = 0;
  get id => _id;
  bool get localData => (_data['_localData'] == true);
  set localData(bool b) => _data['_localData'] = b;
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;

  RowObject();

  /// 从内存池取出对象需要重置
  @override
  init(Map<String, dynamic> json) {
    // 合并模式: 将老对象不存在的key复制到json中,然后盖上
    json.forEach((key, value) {
      if (value != null) {
        setValue(key, value);
      }
    });
  }

  /// 根据键值获得值
  setValue(String key, dynamic value) {
    if (key == 'id') {
      _id = value;
    }
    _data[key] = value;
  }

  /// 根据key获得键值
  T getValue<T>(String? key, [dynamic def]) {
    if (key == null) {
      return _data as T;
    }
    if (_data[key] is T) {
      return _data[key];
    }
    return def;
  }

  double getDoubleValue<double>(String? key, [dynamic def]) {
    if (key == null) {
      return _data as double;
    }
    if (_data[key] is double) {
      return _data[key];
    }
    if (_data[key] is int) {
      return _data[key].toDouble();
    }
    return def;
  }

  /// 更新数据信息
  updateValue(Map value) {
    value.forEach((k, v) => setValue(k, v));
  }

  removeKey(String key) {
    _data.remove(key);
  }

  /// 是否匹配规则
  bool isMatch(Map<String, dynamic>? wheres, [FilterFunc? f]) {
    if (wheres != null) {
      for (var key in wheres.keys) {
        if (_data[key] != wheres[key]) return false;
      }
    }
    // 如果带了函数指针
    if (f != null) {
      return f(this);
    }
    return true;
  }

  //内容解析数据
  dynamic _contentObj;
  String? _contentObjStr;
  dynamic decodeContent({required dynamic cl, required String v}) {
    bool needUpdate = false;
    if (_contentObj == null) {
      needUpdate = true; // 如果没有也要刷新下
    } else {
      //判断解析过的字符串 跟现在的对比下 是否重新解析
      needUpdate = _contentObjStr != v;
    }

    if (needUpdate) {
      _contentObj = cl();

      Map<String, dynamic> map = {};

      if (_contentObj != null) {
        try {
          map = jsonDecode(v);
        } catch (error) {
          pdebug('解析错误=========');
        }
        _contentObj.applyJson(map);
        _contentObjStr = v;
      }
    }
    return _contentObj;
  }

  @override
  cleanup() {
    _id = 0;
    _data.clear();
  }

  @override
  String toString() {
    return _data.toString();
  }

  Map<String, dynamic> toJson() {
    return _data;
  }

  static RowObject creator() {
    return RowObject();
  }
}
