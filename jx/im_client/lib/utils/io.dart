// 文件操作类
import 'dart:convert';
import 'dart:io';

import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/paths/app_path.dart';

// txt缓存文件读写清
class DYio {
  // 获取缓存目录
  static Future<String> getTempPath() async {
    final appCacheRootPath = AppPath.appCacheRootPath;
    return appCacheRootPath;
  }

  // 设置缓存
  static Future<void> setTempFile(fileName, [str = '']) async {
    String tempPath = await getTempPath();
    await File('$tempPath/$fileName.txt').writeAsString(str);
  }

  // 读取缓存
  static Future<dynamic> getTempFile(fileName) async {
    String tempPath = await getTempPath();
    try {
      String contents = await File('$tempPath/$fileName.txt').readAsString();
      return jsonDecode(contents);
    } catch (e) {
      pdebug(['$fileName:缓存不存在']);
    }
  }

  // 清缓存
  static Future<void> clearCache() async {
    try {
      final appCacheRootPath = AppPath.appCacheRootPath;
      await _delDir(Directory(appCacheRootPath));
    } finally {}
  }

  // 递归方式删除目录
  static Future<void> _delDir(FileSystemEntity file) async {
    try {
      if (file is Directory) {
        final List<FileSystemEntity> children = file.listSync();
        for (final FileSystemEntity child in children) {
          await _delDir(child);
        }
      }
      await file.delete();
    } catch (e) {
      // pdebug(e);
    }
  }

  ///创建文件夹
  static Future<void> mkDir(String dirPath) async {
    var d = Directory(dirPath);
    try {
      bool exists = await d.exists();
      if (!exists) {
        await d.create(recursive: true);
        pdebug(["目录 $dirPath 创建成功"]);
      } else {
        pdebug(["目录 $dirPath 已存在"]);
      }
    } catch (e) {
      pdebug([e]);
    }
  }
}
