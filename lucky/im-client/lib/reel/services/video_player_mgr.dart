import 'dart:async';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:cbb_video_player/cbb_video_player.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:video_player/video_player.dart';

class Video extends EventDispatcher {
  //位置更新
  static String EVENT_UPDATEPOS = "event_updatepos";

  static String EVENT_PLAYSTATE_CHANGE = "event_playstate_change";

  static int DISPOSED_CONTROLLER_CODE = 10001;

  //当前播放位置
  Duration? position;
  int totalSecond = 0;
  int totalMillisecond = 0;

  dynamic url;
  String key = '';
  bool isInitialized = false;
  double curVolume = 1.0;

  VideoPlayerController? _videoCtr;

  VideoPlayerController? get videoCtr => _videoCtr;

  VlcPlayerController? _vlcPlayerController;

  VlcPlayerController? get vlcPlayerController => _vlcPlayerController;

  //当前播放时长
  int _currentSecond = 0;

  int get currentSecond => _currentSecond;

  bool playbackComplete = false;

  set currentSecond(int value) {
    if (_currentSecond == value) return;
    _currentSecond = value;
  }

  bool _curMixWithOthers = false;

  Video(
    dynamic _url, {
    bool mixWithOthers = false,
    bool autoInitialize = true,
    bool autoPlay = true,
  }) {
    url = _url;

    _curMixWithOthers = mixWithOthers;

    if (_url is File) {
      key = _url.path;

      _vlcPlayerController = VlcPlayerController.file(
        _url,
        autoPlay: autoPlay,
        autoInitialize: autoInitialize,
        allowBackgroundPlayback: false,
      );
    } else {
      _videoCtr = VideoPlayerController.network(_url,
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: false,
            mixWithOthers: mixWithOthers,
          ));
    }

    _vlcPlayerController?.addListener(_addListener);
    _videoCtr?.addListener(_addListener);
  }

  Future<void> initialize() async {
    if ((_videoCtr?.value.isInitialized ?? false) ||
        (vlcPlayerController?.value.isInitialized ?? false)) return;
    try {
      if (vlcPlayerController != null) {
        await vlcPlayerController?.initialize();
      } else {
        await _videoCtr?.initialize();
      }
    } catch (e) {
      pdebug("Initialize error: $e");
      rethrow;
    }
  }

  _addListener() async {
    if (vlcPlayerController != null) {
      if (!vlcPlayerController!.value.isInitialized) return;

      position = vlcPlayerController?.value.position;
      if (position == null) return;
      bool totalSecondChanged =
          totalSecond != (vlcPlayerController?.value.duration.inSeconds ?? 0);
      totalSecond = vlcPlayerController?.value.duration.inSeconds ?? 0;
      totalMillisecond =
          vlcPlayerController?.value.duration.inMilliseconds ?? 0;
      if (currentSecond != position!.inSeconds && position!.inSeconds == 0) {
        playbackComplete = true;
      } else {
        playbackComplete = false;
      }

      currentSecond = position!.inSeconds;

      event(this, Video.EVENT_UPDATEPOS,
          data: totalSecondChanged ? true : false);
      return;
    }

    if (!_videoCtr!.value.isInitialized) return;
    position = _videoCtr?.value.position;
    if (position == null) return;
    totalSecond = videoCtr?.value.duration.inSeconds ?? 0;
    if (currentSecond != position!.inSeconds && position!.inSeconds == 0) {
      playbackComplete = true;
    }

    currentSecond = position!.inSeconds;
    event(this, Video.EVENT_UPDATEPOS);
  }

  Future<void> setLooping(bool isLooping) async {
    if (vlcPlayerController != null) {
      await vlcPlayerController?.setLooping(isLooping);
      return;
    }

    if (isLooping == (videoCtr?.value.isLooping ?? false)) return;
    await videoCtr?.setLooping(isLooping);
  }

  Future<void> togglePlayState() async {
    if (vlcPlayerController != null) {
      // await play();
      if (vlcPlayerController!.value.isPlaying) {
        await pause();
      } else {
        if (playbackComplete) {
          await stop();
        }
        await play();
      }

      return;
    }

    if (videoCtr!.value.isPlaying) {
      pause();
    } else {
      if (playbackComplete) {
        seekTo(Duration.zero);
      }
      play();
    }
  }

  Future<void> play() async {
    if (vlcPlayerController != null) {
      try {
        if (!vlcPlayerController!.value.isInitialized) {
          await vlcPlayerController?.initialize();
        }
        if (!vlcPlayerController!.value.isPlaying) {
          await vlcPlayerController?.play();
        }
        return;
      } catch (e) {
        throw DISPOSED_CONTROLLER_CODE;
      }
    }
    await videoCtr?.play();
  }

  Future<void> pause() async {
    if (vlcPlayerController != null &&
        vlcPlayerController!.value.isInitialized &&
        vlcPlayerController!.value.isPlaying) {
      try {
        await vlcPlayerController?.pause();
        return;
      } catch (_) {
        throw DISPOSED_CONTROLLER_CODE;
      }
    }
    if (videoCtr?.value.isPlaying ?? false) {
      await videoCtr?.pause();
    }
  }

  Future<void> stop() async {
    if (vlcPlayerController != null &&
        vlcPlayerController!.value.isInitialized) {
      try {
        await vlcPlayerController?.stop();
        return;
      } catch (e) {
        throw DISPOSED_CONTROLLER_CODE;
      }
    }

    await videoCtr?.pause();
    await videoCtr?.seekTo(Duration.zero);
  }

  Future<void> seekTo(Duration position) async {
    if (vlcPlayerController != null) {
      await vlcPlayerController?.seekTo(position);
      return;
    }
    await videoCtr?.seekTo(position);
  }

  Future<void> setVolume(double volume) async {
    if (curVolume == volume) return;
    curVolume = volume;
    //静音允许混流
    bool needMix = curVolume <= 0;
    if (_curMixWithOthers != needMix) {
      _curMixWithOthers = needMix;
    }

    if (vlcPlayerController != null) {
      await vlcPlayerController?.setVolume(volume.toInt() * 100);
      return;
    }
    await videoCtr?.setVolume(volume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (vlcPlayerController != null) {
      await vlcPlayerController?.setPlaybackSpeed(speed);
      return;
    }
    await videoCtr?.setPlaybackSpeed(speed);
  }

  void dispose() {
    isInitialized = false;
    _videoCtr?.dispose();
    _vlcPlayerController?.dispose();
  }
}
