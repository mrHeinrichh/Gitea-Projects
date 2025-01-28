import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cbb_video_player/cbb_video_player.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/services/playback_state.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/reel/services/video_player_mgr.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReelVideo extends StatefulWidget {
  final String source;
  final String thumbnail;
  final int index;
  final bool isLoop;
  final bool isNetwork;
  final bool isPreview;
  final bool isMute;
  final bool autoPlay;
  final void Function(int second)? onPlaybackCallback;

  const ReelVideo.file({
    super.key,
    required this.source,
    required this.thumbnail,
    required this.index,
    this.isLoop = true,
    this.isMute = false,
    this.autoPlay = true,
    this.onPlaybackCallback,
  })  : isNetwork = false,
        isPreview = false;

  const ReelVideo.network({
    super.key,
    required this.source,
    required this.thumbnail,
    required this.index,
    this.isLoop = true,
    this.isMute = false,
    this.autoPlay = true,
    this.onPlaybackCallback,
  })  : isNetwork = true,
        isPreview = false;

  const ReelVideo.preview({
    super.key,
    required this.source,
    required this.thumbnail,
    required this.index,
    this.isLoop = true,
    this.isMute = false,
    this.autoPlay = true,
    this.onPlaybackCallback,
  })  : isNetwork = true,
        isPreview = true;

  @override
  State<ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<ReelVideo> {
  late final ReelController controller;

  Map<double, Map<String, dynamic>> tsMap = {};

  Video? vDetail;
  RxBool isLoading = true.obs;

  RxInt currentSecond = 0.obs;

  double get playbackPercent => currentSecond.value / vDetail!.totalSecond;
  RxBool isPlaying = true.obs;

  Timer? videoInitTimer;

  double vHeight = 0.0;
  double vWidth = 0.0;

  @override
  void initState() {
    super.initState();

    controller = Get.find<ReelController>();
    objectMgr.sysOprateMgr.showImageOrVideo = true;

    initPlayer();
    controller.on(ReelController.eventPageChange, onPageChange);

    controller.on(ReelController.eventPlayStateChange, onPlayStateChange);
    controller.on(ReelController.eventVolumeStateChange, onVolumeStateChange);
    if (!widget.isNetwork) {
      controller.on(
          ReelController.eventCacheVideoListUpdate, cacheVideoListListener);
    }
  }

  @override
  void dispose() {
    controller.off(ReelController.eventPageChange, onPageChange);
    controller.off(ReelController.eventPlayStateChange, onPlayStateChange);
    controller.off(ReelController.eventVolumeStateChange, onVolumeStateChange);

    if (!widget.isNetwork) {
      controller.off(
          ReelController.eventCacheVideoListUpdate, cacheVideoListListener);
    }

    videoInitTimer?.cancel();
    videoInitTimer = null;
    super.dispose();
  }

  void initPlayer() async {
    if (widget.isNetwork) {
      if (widget.source.contains('.m3u8')) {
        preloadVideoRemote(widget.source);
      }

      return;
    }

    if (controller.cacheVideoList.containsKey(widget.source)) {
      final Map<String, dynamic> video =
          controller.cacheVideoList[widget.source]!;
      if (video['tsMap'] == null) {
        return;
      }

      vDetail = video['video'];
      tsMap = video['tsMap'];

      vDetail!.vlcPlayerController!.addOnInitListener(() {
        videoInitTimer!.cancel();
        videoInitTimer = null;
        if (vDetail!.vlcPlayerController!.value.isInitialized) {
          isLoading.value = false;
          onReadyCallback(null, null, null);
          return;
        }
      });

      if (mounted) setState(() {});
      if (!vDetail!.vlcPlayerController!.value.isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await vDetail!.initialize();
          } catch (e) {
            videoInitTimer =
                Timer.periodic(const Duration(seconds: 1), (timer) {
              if (vDetail!.vlcPlayerController!.value.isInitialized) {
                timer.cancel();
                return;
              }

              vDetail!.initialize();
            });
          }

          vDetail!.on(Video.EVENT_UPDATEPOS, onPlaybackProgressUpdate);
        });
      }
      return;
    }
  }

  // 网络在线初始化
  void preloadVideoRemote(String url) async {
    final localPath = await cacheMediaMgr.downloadMedia(url);
    if (localPath != null) {
      final fileExtLastIndex = url.lastIndexOf('?Expires');
      final tsDirLastIdx = url.substring(0, fileExtLastIndex).lastIndexOf('/');
      final tsDir = url.substring(0, tsDirLastIdx);
      tsMap = await cacheMediaMgr.extractTsUrls(tsDir, localPath);

      List values = tsMap.values.toList();

      List<Future> tsFutures = [];

      for (int i = 0; i < values.length; i++) {
        if (i >= 2) {
          break;
        }
        tsFutures.add(cacheMediaMgr.downloadMedia(
          values[i]['url'],
          timeoutSeconds: 30,
        ));
      }

      if (tsFutures.isNotEmpty) {
        await Future.wait(tsFutures);
      }

      vDetail = Video(
        File(localPath),
        mixWithOthers: false,
        autoInitialize: true,
        autoPlay: widget.autoPlay,
      );

      vDetail!.on(Video.EVENT_UPDATEPOS, onPlaybackProgressUpdate);

      vDetail!.vlcPlayerController!.addOnInitListener(() {
        if (vDetail!.vlcPlayerController!.value.isInitialized) {
          onReadyCallback(null, null, null);
          return;
        }
      });

      if (mounted) setState(() {});
    }
  }

  // 视频初始化成功
  void onReadyCallback(_, __, data) async {
    if (!mounted) return;
    isLoading.value = false;

    if (vDetail!.vlcPlayerController != null) {
      vDetail!.vlcPlayerController?.addListener(onProgressListener);
    } else {
      vDetail!.videoCtr?.addListener(onProgressListener);
    }

    if (!widget.isPreview && widget.index != controller.currentPage) {
      try {
        await vDetail!.stop();
      } catch (e) {
        if (e == Video.DISPOSED_CONTROLLER_CODE) {
          onDisposeReInit();
        }
      }
    }

    if (widget.isMute) {
      await vDetail!.setVolume(0.0);
    }

    isPlaying.value = true;
    setState(() {});
  }

  void onPlayStateChange(_, __, data) async {
    if (data == null || vDetail == null) return;

    if (data.containsKey('state') && data['state'] == PlaybackState.stop) {
      vDetail!.pause();
      return;
    }

    if (data is Map<String, dynamic>) {
      if (widget.source == data['source']) {
        if (data.containsKey('state')) {
          switch (data['state']) {
            case PlaybackState.play:
              await vDetail!.play();
              break;
            case PlaybackState.pause:
              await vDetail!.pause();
              break;
            default:
              await vDetail!.stop();
          }

          if (data.containsKey('mute') && data['mute']) {
            await vDetail!.setVolume(0.0);
          } else {
            await vDetail!.setVolume(1.0);
          }

          return;
        }

        if (data.containsKey('mute') && data['mute']) {
          await vDetail!.setVolume(0.0);
        } else {
          await vDetail!.setVolume(1.0);
        }

        await vDetail!.stop();
      }
    }
  }

  void onVolumeStateChange(_, __, data) async {
    if (data == null || vDetail == null) return;

    if (data is Map<String, dynamic>) {
      if (widget.isNetwork && widget.source == data['source']) {
        if (vDetail!.curVolume == 1.0) {
          await vDetail!.setVolume(0.0);
        } else {
          await vDetail!.setVolume(1.0);
        }
      }
    }
  }

  // 播放回调
  void onProgressListener() {
    if (!widget.isNetwork && controller.source != widget.source) return;
    final currentDuration = vDetail!.currentSecond;
    final List<double> keys = tsMap.keys.toList();

    final key =
        keys.toList().indexWhere((element) => element > currentDuration);

    if (key != -1) {
      if (key + 1 >= keys.length) return;
      final double keyVal = keys[key + 1];
      final ts = tsMap[keyVal];

      if (ts!['file'] == null) {
        cacheMediaMgr
            .downloadMedia(
          ts['url'],
          timeoutSeconds: 30,
        )
            .then((value) {
          ts['file'] = value;
        });
      }

      if (key + 2 >= keys.length) return;
      final double secondVal = keys[key + 2];

      final ts2 = tsMap[secondVal];
      if (ts2!['file'] == null) {
        cacheMediaMgr
            .downloadMedia(
          ts2['url'],
          timeoutSeconds: 30,
        )
            .then((value) {
          ts2['file'] = value;
        });
      }
    }
  }

  void onPlaybackProgressUpdate(_, __, Object? data) async {
    if (!mounted || vDetail == null) return;

    if (vDetail!.vlcPlayerController != null &&
        !(vDetail?.vlcPlayerController?.value.isInitialized ?? false)) return;
    if (vDetail!.videoCtr != null &&
        !(vDetail?.videoCtr?.value.isInitialized ?? false)) return;

    if (!widget.isNetwork && controller.source != widget.source) {
      vDetail!.pause();
    }

    if (vDetail!.vlcPlayerController != null &&
        vDetail!.vlcPlayerController!.value.isEnded) {
      vDetail!.stop();
      vDetail!.play();
      if (vDetail!.curVolume == 0.0) {
        vDetail!.setVolume(0.0);
      }
      return;
    } else if (vDetail!.videoCtr != null &&
        !vDetail!.videoCtr!.value.isLooping) {
      vDetail!.videoCtr!.setLooping(true);
    }

    currentSecond.value = vDetail!.currentSecond;
    widget.onPlaybackCallback?.call(currentSecond.value);

    if (data != null && (data is bool && data)) {
      setState(() {});
    }

    if (vDetail!.vlcPlayerController != null) {
      if (vDetail!.vlcPlayerController!.value.playingState !=
              PlayingState.stopped ||
          vDetail!.vlcPlayerController!.value.playingState !=
              PlayingState.paused ||
          (vDetail!.vlcPlayerController!.value.playingState ==
                  PlayingState.initialized &&
              !widget.autoPlay)) {
        isPlaying.value = vDetail!.vlcPlayerController!.value.isPlaying;
      }
    } else {
      isPlaying.value = vDetail!.videoCtr!.value.isPlaying;
    }

    final bool isEnabled = await WakelockPlus.enabled;
    if (isPlaying.value && !isEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    if (widget.isNetwork) return;

    if (controller.source != widget.source) {
      if (controller.checkVideoCacheExist(widget.index) &&
          controller.cacheVideoList[widget.source]!['video'].vlcPlayerController
              .value.isInitialized) {
        controller.cacheVideoList[widget.source]!['video'].pause();
      }

      return;
    }
  }

  void onPageChange(_, Object type, Object? data) async {
    if (data == widget.index) {
      if (vDetail != null) {
        if (vDetail?.vlcPlayerController?.value.isInitialized ?? false) {
          try {
            await vDetail!.play();
          } catch (e) {
            if (e == Video.DISPOSED_CONTROLLER_CODE) {
              onDisposeReInit();
            }
          }
        } else {
          isLoading.value = true;
          await vDetail!.initialize();
        }
      }

      return;
    }

    if (vDetail != null) {
      try {
        await vDetail!.stop();
      } catch (e) {
        if (e == Video.DISPOSED_CONTROLLER_CODE) {
          onDisposeReInit();
        }
      }
    }
  }

  void cacheVideoListListener(_, __, ___) {
    if (controller.cacheVideoList.containsKey(widget.source) &&
        vDetail == null) {
      initPlayer();
    }
  }

  void onDisposeReInit() {
    vDetail = null;
    vDetail = Video(
      widget.source,
      mixWithOthers: false,
      autoInitialize: false,
    );

    if (controller.cacheVideoList.containsKey(widget.source)) {
      controller.cacheVideoList[widget.source]!['video'] = vDetail;
    } else {
      controller.cacheVideoList[widget.source] = {'video': vDetail};
    }

    controller.event(controller, ReelController.eventCacheVideoListUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          buildVideoView(),
          Positioned.fill(
            child: Visibility(
              visible:
                  isLoading.value || (widget.isNetwork && !isPlaying.value),
              child: RemoteImage(
                src: widget.thumbnail,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
                mini: Config().dynamicMin,
              ),
            ),
          ),
          Offstage(
            offstage: !isLoading.value,
            child: const Center(
              child: CupertinoActivityIndicator(
                color: JXColors.white,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5 - 60,
            left: 0,
            right: 0,
            child: Offstage(
              offstage: isLoading.value ? true : isPlaying.value,
              child: SvgPicture.asset(
                'assets/svgs/reel_play_icon.svg',
                width: 88,
                height: 88,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVideoView() {
    if (vDetail == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
      );
    }

    if (vDetail!.vlcPlayerController != null &&
        vDetail!.vlcPlayerController!.value.aspectRatio > 0.0) {
      return VlcPlayer(
        key: ValueKey<String>('reel_video_${widget.source}'),
        controller: vDetail!.vlcPlayerController!,
        aspectRatio: vDetail!.vlcPlayerController!.value.aspectRatio,
      );
    }

    if (vDetail!.videoCtr != null && vDetail!.videoCtr!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: vDetail!.videoCtr!.value.aspectRatio,
          child: VideoPlayer(
            key: ValueKey<String>('reel_video_${widget.source}'),
            vDetail!.videoCtr!,
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
    );
  }
}
