import 'dart:async';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path/path.dart' as tc_path;
import 'package:super_player/super_player.dart';

enum TencentVideoState {
  INIT, // Initial state
  PREPARED, // Prepared
  PLAYING, // Playing
  PAUSED, // Paused
  LOADING, // Buffering
  END, // Playback finished
  DISPOSED,
  ERROR,
  RESTARTING,
  SEEK_TO_END,
  MUTE_LOADING
}

class TencentVideoController extends EventDispatcher {
  // final Offset position;
  // final Widget animation;

  // AnimationPosition({required this.position, required this.animation});
  TencentVideoConfig config;
  TXVodPlayerController vidController = TXVodPlayerController();

  RxDouble aspectRatio = (9 / 16).obs;
  RxBool showSlider = true.obs;

  // Rx<TXPlayerState> playerState = TXPlayerState.buffering.obs;
  Rx<TencentVideoState> playerState = TencentVideoState.INIT.obs;
  TencentVideoState previousState = TencentVideoState.INIT;
  RxBool isFullMode = false.obs;
  RxString absoluteUrl = "".obs;

  RxInt currentProgress = 0.obs;
  RxInt bufferProgress = 0.obs;
  RxInt videoDuration = 0.obs;
  RxBool muted = false.obs;
  RxBool isSeeking = false.obs;
  RxBool isLocal = false.obs;
  int tickDuration = 2000;
  int currentTick = 0;

  int bufferTick = 0;
  int lastBufferProgress = 0;
  bool isBufferDownloading = false;

  bool isControllerPlaying = false;

  StreamSubscription? _netSubscription;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _stateSubscription;

  Function(int, TencentVideoController) notifyParentOnPlayerEvent;
  Function(TencentVideoState, TencentVideoController, {bool? setManuallyPaused})
      notifyParentOnPlayerState;

  TencentVideoController({
    required this.config,
    required this.notifyParentOnPlayerEvent,
    required this.notifyParentOnPlayerState,
  }) {
    asyncInit();
    prepareListeners();
  }

  asyncInit() async {
    // 初始化播放器，分配共享纹理
    aspectRatio.value = 1.0 * config.width / config.height;
    await vidController.initialize();
    var url = await getVideoUrl();
    absoluteUrl.value = url ?? "";

    // pdebug("ededed - 初始化视频 - ${absoluteUrl.value}");

    if (config.initialStartTimeInSeconds != null) {
      await vidController
          .setStartTime(config.initialStartTimeInSeconds!); // 设置开始播放时间
    }

    if (config.isLoop) {
      await vidController.setLoop(config.isLoop); //是否循环播放
    }

    if (config.enableBitrateAutoAdjust) {
      await vidController.setBitrateIndex(-1);
    }

    await vidController.setAutoPlay(isAutoPlay: config.autoplay);

    await vidController.enableHardwareDecode(config.enableHardwareDecode);

    await vidController.setConfig(config);

    // 开始启动播放器
    vidController.startVodPlay(absoluteUrl.value);
  }

  bool get isM3u8 => config.url.contains(".m3u8");

  void switchToMp4(String mp4Path) async {
    config.mediaType = TXVodPlayEvent.MEDIA_TYPE_FILE_VOD; // 用于提升MP4启播速度
    Uri? u = await downloadMgr.getDownloadUri(mp4Path);
    if (u == null) return;

    config.oldM3u8Path = config.url;
    config.url = mp4Path;
    absoluteUrl.value = u.toString();
    await vidController.setConfig(config);
    vidController.startVodPlay(absoluteUrl.value);
  }

  String? checkLocalMp4File() {
    var configURL = config.url;
    if (!isM3u8) {
      if (config.oldM3u8Path == null) {
        return null;
      }
      configURL = config.oldM3u8Path!;
    }

    String extension = tc_path.extension(configURL);
    String mp4Path = configURL.replaceAll(extension, '.mp4');
    String? localUrl = downloadMgrV2.getLocalPath(mp4Path);
    return localUrl;
  }

  Future<String?> getVideoUrl({bool shouldRedirect = false}) async {
    // return "${downloadMgr.appDocumentRootPath}/Video/1e4964f50e06d92c3a8512312d4a01e3.hls";
    if (!isM3u8) {
      // 本地播放
      isLocal.value = true;
      return config.url;
    }

    // if (!config.isPip) {
    String? localUrl = checkLocalMp4File();
    if (localUrl != null) {
      isLocal.value = true;
      config.mediaType = TXVodPlayEvent.MEDIA_TYPE_FILE_VOD; // 用于提升MP4启播速度
      return localUrl;
    }

    //盾播
    Uri? u = await downloadMgr.getDownloadUri(config.url);

    if (u != null) {
      //触发走盾，先消除所有正在预下载中的相应视频
      objectMgr.tencentVideoMgr.removePreloadTask(u.toString());
    }

    return u?.toString() ?? "";
  }

