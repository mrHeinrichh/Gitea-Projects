import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class VideoDetail extends StatefulWidget {
  const VideoDetail({
    super.key,
    required this.url,
    required this.coverSrc,
    this.coverGausPath,
    required this.index,
    required this.message,
    required this.width,
    required this.currentPage,
    required this.height,
    required this.streamMgr,
    this.sourceExtension,
  });

  final dynamic url;

  final String coverSrc;
  final String? coverGausPath;
  final TencentVideoStreamMgr streamMgr;
  final int index;
  final int width;
  final int height;

  final int currentPage;

  final Message message;

  final String? sourceExtension;

  @override
  VideoDetailState createState() => VideoDetailState();
}

class VideoDetailState extends State<VideoDetail> {
  final CancelToken cancelToken = CancelToken();

  Map<double, Map<String, dynamic>> tsMap = {};
  Rxn<TencentVideoStream> stream = Rxn<TencentVideoStream>();
  StreamSubscription? videoStreamSubscription;

  @override
  void initState() {
    super.initState();
    pdebug('##### 视频播放入口启动 ####');

    prepareVideo();
  }

  @override
  void dispose() {
    cancelToken.cancel();

    videoStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> prepareVideo() async {
    TencentVideoStream? stream = widget.streamMgr.getVideoStream(widget.index);
    if (stream != null) {
      this.stream.value = stream;
      _checkPlayFlow();
    } else {
      final String filePath;
      pdebug('##### 准备视频 ####');
      if (widget.url is AssetEntity) {
        MessageVideo messageVideo =
            widget.message.decodeContent(cl: MessageVideo.creator);
        final AssetEntity asset = widget.url as AssetEntity;
        final file = await asset.originFile;

        if (File(messageVideo.filePath).existsSync()) {
          filePath = messageVideo.filePath;
        } else {
          if (file != null) {
            filePath = file.path;
            pdebug('##### 启用 Asset Entity 本地路径 ####');
          } else {
            pdebug('##### 找不到文件，改为 MessageVideo 网址 ####');
            MessageVideo messageVideo =
                widget.message.decodeContent(cl: MessageVideo.creator);
            filePath = messageVideo.url;
          }
        }
      } else if (widget.url is File) {
        pdebug('##### 启用 File 入口 获取本地路径mp4/mov文件 ####');
        final File file = widget.url as File;
        filePath = file.path;
      } else {
        pdebug('##### 没Asset Entity或File，取 url ####');
        filePath = widget.url as String;
      }

      _prepareParams(filePath);
    }
  }

  _checkPlayFlow() {
    if (widget.index != widget.currentPage) return;
    if (stream.value?.controller.config.isPip ?? false) {
      stream.value?.controller.play();
    } else {
      stream.value?.controller.restart();
    }
  }

  _prepareParams(String videoPath) async {
    TencentVideoConfig config = TencentVideoConfig(
      url: videoPath,
      width: widget.width,
      height: widget.height,
      thumbnail: widget.coverSrc,
      thumbnailGausPath: widget.coverGausPath,
      type: ConfigType.saveMp4,
      sourceExtension: widget.sourceExtension,
    );

    videoStreamSubscription =
        widget.streamMgr.onStreamBroadcast.listen(_onStream);
    widget.streamMgr.addController(config, index: widget.index);
  }

  _onStream(TencentVideoStream item) {
    if (item.pageIndex != widget.index) return;
    stream.value ??= item;
    item.pageIndex = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      onDismissed: Navigator.of(context).pop,
      direction: DismissiblePageDismissDirection.down,
      child: Obx(() {
        return stream.value != null
            ? TencentVideoPlayer(
                controller: stream.value!.controller,
                index: widget.index,
              )
            : Container();
      }),
    );
  }
}
