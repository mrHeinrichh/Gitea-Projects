import 'dart:io';
import 'dart:ui';

import 'package:cbb_video_player/cbb_video_event_dispatcher.dart';
import 'package:cbb_video_player/cbb_video_player_controller.dart';
import 'package:cbb_video_player/utils/config.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class VideoDetail extends StatefulWidget {
  const VideoDetail({
    Key? key,
    required this.url,
    required this.remoteSrc,
    required this.fileHash,
    required this.index,
    required this.message,
    required this.width,
    required this.currentPage,
    required this.height,
  }) : super(key: key);

  /// [asset] 可以有的状态, asset : AssetEntity | String | AlbumDetailBean,
  final dynamic url;

  final String remoteSrc;
  final String fileHash;
  final int index;
  final int width;
  final int height;

  final int currentPage;

  /// [message] 对应的消息
  final Message message;

  @override
  VideoDetailState createState() => VideoDetailState();
}

class VideoDetailState extends State<VideoDetail> {
  final CancelToken cancelToken = CancelToken();

  /// M3U8 文件解析出来的ts文件
  /// @params:
  ///
  /// KEY: 叠加长度
  ///
  /// VALUE:
  /// [duration] ts文件时长
  /// [url] ts文件路径
  /// [file] ts 本地文件路径
  Map<double, Map<String, dynamic>> tsMap = {};
  bool _isControllerPlaying = false;
  bool hasInitialized = false;

  @override
  void initState() {
    super.initState();
    pdebug('##### 视频播放入口启动 ####');

    prepareVideo();
    getCoverData();

    // 监听播放进度
    CBBVideoEvents.instance
        .on(VideoEventType.updateCurrentTime, _onPlayingProgress);
    //监听播放器要求删除ts文件
    CBBVideoEvents.instance.on(VideoEventType.deleteTs, _onDeleteTs);
    //监听播放器报错误
    CBBVideoEvents.instance.on(VideoEventType.onError, _onError);
    CBBVideoEvents.instance
        .on(VideoEventType.controllerChanged, _onControllerChanged);
    objectMgr.on(ObjectMgr.eventAppLifeState, _handleAppLifeCycle);
  }

  @override
  void dispose() {
    cancelToken.cancel();

    // 取消监听播放进度
    CBBVideoEvents.instance
        .off(VideoEventType.updateCurrentTime, _onPlayingProgress);
    //取消监听播放器报错误
    CBBVideoEvents.instance.off(VideoEventType.onError, _onError);
    //取消监听播放器要求删除ts文件
    CBBVideoEvents.instance.off(VideoEventType.deleteTs, _onDeleteTs);
    CBBVideoEvents.instance
        .off(VideoEventType.controllerChanged, _onControllerChanged);

    objectMgr.off(ObjectMgr.eventAppLifeState, _handleAppLifeCycle);

    super.dispose();
  }

  getCoverData() {
    CBBVideoPlayerController? controller =
        CBBVideoEvents.instance.getController(widget.index);
    if (controller != null) {
      FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
// Dimensions in logical pixels (dp)
      Size size = view.physicalSize / view.devicePixelRatio;
      double screenWidth = size.width;

      if (widget.width > 0 && widget.height > 0) {
        int videoWidth = widget.width;
        int videoHeight = widget.height;

        double ratio = screenWidth / videoWidth;
        double actualHeight = ratio * videoHeight;
        controller.coverWidth = screenWidth;
        controller.coverHeight = actualHeight;
      }
    }
  }

  Future<void> prepareVideo() async {
    final String filePath;
    pdebug('##### 准备视频 ####');
    if (widget.url is AssetEntity) {
      final AssetEntity asset = widget.url as AssetEntity;
      final file = await asset.originFile;
      if (file != null) {
        filePath = file.path;
        pdebug('##### 启用 Asset Entity 本地路径 ####');
      } else {
        pdebug('##### 找不到文件，改为 MessageVideo 网址 ####');
        MessageVideo messageVideo =
            widget.message.decodeContent(cl: MessageVideo.creator);
        filePath = messageVideo.url;
      }
    } else if (widget.url is File) {
      pdebug('##### 启用 File 入口 获取本地路径mp4/mov文件 ####');
      final File file = widget.url as File;
      filePath = file.path;
    } else {
      pdebug('##### 没Asset Entity或File，取 url ####');
      filePath = widget.url as String;
    }
    if (filePath.endsWith('.m3u8')) {
      pdebug('##### 路径为m3u8 启动m3u8下载 ####');
      _onInitialDownloadM3u8(filePath);
    } else {
      pdebug('##### 路径为本地视频 直接启动视频 ####');
      CBBVideoEvents.instance.getController(widget.index)!.isInitialized.value =
          true;
      CBBVideoEvents.instance.getController(widget.index)?.initPlayer(filePath);
      if (Config().isDebug) mypdebug("播放本地的 mp4/mov", toast: true);
      pdebug('##### 视频启动 完毕 ####');
    }
  }

