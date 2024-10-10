import 'dart:async';

import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:super_player/super_player.dart';

class TencentVideoStreamMgr {
  late final List<TencentVideoStream> _data = [];
  final StreamController<TencentVideoStream> streamController =
      StreamController.broadcast();
  bool enteringBusinessPausePhase = false; //业务所需暂停
  Rxn<int> currentIndex = Rxn<int>();

  TencentVideoStreamMgr();

  Stream<TencentVideoStream> get onStreamBroadcast => streamController.stream;
  dynamic _tempEventUpdate;
  dynamic _tempStateUpdate;

  TencentVideoStream addController(TencentVideoConfig config, {int index = 0}) {
    var item = _data.firstWhereOrNull((element) => element.pageIndex == index);
    if (item != null) return item;

    if (objectMgr.tencentVideoMgr.pipStream != null) {
      objectMgr.tencentVideoMgr.closeFloating();
    }

    bool changeAutoPlay = false;
    if (!objectMgr.tencentVideoMgr.checkCallAllowPlay() && config.autoplay) {
      config.autoplay = false; //自动false
      changeAutoPlay = true;
    }

    TencentVideoController controller = TencentVideoController(
      config: config,
      notifyParentOnPlayerEvent: _onPlayerEventUpdate,
      notifyParentOnPlayerState: _onPlayerStateUpdate,
    );

    TencentVideoStream videoStream = TencentVideoStream(
      controller: controller,
      url: config.url,
      pageIndex: index,
    );

    controller.playerState = videoStream.state;
    if (changeAutoPlay) {
      videoStream.hasManuallyPaused = true;
    }
    _data.add(videoStream);
    return videoStream;
  }

  List<TencentVideoStream> getAllStreams() {
    return _data;
  }

  removeAllControllersExcept(List<TencentVideoStream> streams) {
    List<TencentVideoStream> s = [];
    for (var d in _data) {
      if (streams.contains(d)) continue;
      d.state.value = TencentVideoState.DISPOSED;
      d.controller.dispose();
      streamController.add(d);
      s.add(d);
    }
    _data.removeWhere((element) => !streams.contains(element));
  }

  removeController(int index) {
    TencentVideoStream? stream =
        _data.firstWhereOrNull((element) => element.pageIndex == index);
    if (stream == null) return;
    if (stream.stopRemoval) return;
    stream.controller.dispose();
    stream.state.value = TencentVideoState.DISPOSED;
    _data.remove(stream);
    streamController.add(stream);
  }

  realignIndex(int indexToAlign, {int reducingOffset = 1}) {
    List<TencentVideoStream> itemsToReAlign = _data.where((element) => element.pageIndex > indexToAlign).toList(); //
    for (var element in itemsToReAlign) {
      element.pageIndex -= reducingOffset;
      //从移除流上面把所有index进行-1
    }
  }

  bool shouldBuild(int currentIndexOfPage, int indexToBuild, int range) {
    return (currentIndexOfPage - range) <= indexToBuild &&
        indexToBuild <= (currentIndexOfPage + range);
  }

  pausePlayingControllers(int index) async{
    List<TencentVideoStream> toPause =
        _data.where((element) => element.pageIndex != index).toList();
    for (var element in toPause) {
      await element.controller.pause();
    }
  }

  removeAllControllers() {
    for (var stream in _data) {
      stream.controller.dispose();
      stream.state.value = TencentVideoState.DISPOSED;
      streamController.add(stream);
    }
    _data.clear();
  }

  stopAllControllers() {
    for (var element in _data) {
      element.controller.pause();
    }
  }

  addPipStream(TencentVideoStream stream) {
    _data.add(stream);
    stream.controller.setLoop(false);
    stream.controller.config.isLoop = false;
    stream.controller.notifyParentOnPlayerEvent = _onPlayerEventUpdate;
    stream.controller.notifyParentOnPlayerState = _onPlayerStateUpdate;
  }

  removeFloatingStream(TencentVideoStream stream) {
    _data.remove(stream);
  }

  removeControllersOutOfRange(int index, int range) {
    List<TencentVideoStream> toRemove = _data
        .where((element) => !shouldBuild(element.pageIndex, index, range))
        .toList();

    for (var element in toRemove) {
      removeController(element.pageIndex);
    }
  }

  // TencentVideoStream? getVideoStreamByUrl(String url) {
  //   TencentVideoStream? stream =
  //       _data.firstWhereOrNull((element) => element.url == url);
  //   return stream;
  // }
  //
  // removeVideoStreamByUrl(String url) {
  //   var stream = getVideoStreamByUrl(url);
  //   if (stream == null) return;
  //   stream.controller.dispose();
  //   stream.state.value = TencentVideoState.DISPOSED;
  //   _data.remove(stream);
  //   _streamController.add(stream);
  // }
  bool hasStream() {
    return _data.isNotEmpty;
  }

