import 'dart:async';
import 'dart:io';

import 'package:all_sensors/all_sensors.dart';
import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:logger/logger.dart' show Level;
// GooglePlay=====>
import 'package:proximity_sensor/proximity_sensor.dart';
// <=====GooglePlay

///
enum VolumePlayerServiceType {
  play(),
  pause(),
  stop();

  const VolumePlayerServiceType();
}

class VolumePlayerService extends EventDispatcher {
  static const String playerStateChange = 'playerStateChange';

  static const String keyVolumePlayerStatus = 'keyVolumePlayerStatus';
  static const String keyVolumePlayerProgress = 'keyVolumePlayerProgress';

  factory VolumePlayerService() => _getInstance();

  static VolumePlayerService get sharedInstance => _getInstance();

  static VolumePlayerService? _instance;

  VolumePlayerService._internal() {
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMessageDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventVoicePause, _eventVoicePause);
    objectMgr.callMgr.on(CallMgr.eventBluetoothChanged, _onBluetoothChanged);
    _doInit();
  }

  static VolumePlayerService _getInstance() {
    _instance ??= VolumePlayerService._internal();
    return _instance!;
  }

  StreamSubscription? _playerSubscription;

  final FlutterSoundPlayer _player =
      FlutterSoundPlayer(logLevel: Level.nothing);

  // 播放设置

  // 播放器选择
  AudioDevice playbackDevice = AudioDevice.speaker;

  bool get isPlaying => _player.isPlaying;

  bool? get isPlayedBefore =>
      objectMgr.localStorageMgr.read('${currentMessage?.message_id}') != null;
  String currentPlayingFileName = '';
  Message? currentMessage;
  String currentPlayingFile = '';
  Map<String, double> playbackDuration = {};
  Uint8List? sendMessageBuffer;
  String playbackKey = '';
  String currentUsrName = '';

  final StreamController<bool> _playerStateController =
      StreamController.broadcast();
  final StreamController<double> _playerDurationController =
      StreamController.broadcast();

  // 音频设置初始化判断
  bool isOpenAudioSession = false;

  // 传感器监听
  final List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  List<Message> nextPlayerAudioTag = [];

  bool sendFunctionOnceAtStatusChange = true;

  _doInit() {
    // GooglePlay=====>
    ProximitySensor.setProximityScreenOff(true).onError((error, stackTrace) {
      return null;
    });
    // <=====GooglePlay
  }

  /// 只需要调一次
  Future<void> openPlayer({
    required VoidCallback onFinish,
    Function(PlaybackDisposition)? onProgress,
    VoidCallback? onPlayerStateChanged,
    AudioDevice? device,
    bool? isFromChatInfoPage,
    bool shouldCache = true,
    bool shouldEnablePinNotify = true,
    bool isPlayVoiceMessage = true,
  }) async {
    await stopPlayer();
    //stop后直接调用_startPlayer ，会导致引擎为nil(偶现)，所以延迟一下
    if (isFromChatInfoPage ?? false) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!isOpenAudioSession) {
      await _player.openAudioSession(
        focus: AudioFocus.requestFocusAndDuckOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: playbackDevice,
      );
      isOpenAudioSession = true;
    }

    if (!isPlayedBefore! && shouldCache) {
      assert(
        currentMessage != null,
        "Message is required to cache audio playing status",
      );
      objectMgr.localStorageMgr
          .write<bool>('${currentMessage!.message_id}', true);
      objectMgr.chatMgr.event(
        objectMgr.chatMgr,
        ChatMgr.eventVoicePlayUpdate,
        data: {
          'message_id': currentMessage!.message_id,
        },
      );
    }

    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    if (isPlayVoiceMessage) {
      if (Platform.isIOS) {
        _streamSubscriptions.add(
          proximityEvents!.listen((ProximityEvent event) async {
            _onProximityChanged(event.getValue());
          }),
        );
      } else {
        // GooglePlay=====>
        _streamSubscriptions.add(ProximitySensor.events.listen((int event) {
          _onProximityChanged(event > 0);
        }));
        // <=====GooglePlay
      }
    }

    await _player.setSubscriptionDuration(const Duration(milliseconds: 5));
    _startPlayer(
      onFinish: onFinish,
      onProgress: onProgress,
      onPlayerStateChanged: onPlayerStateChanged,
      shouldEnablePinNotify: shouldEnablePinNotify,
      isPlayVoiceMessage: isPlayVoiceMessage,
    );
  }

  _onProximityChanged(bool isNear) async {
    bool isBluetooth = await isBluetoothDevice();
    if (isBluetooth) {
      objectMgr.callMgr.bluetoothPlay();
    } else {
      if (isNear || playbackDevice == AudioDevice.earPiece) {
        switchToHeadphones();
      } else {
        switchToSpeaker();
      }
    }
  }

  _onMessageDeleted(sender, type, data) {
    if (currentMessage == null || data['id'] != currentMessage!.chat_id) {
      return;
    }

    if (data['message'] != null) {
      bool find = false;
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == currentMessage!.id) {
            find = true;
            break;
          }
        } else {
          if (item == currentMessage!.message_id) {
            find = true;
            break;
          }
        }
      }
      if (find) {
        isShowAudioPin.value = false;
        VolumePlayerService.sharedInstance.doCheckPlayingAudio(
          VolumePlayerService.sharedInstance.currentPlayingFileName,
          stop: true,
        );
      }
    }
  }

  /// 正确播放语音或者音频需调用这个
  _startPlayer({
    required VoidCallback onFinish,
    Function(PlaybackDisposition)? onProgress,
    VoidCallback? onPlayerStateChanged,
    bool shouldEnablePinNotify = true,
    bool isPlayVoiceMessage = true,
  }) async {
    try {
      if (shouldEnablePinNotify) isShowAudioPinWidget();
      final user =
          await objectMgr.userMgr.loadUserById2(currentMessage?.send_id ?? 0);
      String newDisplayName = objectMgr.userMgr.getUserTitle(user);
      Chat? chat = objectMgr.chatMgr.getChatById(currentMessage!.chat_id);
      if (chat != null && chat.isGroup) {
        newDisplayName =
            objectMgr.userMgr.getUserTitle(user, groupId: chat.chat_id);
      }
      currentUsrName = newDisplayName;

      setAudioSession(device: playbackDevice);

      objectMgr.tencentVideoMgr.pauseAllControllers(); //若有视频正在播放，则直接暂停

      await _player.startPlayer(
        fromURI: currentPlayingFile,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          stopPlayer();
          resetPlayer();
          //结束播放
          onFinish();
          if (isPlayVoiceMessage) {
            event(
              this,
              keyVolumePlayerStatus,
              data: VolumePlayerServiceType.stop,
            );
          }
          sendFunctionOnceAtStatusChange = true;
        },
      );

      if (getPlaybackDuration(currentPlayingFileName) >= 0.0) {
        await seekTo(getPlaybackDuration(currentPlayingFileName).toInt());
      }

      _playerStateController.sink.add(_player.isPlaying);

      ////此处有内存泄露
      await _subscribeToProgressStream(onProgress);

      Future.delayed(const Duration(milliseconds: 10), () {
        onPlayerStateChanged?.call();
      });
    } catch (err) {
      pdebug('_startPlayer【播放错误】: $err');
    }
  }

  StreamSubscription<PlaybackDisposition>? _progressSubscription;

  Future<void> _subscribeToProgressStream(
    Function(PlaybackDisposition)? onProgress,
  ) async {
    // 取消旧的订阅（如果存在）
    _progressSubscription?.cancel();

    // 创建新的订阅
    _progressSubscription = _player.onProgress!
        .listen((PlaybackDisposition playbackDisposition) async {
      // pdebug("播放进度：${event.position.inMilliseconds}");
      if (objectMgr.callMgr.getCurrentState() == CallState.Idle) {
        playbackDuration[currentPlayingFileName] =
            playbackDisposition.position.inMilliseconds.toDouble();
        _playerDurationController.sink
            .add(playbackDisposition.position.inMilliseconds.toDouble());
        if (onProgress != null) {
          onProgress(playbackDisposition);
        }
        event(this, keyVolumePlayerProgress, data: playbackDisposition);
      } else {
        await pausePlayer();
      }
    });
  }

  void doCheckPlayingAudio(
    String playbackFileName, {
    bool stop = false,
  }) {
    if (currentPlayingFileName != playbackFileName) return;

    if (stop) {
      stopPlayer();
    }
  }

  Future<void> stopPlayer() async {
    try {
      await _player.stopPlayer();
      cancelPlayerSubscriptions();
      _playerStateController.sink.add(_player.isPlaying);
      // 取消传感器订阅
      for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
        subscription.cancel();
      }

      event(this, playerStateChange, data: false);
    } catch (err) {
      pdebug('stopPlayer====> 错误：$err');
    }
  }

  void resetPlayer() {
    isShowAudioPin.value = false;
    audioPinProgressPercent.value = 0;
    currentPlayingFileName = '';
    currentPlayingFile = '';
  }

  cancelPlayerSubscriptions() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
  }

  Stream<bool> get playerStateStream => _playerStateController.stream;

  Stream<double> get playerDurationStream => _playerDurationController.stream;

  /// ================================= UTIL ===================================
  Future<void> resumePlayer() async {
    objectMgr.tencentVideoMgr.pauseAllControllers(); //若有视频正在播放，则直接暂停
    try {
      if (Platform.isIOS) {
        bool isBluetooth = await isBluetoothDevice();
        if (isBluetooth) {
          objectMgr.callMgr.bluetoothPlay();
        } else {
          objectMgr.callMgr.setAudioSoundForVoice(
              playbackDevice == AudioDevice.speaker
                  ? SoundType.speaker
                  : SoundType.reciever);
        }
      }

      await _player.resumePlayer();
      event(this, keyVolumePlayerStatus, data: VolumePlayerServiceType.play);
      _playerStateController.sink.add(_player.isPlaying);
    } catch (e) {
      pdebug('resumePlayer====> 错误：$e');
    }
  }

  Future<void> pausePlayer() async {
    try {
      await _player.pausePlayer();
      _playerStateController.sink.add(_player.isPlaying);
      event(this, keyVolumePlayerStatus, data: VolumePlayerServiceType.pause);
    } catch (e) {
      pdebug('pausePlayer====> 错误：$e');
    }
  }

  // seek to function must ensure the player has been started and either state isPlaying or isPaused
  Future<void> seekTo(int milliseconds) async =>
      await _player.seekToPlayer(Duration(milliseconds: milliseconds));

  double getPlaybackDuration(String key) => playbackDuration[key] ?? 0.0;

  void setPlaybackDuration(String key, double milliseconds) =>
      playbackDuration[key] = milliseconds;

  void removePlaybackDuration(String key) => playbackDuration.remove(key);

  Future<void> setPlaybackSpeed(double scale) async =>
      await _player.setSpeed(scale);

  Future<void> releaseAudio() async {
    try {
      await _player.closeAudioSession();
    } catch (e) {
      pdebug(e);
    }
  }

  Future<void> setAudioSession({
    AudioDevice device = AudioDevice.speaker,
  }) async {
    bool isBluetooth = await isBluetoothDevice();
    if (isBluetooth && (device != AudioDevice.speaker)) {
      await switchToBluetooth();
    } else if (!isBluetooth && (device != AudioDevice.speaker)) {
      await switchToHeadphones();
    } else {
      await switchToSpeaker();
      if (isBluetooth && Platform.isIOS) objectMgr.callMgr.bluetoothPlay();
    }
  }

  Future<bool> isBluetoothDevice() async {
    bool isBluetooth = false;
    if (Platform.isIOS) {
      isBluetooth = await objectMgr.callMgr.isBluetoothConnected();
    } else {
      final session = await audio_session.AudioSession.instance;
      final audioDevices = await session.getDevices();
      for (var element in audioDevices) {
        if (element.type == audio_session.AudioDeviceType.bluetoothA2dp ||
            element.type == audio_session.AudioDeviceType.bluetoothSco ||
            element.type == audio_session.AudioDeviceType.bluetoothLe) {
          isBluetooth = true;
        }
      }
    }
    return isBluetooth;
  }

  resetState() {
    playbackDuration.clear();
    currentPlayingFileName = '';
    currentPlayingFile = '';
  }

  Future<bool> switchToSpeaker() async {
    if (Platform.isIOS) {
      objectMgr.callMgr.setAudioSoundForVoice(SoundType.speaker);
    } else {
      final audioManager = audio_session.AndroidAudioManager();
      await audioManager.setMode(audio_session.AndroidAudioHardwareMode.normal);
      await audioManager.stopBluetoothSco();
      await audioManager.setBluetoothScoOn(false);
      await audioManager.setSpeakerphoneOn(true);
    }
    return true;
  }

  Future<bool> switchToHeadphones() async {
    if (Platform.isIOS) {
      objectMgr.callMgr.setAudioSoundForVoice(SoundType.reciever);
    } else {
      final audioManager = audio_session.AndroidAudioManager();
      await audioManager
          .setMode(audio_session.AndroidAudioHardwareMode.inCommunication);
      await audioManager.stopBluetoothSco();
      await audioManager.setBluetoothScoOn(false);
      await audioManager.setSpeakerphoneOn(false);
    }
    return true;
  }

  Future<bool> switchToBluetooth() async {
    if (Platform.isIOS) {
      objectMgr.callMgr.bluetoothPlay();
    } else {
      final audioManager = audio_session.AndroidAudioManager();
      await audioManager
          .setMode(audio_session.AndroidAudioHardwareMode.inCommunication);
      await audioManager.startBluetoothSco();
      await audioManager.setBluetoothScoOn(true);
    }
    return true;
  }

  Future<void> _eventVoicePause(
    Object sender,
    Object type,
    Object? data,
  ) async {
    if (_player.isPlaying) {
      pausePlayer();
    }
  }

  Future<void> _onBluetoothChanged(
      Object sender, Object type, Object? data) async {
    if (data != null &&
        data is Map &&
        objectMgr.callMgr.currentState.value == CallState.Idle) {
      final hasBluetooth = data["hasBluetooth"] == true;
      pdebug("_onBluetoothChanged======> $hasBluetooth | $playbackDevice");
      if (!hasBluetooth) {
        if (playbackDevice == AudioDevice.earPiece) {
          switchToHeadphones();
        } else {
          switchToSpeaker();
        }
      } else {
        if (Platform.isAndroid) {
          objectMgr.callMgr.bluetoothPlay();
        }
      }
    }
  }

  onClose() async {
    Future.delayed(Duration.zero, () {
      if (_player.isPaused || _player.isPlaying) {
        // 需求：1. 当在聊天室播放语音的时，去详情页或者放大图片的时候，再回来，如果没有播放完毕，顶部条还要在，并继续播放
        //      2. 切后台：播放一半的语音消息，切后台回到app，点击继续播放，没有继续播放而是从头开始播放
        //      3. 语音消息播放中，切后台再回来时，语音悬浮栏消失了（TG切回来继续播放还会有悬浮栏）
        pausePlayer();
      } else {
        stopPlayer();
        resetPlayer();
      }
    });
  }

  logout() async {
    stopPlayer();
    resetPlayer();
    isShowAudioPin.value = false;
    audioSpeed.value = 1.0;
  }

  void isShowAudioPinWidget() {
    var currentRoute = Get.currentRoute;
    if ('/chat/groupChatInfo' == currentRoute ||
        '/chat/chatInfo' == currentRoute) {
      isShowAudioPin.value = false;
    } else {
      isShowAudioPin.value = true;
    }
  }

  void autoPlayNextAudio(int index) async {
    int neverPlayedIndex = index;

    if (neverPlayedIndex.isNegative) {
      audioSpeed.value = 1.0;
      setPlaybackSpeed(audioSpeed.value);

      if (Get.isRegistered<FancyGestureController>()) {
        Get.find<FancyGestureController>().event.event(
              this,
              FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
              data: FancyGestureEventType.enable,
            );
      }

      return;
    }

    for (int i = index; index >= 0; i--) {
      if (i.isNegative) {
        audioSpeed.value = 1.0;
        setPlaybackSpeed(audioSpeed.value);

        Get.find<FancyGestureController>().event.event(
              this,
              FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
              data: FancyGestureEventType.enable,
            );
        return;
      }

      if (!(objectMgr.localStorageMgr
              .read('${nextPlayerAudioTag[i].message_id}') !=
          null)) {
        neverPlayedIndex = i;
        break;
      }
    }

    setPlaybackDuration(currentPlayingFileName, 0.0);
    MessageVoice messageVoice = nextPlayerAudioTag[neverPlayedIndex]
        .decodeContent(cl: MessageVoice.creator);

    String? voiceFilePath;
    String? cacheUrl = messageVoice.localUrl;
    if (cacheUrl != null && cacheUrl.isNotEmpty) {
      voiceFilePath = cacheUrl;
      final f = File(voiceFilePath);
      if (!f.existsSync()) {
        voiceFilePath = null;
      }
    }

    if (voiceFilePath == null || voiceFilePath.isEmpty) {
      voiceFilePath = await cacheMediaMgr.downloadMedia(
            messageVoice.url,
            onReceiveProgress: (int received, int total) {
              // downloadProgress.value = received / total;
            },
          ) ??
          '';
    }

    if (voiceFilePath.isEmpty) return;

    playbackKey =
        '${nextPlayerAudioTag[neverPlayedIndex].message_id}_$voiceFilePath';

    final f = File(voiceFilePath);
    if (f.existsSync()) {
      currentPlayingFileName = playbackKey;
      currentMessage = nextPlayerAudioTag[neverPlayedIndex];
      currentPlayingFile = voiceFilePath;

      if (getPlaybackDuration(
            '${nextPlayerAudioTag[neverPlayedIndex].message_id}_null',
          ) >
          0.0) {
        setPlaybackDuration(
          playbackKey,
          getPlaybackDuration(
            '${nextPlayerAudioTag[neverPlayedIndex].message_id}_null',
          ),
        );
        removePlaybackDuration(
          '${nextPlayerAudioTag[neverPlayedIndex].message_id}_null',
        );
      }
    } else {
      Toast.showToast("语音文件不存在");
      return;
    }

    await openPlayer(
      onFinish: () {
        sendFunctionOnceAtStatusChange = true;
        removePlaybackDuration(playbackKey);
      },
      onProgress: (_) {
        isAudioPinPlaying.value = true;
      },
    );
  }
}