  Future<void> _onInitialDownloadM3u8(
    String url, {
    int tryCount = 0,
    CancelToken? cancelToken,
  }) async {
    pdebug('##### 开始下载m3u8 ####');
    // 1. Polling
    String? localM3u8File =
        await videoMgr.previewVideoM3u8(url, cancelToken: cancelToken);

    if (localM3u8File == null ||
        localM3u8File.isEmpty ||
        cacheMediaMgr.checkLocalFile(localM3u8File) == null) {
      // 启动远端视频播放
      _initializeWithURI();
      return;
    }

    // extract m3u8 file
    final String m3u8Content = File(localM3u8File).readAsStringSync();
    if (!m3u8Content.contains('EXT')) {
      pdebug('##### 下载m3u8失败 ####');
      File(localM3u8File).deleteSync();
      if (tryCount < 3) {
        pdebug('##### 启动重试 ####');
        Future.delayed(const Duration(seconds: 5));
        _onInitialDownloadM3u8(
          url,
          tryCount: tryCount + 1,
          cancelToken: cancelToken,
        );
      } else {
        pdebug('##### 重试次数到达，远程逻辑 ####');
        _initializeWithURI();
      }
      return;
    }

    pdebug('##### 下载第一片 ts 中####');
    // 2. Extract content and put in tsMap && Download first ts file
    tsMap = await videoMgr.downloadTsFile(
      url,
      localM3u8File,
      cancelToken: cancelToken,
    );

    if (tsMap.isNotEmpty) {
      pdebug('##### 下载第一片 ts 成功####');
      // 3. Register event
      CBBVideoEvents.instance.getController(widget.index)!.isInitialized.value =
          true;
      CBBVideoEvents.instance
          .getController(widget.index)
          ?.initPlayer(localM3u8File);
      if (Config().isDebug) mypdebug("播放 m3u8", toast: true);
      pdebug('##### 视频启动 完毕 ####');
    } else {
      pdebug('##### 下载第一片 ts 失败####');
      _initializeWithURI();
    }
  }

  _initializeWithURI() async {
    pdebug('##### 先尝试远程下载mp4 ####');
    String combineSrc = widget.remoteSrc;
    String localMp4File = await videoMgr.downloadMp4File(widget.remoteSrc,
        cancelToken: cancelToken);
    if (localMp4File == null ||
        localMp4File.isEmpty ||
        File(localMp4File).existsSync() == false) {
      if (!widget.remoteSrc.startsWith('http') &&
          serversUriMgr.download2Uri != null) {
        combineSrc =
            serversUriMgr.download2Uri.toString() + '/' + widget.remoteSrc;
      }

      pdebug('##### 远程盾 地址获取 ####');
      final Uri? uploadUri = await serversUriMgr.exChangeKiwiUrl(
          combineSrc, serversUriMgr.download2Uri);
      if (uploadUri == null ||
          widget.remoteSrc.isEmpty ||
          !combineSrc.startsWith('http')) {
        mypdebug(localized(videoDownloadFailed), toast: true);
        return null;
      }

      pdebug('##### 远程网址视频启动 ####');
      CBBVideoEvents.instance.getController(widget.index)!.isInitialized.value =
          true;
      CBBVideoEvents.instance
          .getController(widget.index)
          ?.initPlayerOnWebResource(uploadUri);
      if (Config().isDebug)
        mypdebug("播放远端的mp4 （m3u8 下载失败 / 播放器报错）", toast: true);
      pdebug('##### 视频启动 完毕 ####');
    } else {
      pdebug('##### 下载成功，走本地播放，启动视频 ####');
      CBBVideoEvents.instance.getController(widget.index)!.isInitialized.value =
          true;
      CBBVideoEvents.instance
          .getController((widget.index))
          ?.initPlayer(localMp4File);
      if (Config().isDebug)
        mypdebug("播放远端的下载mp4 （m3u8 下载失败 / 播放器报错）", toast: true);
      pdebug('##### 视频启动 完毕 ####');
    }
  }