  prepareListeners() {
    _netSubscription = vidController.onPlayerNetStatusBroadcast
        .listen(_netStatusBroadcastListener);
    _eventSubscription =
        vidController.onPlayerEventBroadcast.listen(_eventBroadcastListener);
    _stateSubscription =
        vidController.onPlayerState.listen(_playerStateListener);
    objectMgr.on(ObjectMgr.eventAppLifeState, _handleAppLifeCycle);
  }

  String downloadVideo({bool toast = true}) {
    if (isLocal.value) {
      return absoluteUrl.value;
    }

    String? mp4Video = checkLocalMp4File();
    if (mp4Video == null) {
      _logSaveFailure();
      if (toast) Toast.showToast(localized(toastHavenDownload));
      return "";
    }

    return mp4Video;
  }

  _logSaveFailure() async {
    String urlToSave1 = config.url;
    String urlToSave2 = absoluteUrl.value;
    String errorMsg =
        await objectMgr.tencentVideoMgr.checkFailedSave(urlToSave1, urlToSave2);
    objectMgr.tencentVideoMgr.addLog(urlToSave1, urlToSave2, errorMsg);
  }

  int retries = 0;

  _playerStateListener(value, {onError, onDone, cancelOnError}) {
    if (value is! TXPlayerState) return;
    switch (value) {
      case TXPlayerState.paused:
        playerState.value = TencentVideoState.PAUSED;
        break;
      case TXPlayerState.stopped:
        // playerState.value = TencentVideoState.END;
        return;
      case TXPlayerState.buffering:
        // ignore buffer loading state
        // stream.state = TencentVideoState.LOADING;
        return;
      case TXPlayerState.playing:
        playerState.value = TencentVideoState.PLAYING;
        break;
      case TXPlayerState.disposed:
        playerState.value = TencentVideoState.DISPOSED;
        break;
      case TXPlayerState.failed:
        playerState.value = TencentVideoState.ERROR;
        break;
    }

    notifyParentOnPlayerState(playerState.value, this);
  }

  bool _isSaving = false;

  _eventBroadcastListener(event, {onError, onDone, cancelOnError}) async {
    // TXVodPlayEvent e = event["event"];
    if (currentTick > 0) {
      currentTick -= config.progressInterval;
      if (currentTick <= 0) {
        _isSaving = false;
        currentTick = 0;
      }
    }

    var e = event["event"];
    // pdebug("ededed - event $event");
    switch (e) {
      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED:
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
      case TXVodPlayEvent.VOD_PLAY_EVT_SEEK_COMPLETE:
        notifyParentOnPlayerEvent(e, this);
        break;
      default:
        break;
    }

    if (e == TXVodPlayEvent.PLAY_EVT_PLAY_END) {
      //播放完毕
      currentProgress.value = videoDuration.value;
    }

    if (e == TXVodPlayEvent.VOD_PLAY_EVT_SEEK_COMPLETE ||
        e == TXVodPlayEvent.PLAY_EVT_RTMP_STREAM_BEGIN) {
      //增加重连状态
      isSeeking.value = false;
    }

//17 毫秒
    if (e == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS && !isSeeking.value) {
      // // 播放进度, 单位是秒
      int progress = 0;
      if (event[TXVodPlayEvent.EVT_PLAY_PROGRESS_MS] != null) {
        //安卓会给MS
        progress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS_MS];
      } else if (event[TXVodPlayEvent.EVT_PLAY_PROGRESS] !=
          null) //iOS会给seconds (double)
      {
        progress = (event[TXVodPlayEvent.EVT_PLAY_PROGRESS] * 1000).toInt();
      }

      if (progress < 0) progress = 0;
      currentProgress.value = progress;
      // // 视频总长, 单位是秒
      int duration = 0;
      if (event[TXVodPlayEvent.EVT_PLAY_DURATION_MS] != null) {
        duration = event[TXVodPlayEvent.EVT_PLAY_DURATION_MS];
      } else if (event[TXVodPlayEvent.EVT_PLAY_DURATION] != null) {
        duration = (event[TXVodPlayEvent.EVT_PLAY_DURATION] * 1000).toInt();
      }
      videoDuration.value = duration;
      // 更多详细请查看iOS或者Android原生SDK状态码
      // 可播放时长，即加载进度, 单位是毫秒
      //ios 只有playable_duration
      int playableDuration = 0;
      if (isM3u8 || !isLocal.value) {
        if (event["PLAYABLE_DURATION"] != null) {
          playableDuration = (event["PLAYABLE_DURATION"] * 1000).toInt();
        } else if (event[TXVodPlayEvent.EVT_PLAYABLE_DURATION_MS] != null) {
          playableDuration = event[TXVodPlayEvent.EVT_PLAYABLE_DURATION_MS];
        }

        if (videoDuration.value - playableDuration <= 1000 ||
            !absoluteUrl.value.contains("http")) {
          //m3u8d读取和外边不一致
          bufferProgress.value = videoDuration.value;
        } else if (bufferProgress.value < playableDuration) {
          bufferProgress.value = playableDuration;
        }

        if (config.type == ConfigType.saveMp4 &&
            !_isSaving &&
            bufferProgress.value == videoDuration.value &&
            absoluteUrl.value.contains("http")) {
          //pdebug download ready
          if (isM3u8) {
            startCombineToMp4();
          } else {
            //mp4 copy
            startCopyMp4();
          }
        }
      } else {
        bufferProgress.value = videoDuration.value;
      }
    }
    if (event["event"] == TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED) {
      if (config.initialMute) await mute();
    }

