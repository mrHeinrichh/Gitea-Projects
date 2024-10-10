
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

class FlutterPasteboard {
  static const MethodChannel _channel = MethodChannel('pasteboard');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Returns the image data of the pasteboard.
  static Future<dynamic> get image async {
    
    if (Platform.isMacOS || Platform.isLinux || Platform.isIOS || Platform.isWindows) {
      return await Pasteboard.image;
    }
    final obj = await _channel.invokeMethod<Object>('image');

    return obj;
  }

  /// set image data to system pasteboard.
  static Future<void> writeImage(dynamic image) async {
    if (image == null) {
      return;
    }
    dynamic obj;
    if(image is File){
      obj = image.readAsBytesSync();
    }
    else {
      obj = image;
    }

    if (Platform.isIOS) {
      await Pasteboard.writeImage(obj);
    }
    else {
      await _channel.invokeMethod<void>('writeImage', obj);
    }
  }

  /// Get files from system pasteboard.
  static Future<List<String>> files() async {
    return await Pasteboard.files();
  }

  /// Set files to system pasteboard.
  static Future<bool> writeFiles(List<String> files) async {
    return await Pasteboard.writeFiles(files);
  }
}