  Future<void> _onError(Object sender, _, Object? data) async {
    if (sender != CBBVideoEvents.instance.getController(widget.index)) return;
    _initializeWithURI();
  }

  Future<void> _onDeleteTs(Object sender, _, Object? data) async {
    if (sender != CBBVideoEvents.instance.getController(widget.index)) return;
    if (data is String) {
      final List<Map<String, dynamic>> values = tsMap.values.toList();
      final item =
          values.firstWhereOrNull((element) => element['url'].contains(data));
      if (item != null) {
        final String? deleteTSPath = cacheMediaMgr.checkLocalFile(item['url']);
        if (deleteTSPath != null) {
          pdebug("#### 删除可能损坏的TS文件 ####");
          File(deleteTSPath).deleteSync();
        }
      }
    }
  }

  Future<void> _onPlayingProgress(Object sender, _, Object? data) async {
    if (sender != CBBVideoEvents.instance.getController(widget.index)) return;

    bool isPrioritize = false;
    double loadTime = 0;
    bool toDeleteSegments = false;
    if (data is TimeUpdateEvent) {
      isPrioritize = data.priority == DownloadPriority.prioritized;
      loadTime = data.timeInSeconds;
      toDeleteSegments = data.toDeleteCurrentDownloadedSegments;
    }

    final List<double> keys = tsMap.keys.toList();
    final key = keys.toList().indexWhere((element) => element > loadTime);

    // 获取准备下载的ts 数据

    if (key != -1) {
      if (toDeleteSegments) {
        //移除当下时间过后的文件
        for (var i = key; i < keys.length; i++) {
          final double kV = keys[i];
          final mapToDeleteTS = tsMap[kV];
          final String? deleteTSPath =
              cacheMediaMgr.checkLocalFile(mapToDeleteTS!['url']);
          if (deleteTSPath != null) {
            pdebug("#### 删除可能损坏的TS文件 ####");
            File(deleteTSPath).deleteSync();
          }
        }
      }

      final double keyVal = keys[key];
      final ts = tsMap[keyVal];

      final String? tsPath = cacheMediaMgr.checkLocalFile(ts!['url']);

      if (tsPath == null) {
        cacheMediaMgr.downloadMedia(
          ts['url'],
          cancelToken: cancelToken,
          priority: isPrioritize ? 100 : 1,
          timeoutSeconds: 60,
        );
      }

      if (key + 1 < keys.length) {
        final double secondVal = keys[key + 1];
        final ts2 = tsMap[secondVal];

        final String? ts2Path = cacheMediaMgr.checkLocalFile(ts2!['url']);

        if (ts2Path == null) {
          cacheMediaMgr.downloadMedia(
            ts2['url'],
            cancelToken: cancelToken,
            priority: (isPrioritize ? 100 : 1),
            timeoutSeconds: 60,
          );
        }
      }
    }
  }

  _handleAppLifeCycle(sender, type, data) {
    if (data is AppLifecycleState) {
      AppLifecycleState state = data;
      pdebug("#### ${state.toString()} ####");
      CBBVideoPlayerController? controller =
          CBBVideoEvents.instance.getController(widget.index);
      if (controller == null) return;

      switch (state) {
        case AppLifecycleState.resumed:
          if (_isControllerPlaying) controller.play();
          break;
        case AppLifecycleState.paused:
          _isControllerPlaying = controller.isPlaying.value;
          controller.pause();
          break;
        default:
          break;
      }
    }
  }

  _onControllerChanged(Object sender, __, Object? data) {
    if (data is! int) return;
    if (data != widget.index) return;
    prepareVideo();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (hasInitialized)
      return CBBVideoEvents.instance.getController(widget.index)!.getPlayer();

    if (widget.index == widget.currentPage) {
      hasInitialized = true;
      return CBBVideoEvents.instance.getController(widget.index)!.getPlayer();
    }

    return CBBVideoEvents.instance.getController(widget.index)!.videoCover();
  }
}
