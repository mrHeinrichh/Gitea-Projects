import 'dart:async';
import 'dart:io';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/webp_first_fram.dart';
import 'package:lottie_tgs/lottie.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// 状态
enum _DataStatus {
  // 待下载
  wait,
  // 下载中
  running,
  // 下载完成
  finished,
  // 下载错误
  error,
}

// 缓存文件
class CacheFile {
  /// 图片缓存 是否需要持久化
  static final Map<String, CacheFile> _caches = {};

  /// 申请一个缓存文件
  static CacheFile malloc(String path) {
    CacheFile? v = _caches[path];
    if (v == null) {
      v = CacheFile.create(path);
      _caches[path] = v;
      pdebug(["CacheFile count: ${_caches.length}"]);
    }
    v.ref++;
    pdebug([
      "===CacheFile add: ${v.path.substring(v.path.indexOf('download/'))} ref: ${v.ref}"
    ]);
    return v;
  }

  /// 释放缓存文件
  static free(CacheFile v) {
    v.ref--;
    pdebug([
      "===CacheFile sub: ${v.path.substring(v.path.indexOf('download/'))} ref: ${v.ref}"
    ]);
  }

  // 校验释放缓存文件
  static _checkDispose(CacheFile v) {
    if (v.ref <= 0) {
      _caches.remove(v.path);
      pdebug(["CacheFile count: ${_caches.length}"]);
      pdebug([
        "===CacheFile remove: ${v.path.substring(v.path.indexOf('download/'))}"
      ]);
    }
  }

  String path;

  // 支持文件也支持字节流
  late File _file;

  File get file => _file;

  // 引用计数
  int _ref = 0;

  int get ref {
    return _ref;
  }

  deleteFile() async {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  set ref(int v) {
    _ref = v;
    if (_ref == 0) {
      Future.delayed(const Duration(seconds: 5), () => _checkDispose(this));
    }
  }

  CacheFile.create(this.path) {
    _file = File(path);
  }
}

// 远程图片Data
class RemoteImageData extends EventDispatcher {
  static int _instances = 0;

  static set instances(int v) {
    _instances = v;
    pdebug(["+++++++++++++++ RemoteImageData instances: $_instances"]);
  }

  static int get instances {
    return _instances;
  }

  // 错误图像
  static String error = 'assets/images/common/picture_loading.jpg';

  // 状态变更
  static String statusChange = "RemoteImageData.statusChange";

  String src = '';

  //缩略图最大大小
  int? mini;
  final double? width;
  final double? height;
  final BoxFit? fit;

  bool shouldAnimate = false;

  /// 本地文件路径
  String? localSrc;

  CacheFile? cacheFile;

  /// 状态
  _DataStatus _status = _DataStatus.wait;

  void _changeStatus(_DataStatus v) {
    if (_status != v) {
      _status = v;
      event(this, statusChange);
    }
  }

  RemoteImageData.create(
    this.src,
    this.width,
    this.height,
    this.fit, {
    String? error,
    this.mini,
    this.shouldAnimate = false,
  }) {
    //暂时解决视频号的cover的path后面有无用参数的问题
    // this.src = Uri.parse(this.src).path;
    instances++;

    if (src.isEmpty) {
      _changeStatus(_DataStatus.error);
    } else {
      String? savePath = cacheMediaMgr.checkLocalFile(src, mini: mini);
      if (savePath != null) {
        localSrc = savePath;
        cacheFile = CacheFile.malloc(localSrc!);
        _changeStatus(_DataStatus.finished);
      } else {
        // 下载图片
        _download();
      }
    }
  }

  void _download() async {
    _changeStatus(_DataStatus.running);
    localSrc = await cacheMediaMgr.downloadMedia(
      src,
      mini: mini,
    );

    if (localSrc != null) {
      cacheFile = CacheFile.malloc(localSrc!);
      _changeStatus(_DataStatus.finished);
      return;
    } else {
      _changeStatus(_DataStatus.error);
      pdebug(["RemoteImageData【下载失败】: ${src}"]);
    }
  }

  retry() async {
    await cacheFile!.deleteFile();
    freeLocalFile();
    _changeStatus(_DataStatus.error);
  }

  void freeLocalFile() {
    if (cacheFile != null) {
      CacheFile.free(cacheFile!);
      cacheFile = null;
    }
  }

  /// 释放
  void dispose() {
    instances--;
    freeLocalFile();
    pdebug(
        ["RemoteImageData.dispose src: ${this.src} , instance = ${instances}"]);
  }
}

/// 远程图片
/// @src 可为资源id(number)或资源路径(string)
class RemoteImage extends EventsWidget {
  ///////////// profile debug /////////////
  static int _instances = 0;

