import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:path/path.dart' as path;

class RemoteImageData {
  final String src;
  int? mini;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool shouldAnimate;
  late Future<File?> localFile;
  late final String file_extension;
  late final String? _localSrc;
  late final File? init_local_file;
  String? gaussianPath;
  bool _isGaus = false;

  bool get isGaus => _isGaus;
  int _retryCount = 3;

  RemoteImageData(
      {required this.src,
      required this.width,
      required this.height,
      required this.fit,
      this.gaussianPath,
      this.mini,
      this.shouldAnimate = false}) {
    _isGaus = notBlank(gaussianPath);
    file_extension = path.extension(src).toLowerCase();
    if (_isGaus) {
      _localSrc = imageMgr.getBlurHashSavePath(src);
    } else {
      _localSrc = downloadMgrV2.getLocalPath(src, mini: mini);
    }

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
      String? localSrc;
      // 检查本地文件存不存在
      if (_isGaus) {
        localSrc = imageMgr.getBlurHashSavePath(url);
      } else {
        localSrc = downloadMgrV2.getLocalPath(url, mini: mini);
      }

      if ((localSrc == null || !File(localSrc).existsSync()) &&
          !(url.contains('_gaus') && mini == null)) {
        return _download(url);
      }

      if (localSrc == null) return null;

      final file = File(localSrc);

      return file.existsSync() ? file : null;
    }
  }

  Future<File?> _download(String url) async {
    String? localSrc;

    if (_isGaus) {
      localSrc = await imageMgr.genBlurHashImage(
        gaussianPath!,
        url,
      );
    } else {
      DownloadResult result = await downloadMgrV2.download(
        url,
        mini: mini,
      );
      localSrc = result.localPath;
      // localSrc = await downloadMgr.downloadFile(
      //   url,
      //   mini: mini,
      // );
    }

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
}