    if (bufferProgress.value != videoDuration.value &&
        config.type == ConfigType.saveMp4) {
      //朋友全/视频号
      if (bufferProgress.value != lastBufferProgress) {
        lastBufferProgress = bufferProgress.value;
        bufferTick = 0;
      } else {
        if (!isBufferDownloading) {
          bufferTick += config.progressInterval;
          if (bufferTick >= 2000) {
            //超过两秒
            isBufferDownloading = true;
            bufferTick = 0;
            objectMgr.tencentVideoMgr.addDownloadTask(
              absoluteUrl.value,
              onComplete: () {},
              saveError: () {
                //下载失败，等待重试
                isBufferDownloading = false;
              },
            );
          }
        }
      }
    } else {
      //equals
      lastBufferProgress = bufferProgress.value;
    }
  }

  startCopyMp4() async {
    _isSaving = true;
    objectMgr.tencentVideoMgr.onMp4Ready(
        config.oldM3u8Path ?? config.url, absoluteUrl.value, _saveError);
  }

  startCombineToMp4() async {
    _isSaving = true;
    objectMgr.tencentVideoMgr
        .onDownloadReady(config.url, absoluteUrl.value, _saveError);
  }

  _saveError() async {
    currentTick = tickDuration; //增加重试
  }

  _netStatusBroadcastListener(event, {onError, onDone, cancelOnError}) async {
    double w = (event[TXVodNetEvent.NET_STATUS_VIDEO_WIDTH]).toDouble();
    double h = (event[TXVodNetEvent.NET_STATUS_VIDEO_HEIGHT]).toDouble();

    if (w > 0 && h > 0) {
      aspectRatio.value = 1.0 * w / h;
    }
  }

  pause() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    try {
      await vidController.pause();
      checkIfRequireDownload();
    } catch (e) {
      pdebug("unable to pause");
    }
  }

  play() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    if (!objectMgr.tencentVideoMgr.checkAllowPlay()) return;
    try {
      await vidController.resume();
    } catch (e) {
      pdebug("unable to resume");
    }
  }

  stop({bool isNeedClear = true}) async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    await vidController.stop(isNeedClear: true);
  }

  togglePlayState() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    if (playerState.value == TencentVideoState.PLAYING) {
      await pause();
    } else if (playerState.value == TencentVideoState.PAUSED ||
        playerState.value == TencentVideoState.PREPARED) {
      await play();
    } else if (playerState.value == TencentVideoState.END) {
      await restart();
    }
  }

  //快进十秒
  onForwardVideo() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    if (videoDuration.value == 0) return;
    int value = (currentProgress.value + 10000) > videoDuration.value
        ? videoDuration.value
        : currentProgress.value + 10000;
    previousState = playerState.value;
    currentProgress.value = value;
    isSeeking.value = true;
    if (value == videoDuration.value) {
      notifyParentOnPlayerState(TencentVideoState.SEEK_TO_END, this);
    }
    await seek(value / 1000);
  }

  onRewindVideo() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    int value =
        (currentProgress.value - 10000) < 0 ? 0 : currentProgress.value - 10000;
    previousState = playerState.value;
    currentProgress.value = value;
    isSeeking.value = true;
    await seek(value / 1000);
    if (previousState == TencentVideoState.END) {
      // 若是从尾倒退，则会重开视频，则需要另外暂停。
      await pause();
      previousState = TencentVideoState.PAUSED;
      playerState.value = TencentVideoState.PAUSED;
    }
  }

  restart() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    if (!objectMgr.tencentVideoMgr.checkAllowPlay()) return;
    notifyParentOnPlayerState(TencentVideoState.RESTARTING, this);
    await vidController.resume();
    await vidController.seek(0);
  }

  seek(double timeInMs) async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    if (bufferProgress.value == videoDuration.value) {
      notifyParentOnPlayerState(TencentVideoState.MUTE_LOADING, this);
    }
    await vidController.seek(timeInMs);
  }

  seekPdt(int pdtTimeInMs) async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    await vidController.seekToPdtTime(pdtTimeInMs);
  }

  setRate(double rate) async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    await vidController.setRate(rate);
  }

  Future<bool> isLoop() async {
    return await vidController.isLoop();
  }

  toggleMute() async {
    muted.value ? await unMute() : await mute();
  }

  mute() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    muted.value = true;
    await vidController.setMute(muted.value);
  }

  unMute() async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    muted.value = false;
    await vidController.setMute(muted.value);
  }

  //only after prepared
  Future<int> getWidth() async {
    return await vidController.getWidth();
  }

  Future<int> getHeight() async {
    return await vidController.getHeight();
  }

  dispose() {
    _stateSubscription?.cancel();
    _netSubscription?.cancel();
    _eventSubscription?.cancel();
    vidController.stop(isNeedClear: true);
    vidController.dispose();
    objectMgr.tencentVideoMgr.stopDownloadTask(absoluteUrl.value);

    objectMgr.off(ObjectMgr.eventAppLifeState, _handleAppLifeCycle);
  }

  onChangeStart(double v) {
    previousState = playerState.value;
    isSeeking.value = true;
    currentProgress.value = v.toInt();
  }

  onChange(double v) {
    currentProgress.value = v.toInt();
  }

  onChangeEnd(double v) async {
    // double seekPosDouble = v;
    previousState = playerState.value;
    await seek(v / 1000);
    if (previousState == TencentVideoState.END) {
      // 若是从尾倒退，则会重开视频，则需要另外暂停。
      await pause();
      previousState = TencentVideoState.PAUSED;
      playerState.value = TencentVideoState.PAUSED;
    }
  }

  enablePip() async {
    if (!objectMgr.tencentVideoMgr.supportPIP) return;
    await vidController.enterPictureInPictureMode();
  }

  setLoop(bool loop) async {
    if (playerState.value == TencentVideoState.DISPOSED) return;
    await vidController.setLoop(loop);
  }

  _handleAppLifeCycle(sender, type, data) {
    if (data is AppLifecycleState) {
      AppLifecycleState state = data;

      switch (state) {
        case AppLifecycleState.resumed:
          notifyParentOnPlayerState(TencentVideoState.PAUSED, this,
              setManuallyPaused: false);
          if (isControllerPlaying) {
            isControllerPlaying = false;
            play();
          }
          break;
        case AppLifecycleState.paused:
          isControllerPlaying = playerState.value == TencentVideoState.PLAYING;
          notifyParentOnPlayerState(TencentVideoState.PAUSED, this);
          pause();
          break;
        default:
          break;
      }
    }
  }

  checkIfRequireDownload() {
    if (config.type != ConfigType.saveMp4) return;
    if (!isBufferDownloading) {
      if (bufferProgress.value != videoDuration.value) {
        //超过两秒
        isBufferDownloading = true;
        bufferTick = 0;
        objectMgr.tencentVideoMgr.addDownloadTask(
          absoluteUrl.value,
          onComplete: () {
            bufferProgress.value = videoDuration.value;
            if (config.type == ConfigType.saveMp4 &&
                !_isSaving &&
                absoluteUrl.value.contains("http")) {
              //pdebug download ready
              if (isM3u8) {
                startCombineToMp4();
              } else {
                //mp4 copy
                startCopyMp4();
              }
            }
          },
          onProgress: (info) {
            if (isM3u8) {
              int duration = info.playableDuration;
              if (Platform.isIOS) {
                duration *= 1000;
              }
              bufferProgress.value = duration;
            } else {
              double progress = info.progress;
              bufferProgress.value = (progress * videoDuration.value).toInt();
            }
          },
          saveError: () {
            //下载失败，等待重试
            isBufferDownloading = false;
          },
        );
      }
    }
  }

//unused
//// 在收到播放器 PLAY_EVT_VOD_PLAY_PREPARED 事件调用 getSupportedBitrates 才会有值返回
// List _supportedBitrates = (await _controller.getSupportedBitrates())!;; //获取多码率数组
// int index = _supportedBitrates[i];  // 指定要播的码率下标
// _controller.setBitrateIndex(index);  // 切换码率到想要的清晰度
}