  static set instances(int v) {
    _instances = v;
    pdebug(["+++++++++++++++ RemoteImage instances: $_instances"]);
  }

  static int get instances {
    return _instances;
  }

  RemoteImage({
    Key? key,
    required this.src,
    this.width,
    this.height,
    this.fit,
    this.mini,
    this.errorImage,
    this.onLoadCallback,
    this.onLoadError,
    this.shouldAnimate = false,
  }) : super(key: key ?? ValueKey(src), data: EventDispatcher());
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String? errorImage;
  final int? mini;
  final Function(CacheFile? f)? onLoadCallback;
  final VoidCallback? onLoadError;
  final bool shouldAnimate;

  @override
  _RemoteImageState createState() => _RemoteImageState();
}

class _RemoteImageState extends EventsState {
  RemoteImageData? _imgData;
  int index = 0;

  bool isUserScrolling = false;

  @override
  void didUpdateWidget(covariant SuperEventsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  List<EventsWidgetData>? createData() {
    var _widget = widget as RemoteImage;
    _imgData = RemoteImageData.create(
      _widget.src,
      _widget.width,
      _widget.height,
      _widget.fit,
      mini: _widget.mini,
      error: _widget.errorImage,
      shouldAnimate: _widget.shouldAnimate,
    );
    RemoteImage.instances++;

    objectMgr.chatMgr.on(ChatMgr.eventScrolling, onUserScrolling);

    return [
      EventsWidgetData(_imgData!, [
        RemoteImageData.statusChange,
      ])
    ];
  }

  @override
  void dispose() {
    RemoteImage.instances--;
    objectMgr.chatMgr.off(ChatMgr.eventScrolling, onUserScrolling);
    _imgData?.dispose();
    super.dispose();
  }

  void onUserScrolling(Object sender, Object type, Object? data) {
    if (data is bool && isUserScrolling != data) {
      isUserScrolling = data;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context1) {
    if (!this.mounted) return const SizedBox();

    RemoteImageData imgData = _imgData!;
    Widget child = SizedBox(width: imgData.width, height: imgData.height);

    switch (imgData._status) {
      case _DataStatus.finished:
        if (imgData.cacheFile == null) {
          break;
        }

        if (imgData.localSrc!.endsWith('.tgs')) {
          child = SizedBox(
            width: _imgData?.width ?? 200,
            height: _imgData?.height ?? 200,
            child: Lottie.file(
              imgData.cacheFile!.file,
              width: 100,
              height: 100,
              animate: isUserScrolling ? false : imgData.shouldAnimate,
              frameRate: FrameRate(240),
              errorBuilder: (context, error, stackTrace) {
                return Shimmer(
                  enabled: true,
                  color: Colors.black26,
                  colorOpacity: 0.2,
                  duration: const Duration(seconds: 2),
                  child: SizedBox(
                    width: imgData.width,
                    height: imgData.height,
                  ),
                );
              },
            ),
          );
        } else if (imgData.localSrc!.endsWith('.webp') &&
            imgData.shouldAnimate == false) {
          child = WebpWidget(imgData);
        } else {
          child = Image.file(
            imgData.cacheFile!.file,
            key: ValueKey('${imgData.cacheFile!.file}'),
            width: imgData.width,
            height: imgData.height,
            fit: imgData.fit,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null) {
                (widget as RemoteImage).onLoadCallback?.call(imgData.cacheFile);
                return child;
              }

              return SizedBox(
                width: imgData.width,
                height: imgData.height,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              (widget as RemoteImage).onLoadError?.call();
              imgData.retry();
              return SizedBox(
                width: imgData.width,
                height: imgData.height,
              );
            },
          );
        }

        break;
      case _DataStatus.running:
        if (imgData.cacheFile != null) {
          child = Image.file(
            imgData.cacheFile!.file,
            width: imgData.width,
            height: imgData.height,
            fit: imgData.fit,
          );
        }
        break;
      case _DataStatus.error:
        return Image.asset(
          'assets/images/common/picture_loading_failed.jpg',
          width: imgData.width,
          height: imgData.height,
          fit: imgData.fit,
        );
      default:
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      child: (imgData._status == _DataStatus.finished ||
                  imgData._status == _DataStatus.running) &&
              imgData.cacheFile == null
          ? Shimmer(
              enabled: true,
              color: Colors.black26,
              colorOpacity: 0.2,
              duration: const Duration(seconds: 2),
              child: SizedBox(
                width: imgData.width,
                height: imgData.height,
              ),
            )
          : child,
    );
  }
}
