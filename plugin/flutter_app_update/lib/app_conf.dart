// {
//   "check_update": true,
//   "force_update": false,
//   "audit":false,
//   "version":{
//     "code":6,
// 	   "info":"1.添加名片分享功能\n2.优化部分功能\n3.修复部分已知bug",
//     "android_url":"http://d1kk9e.coding-pages.com/download/madai.apk",
// 	   "android_size":86041537
//   }
// }
import 'dart:math';

class AppConf {
   /// 是否审核中
  bool get audit => _json['audit'] ?? false;
  /// 版本信息
  String get version => _json['version'] ?? '';

  /// 最低版本
  String get minversion => _json['minversion'] ?? '';

  /// 更新日志 
  String get changelog => _json['changelog'] ?? '';

  /// 安卓apk下载地址
  String get url => _json['url'] ?? "";
  /// apk md5
  String get md5 => _json['md5'] ?? "";

  /// 安卓apk大小
  String get size {
    int size = _json['size'] ?? 0;
    String str = "";
    if (size >= pow(2, 40)) {
      str = ((size / pow(2, 40) * 100).floor() / 100).toString() + "TB";
    } else if (size >= pow(2, 30)) {
      str = ((size / pow(2, 30) * 100).floor() / 100).toString() + "GB";
    } else if (size >= pow(2, 20)) {
      str = ((size / pow(2, 20) * 100).floor() / 100).toString() + "MB";
    } else if (size >= pow(2, 10)) {
      str = (size / pow(2, 10)).ceil().toString() + "KB";
    } else {
      str = "1KB";
    }
    return str;
  }

  final Map<String, dynamic> _json;
  AppConf.created(this._json);
}


