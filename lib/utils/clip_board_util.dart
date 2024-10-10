import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ClipboardUtil {
  static const platform = MethodChannel('jxim/clipboard');

  // 获取剪贴板中的图片文件路径列表
  static Future<List<List<String>>> getClipboardImages() async {
    try {
      final List<dynamic> filePaths = await platform.invokeMethod('getClipboardImages');
      final List<List<String>> imagePaths = filePaths.map((dynamic innerList) {
        return (innerList as List<dynamic>).map((dynamic item) => item as String).toList();
      }).toList();
      return imagePaths;
    } catch (e) {
      debugPrint("Failed to get clipboard images: $e");
      return [];
    }
  }
}