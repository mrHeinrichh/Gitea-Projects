import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:path/path.dart' as path;

class RemoteImageData {
  final String src;
  int? mini;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool? shouldAnimate;
  late Future<File?> localFile;
  late final String file_extension;
  late final String? _localSrc;
  late final File? init_local_file;

  RemoteImageData(
      {required this.src,
      required this.width,
      required this.height,
      required this.fit,
      this.mini,
      this.shouldAnimate = false}) {
    file_extension = path.extension(src).toLowerCase();
    _localSrc = downloadMgr.checkLocalFile(src, mini: mini);
    if (_localSrc != null && File(_localSrc!).existsSync()) {
      init_local_file = File(_localSrc!);
    } else {
      init_local_file = null;
    }
    localFile = getFile(src);
  }

  Future<File?> getFile(String url) async {
    if (url.isEmpty) {
      return null;
    } else {
      // 检查本地文件存不存在
      final localSrc = downloadMgr.checkLocalFile(url, mini: mini);
      if (localSrc == null) {
        return _download(url);
      }
      final file = File(localSrc);
      return file.existsSync() ? file : null;
    }
  }

  Future<File?> _download(String url) async {
    final localSrc = await cacheMediaMgr.downloadMedia(
      url,
      mini: mini,
    );

    if (localSrc == null) {
      if (_retryCount <= 0) return null;
      await Future.delayed(const Duration(milliseconds: 500));
      _retryCount--;
      return _download(url);
    }
    final file = File(localSrc);
    return file.existsSync() ? file : null;
  }

  int _maxRey = 3;

  bool _retryLock = false;

  retry() {
    if (_retryLock) return;
    if (_maxRey <= 0) return;
    _maxRey--;
    _retryCount = 3;
    _retryLock = true;
    localFile = getFile(src);
    _retryLock = false;
  }

  reflush(String url, int? new_mini) {
    if (new_mini != null) {
      mini = new_mini;
    }
    localFile = getFile(url);
  }

  int _retryCount = 3;
}