  TencentVideoController? getVideo(int index) {
    TencentVideoStream? stream =
        _data.firstWhereOrNull((element) => element.pageIndex == index);
    return stream?.controller;
  }

  TencentVideoStream? getVideoStream(int index) {
    TencentVideoStream? stream =
        _data.firstWhereOrNull((element) => element.pageIndex == index);
    return stream;
  }

  updateCurrentIndex(int index) {
    currentIndex.value = index;
    TencentVideoStream? s = getVideoStream(index);
    if (s != null) {
      if (!streamController.isClosed) {
        streamController.add(s);
      }
    }
  }

  _onPlayerEventUpdate(int event, TencentVideoController controller) {
    TencentVideoStream? stream =
        _data.firstWhereOrNull((element) => element.controller == controller);
    if (stream == null) return;
    switch (event) {
      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED:
        stream.hasEnteredPrepared = true;
        stream.state.value = TencentVideoState.PREPARED;
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
        if (stream.hasManuallyPaused) return;

        if (stream.state.value != TencentVideoState.LOADING) {
          //if have entered loading, stop updating to playing
          stream.state.value = TencentVideoState.PLAYING;
        }

        if (currentIndex.value != null &&
            stream.pageIndex != currentIndex.value) {
          controller.pause();
        }

        if (!stream.hasUpdatedAudioSession) {
          stream.updateAudioSession();
        }
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
        stream.state.value = TencentVideoState.LOADING;
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
        stream.hasManuallyPaused = false;
        stream.state.value = TencentVideoState.PLAYING;
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
        stream.state.value = TencentVideoState.END;
        break;
      case TXVodPlayEvent.VOD_PLAY_EVT_SEEK_COMPLETE:
        stream.state.value = controller.previousState;
        break;
      default:
        break;
    }
    // pdebug(stream.state.value);
    // print("stream update - ${stream.state.value}");
    if (!streamController.isClosed) {
      streamController.add(stream);
    } else {
      stream.controller.dispose(); //确认关闭了还接收到状态更新，直接让播放器释放
    }

    if (enteringBusinessPausePhase) { //若是业务所需还收到播放事件（就强制让播放器暂停）
      stream.controller.pause();
    }

  }

  _onPlayerStateUpdate(
      TencentVideoState state, TencentVideoController controller,
      {bool? setManuallyPaused}) {
    TencentVideoStream? stream =
        _data.firstWhereOrNull((element) => element.controller == controller);
    if (stream == null) return;
    if (state == TencentVideoState.PAUSED) {
      stream.hasManuallyPaused = setManuallyPaused ?? true;
    }
    stream.state.value = state;

    if (!streamController.isClosed) {
      streamController.add(stream);
    }else {
      stream.controller.dispose(); //确认关闭了还接收到状态更新，直接让播放器释放
    }

    if (stream.state.value == TencentVideoState.PAUSED) {
      stream.hasUpdatedAudioSession = false;
    }
  }

  _removeAllControllers() {
    for (var stream in _data) {
      stream.state.value = TencentVideoState.DISPOSED;
      stream.controller.dispose();
      if (!streamController.isClosed) {
        streamController.add(stream);
      }
    }
    _data.clear();
  }

  dispose() {
    _removeAllControllers();
    streamController.close();
  }

  updateStream(TencentVideoStream stream) {
    _data.add(stream);
    _tempEventUpdate = stream.controller.notifyParentOnPlayerEvent;
    _tempStateUpdate = stream.controller.notifyParentOnPlayerState;
    stream.controller.notifyParentOnPlayerEvent = _onPlayerEventUpdate;
    stream.controller.notifyParentOnPlayerState = _onPlayerStateUpdate;
  }

  clearStartingStream(TencentVideoStream stream) {
    _data.remove(stream);
    stream.controller.notifyParentOnPlayerEvent = _tempEventUpdate;
    stream.controller.notifyParentOnPlayerState = _tempStateUpdate;
  }
}

class TencentVideoStream {
  bool isEnteringPIPMode;
  bool hasEnteredPrepared;
  bool stopRemoval;
  bool hasUpdatedAudioSession;
  int pageIndex;
  bool hasManuallyPaused;
  final TencentVideoController controller;
  final String url;

  late Rx<TencentVideoState> state;

  TencentVideoStream({
    this.pageIndex = 0,
    required this.controller,
    required this.url,
    this.isEnteringPIPMode = false,
    this.hasEnteredPrepared = false,
    this.stopRemoval = false,
    this.hasUpdatedAudioSession = false,
    this.hasManuallyPaused = false,
    // this.state = TencentVideoState.INIT,
  }) {
    state = TencentVideoState.INIT.obs;
  }

  updateAudioSession() async {
    hasUpdatedAudioSession = true;
    objectMgr.tencentVideoMgr.updateAudioSession();
    // var requireUpdate = await objectMgr.tencentVideoMgr.getAudioSession();
    // if (requireUpdate) {
    //   objectMgr.tencentVideoMgr.updateAudioSession();
    // }
  }
}
