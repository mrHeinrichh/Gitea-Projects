import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';
import 'package:super_player/super_player.dart';

class TencentVideoPlayer extends StatefulWidget {
  final int? index;
  final TencentVideoController controller;
  final Widget? overlay;
  final bool hasAspectRatio; //是否占满全屏 是 == 不占满全屏、否 == 占满全屏
  final double? pipAspectRatio;
  final Function()? onTapWidget;
  final bool showPlayButton;

  const TencentVideoPlayer({
    super.key,
    this.index,
    required this.controller,
    this.hasAspectRatio = true,
    this.pipAspectRatio,
    this.overlay,
    this.onTapWidget,
    this.showPlayButton = true,
  });

  @override
  TencentVideoPlayerState createState() => TencentVideoPlayerState();
}

class TencentVideoPlayerState extends State<TencentVideoPlayer> {
  final RxBool _showThumbnail = false.obs;
  StreamSubscription? videoStreamSubscription;
  Rx<TencentVideoState> currentState = TencentVideoState.INIT.obs;

  final RxBool _hasStartedPlaying = false.obs;
  final RxBool _inCall = false.obs;

  @override
  void initState() {
    super.initState();
    if (widget.showPlayButton) {
      TencentVideoStreamMgr mgr = objectMgr.tencentVideoMgr.currentStreamMgr!;
      videoStreamSubscription = mgr.onStreamBroadcast.listen(_onStream);
    } else {
      if (!objectMgr.tencentVideoMgr.checkCallAllowPlay()) {
        _inCall.value = true;
        _showThumbnail.value = true;
      }
      videoStreamSubscription =
          objectMgr.tencentVideoMgr.onStreamBroadcast.listen(_onStream);
    }

    asyncInit();
  }

  asyncInit() async {
    if (widget.controller.config.mediaType ==
        TXVodPlayEvent.MEDIA_TYPE_HLS_VOD) {
      //查询后端是否有m3u8，做为是否展示缩略图的依据
      // /a/b/hash/hls_folder/index.m3u8
      String videoPath = widget.controller.config.url;
      final mp4RelativeFolderIdx =
          videoPath.lastIndexOf(Platform.pathSeparator); //去除 index.m3u8
      final mp4RelativeFolder = videoPath.substring(0, mp4RelativeFolderIdx);
      final hlsHashFolderIndex =
          mp4RelativeFolder.lastIndexOf(Platform.pathSeparator); //去除 hls folder
      final hlsHashFolder = mp4RelativeFolder.substring(0, hlsHashFolderIndex);
      final urlHashFolderIdx =
          hlsHashFolder.lastIndexOf(Platform.pathSeparator); //找寻hash点位
      final urlHash = hlsHashFolder.substring(urlHashFolderIdx + 1); //取hash
      String type = videoPath.contains("Reels") ? "Reels" : "Video";
      bool hasM3u8 =
          await videoMgr.checkM3u8HasFinishedProcessing(urlHash, type: type);

      _showThumbnail.value = !hasM3u8;
    }
  }

  bool _inCheckingForNonPlaying = false;

  _onStream(TencentVideoStream item) {
    if (item.pageIndex != widget.index) return;
    if (item.controller != widget.controller) return;
    // pdebug(
    //     "getting updates - ${item.pageIndex} - obj - ${objectMgr.tencentVideoMgr.currentStreamMgr!.currentIndex.value} - ${DateTime.now()}");
    if (item.pageIndex ==
            objectMgr.tencentVideoMgr.currentStreamMgr!.currentIndex.value &&
        !_inCheckingForNonPlaying &&
        !item.hasEnteredPrepared) {
      //等待两秒，还是不播就显示缩略图
      _inCheckingForNonPlaying = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!item.hasEnteredPrepared) {
          _showThumbnail.value = true;
        }
      });
    }

    if (item.state.value == TencentVideoState.PREPARED &&
        !objectMgr.tencentVideoMgr.checkCallAllowPlay()) {
      _inCall.value = true;
      _showThumbnail.value = true;
    }

    if (!_hasStartedPlaying.value &&
        item.state.value == TencentVideoState.PLAYING) {
      _hasStartedPlaying.value = true;
      _inCall.value = false;
    }

    if (item.state.value != currentState.value) {
      currentState.value = item.state.value;
    }

    if (_showThumbnail.value) {
      //check first frame started playing, if started playing, remove placeholder and loading
      if (widget.controller.currentProgress.value > 0) {
        _showThumbnail.value = false;
      }
    }

    if (item.hasManuallyPaused) {
      currentState.value = TencentVideoState.PAUSED;
    }
  }

  @override
  void dispose() {
    videoStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);

    Widget w = Stack(
      children: [
        Obx(
          () => Offstage(
            offstage: _inCall.value,
            child: TXPlayerVideo(controller: widget.controller.vidController),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.onTapWidget != null) widget.onTapWidget!();
            widget.controller.togglePlayState();
          },
          child: Obx(() {
            return Visibility(
              visible: widget.showPlayButton
                  ? (widget.controller.isSeeking.value
                      ? (widget.controller.previousState !=
                              TencentVideoState.PLAYING &&
                          widget.controller.previousState !=
                              TencentVideoState.LOADING)
                      : _hasStartedPlaying.value //
                          ? (currentState.value != TencentVideoState.PLAYING &&
                              currentState.value != TencentVideoState.LOADING &&
                              currentState.value != TencentVideoState.INIT &&
                              currentState.value != TencentVideoState.PREPARED)
                          : false)
                  : false,
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/reel_play_icon.svg',
                  width: widget.controller.isFullMode.value ? 88 : 36,
                  height: widget.controller.isFullMode.value ? 88 : 36,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Obx(
            () => Offstage(
              offstage: !_showThumbnail.value,
              child: GestureDetector(
                onTap: () {
                  if (widget.onTapWidget != null) widget.onTapWidget!();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    // 增加一个半透明背景，防止透明封面图的出现
                    color: Color(0x11BBBBBB),
                  ),
                  child: GaussianImage(
                    src: widget.controller.config.thumbnail ?? "",
                    gaussianPath: widget.controller.config.thumbnailGausPath,
                    fit: widget.hasAspectRatio ? BoxFit.cover : BoxFit.fill,
                    mini: Config().dynamicMin,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Obx(
            () => Visibility(
              visible: (_showThumbnail.value && !_inCall.value) ||
                  currentState.value == TencentVideoState.LOADING,
              child: Center(
                child: Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: colorTextPrimary.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const CupertinoActivityIndicator(
                    radius: 12.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.overlay != null) widget.overlay!,
      ],
    );

    if (!widget.hasAspectRatio) return w;

    if (widget.pipAspectRatio != null) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.aspectRatio.value,
            child: IntrinsicHeight(
              child: w,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: widget.controller.config.hasTopSafeArea,
      bottom: widget.controller.config.hasBottomSafeArea,
      child: Center(
        child: Obx(() {
          return AspectRatio(
            aspectRatio: widget.controller.aspectRatio.value > 0.0 ? widget.controller.aspectRatio.value : (9 / 16),
            child: IntrinsicHeight(
              child: w,
            ),
          );
        }),
      ),
    );
  }
}
