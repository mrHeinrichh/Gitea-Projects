import 'dart:async';
import 'dart:io';

import 'package:all_sensors/all_sensors.dart';
import 'package:audio_session/audio_session.dart' as audioSession;
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:logger/logger.dart' show Level;

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

  factory VolumePlayerService() => _getInstance();

  static VolumePlayerService get sharedInstance => _getInstance();

  static VolumePlayerService? _instance;

  VolumePlayerService._internal() {
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMessageDeleted);
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
  String currentPlayingFileName = '';
  Message? currentMessage;
  String currentPlayingFile = '';
  Map<String, double> playbackDuration = {};
  Uint8List? sendMessageBuffer;
  String playbackKey = '';
  String currentUsrName = '';

  VoidCallback? onAudioFinish;
  Function(PlaybackDisposition)? onAudioProgress;
  VoidCallback? onAudioPlayerStateChanged;

  StreamController<bool> _playerStateController = StreamController.broadcast();
  StreamController<double> _playerDurationController =
      StreamController.broadcast();

  // 音频设置初始化判断
  bool isOpenAudioSession = false;

  // 传感器监听
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  /// 只需要调一次
  Future<void> openPlayer({
    required VoidCallback onFinish,
    Function(PlaybackDisposition)? onProgress,
    VoidCallback? onPlayerStateChanged,
    AudioDevice? device,
  }) async {
    await stopPlayer();

    if (!isOpenAudioSession) {
      await _player.openAudioSession(
        focus: AudioFocus.requestFocusAndDuckOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: playbackDevice,
      );
      isOpenAudioSession = true;
    }

    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    _streamSubscriptions.add(
      proximityEvents!.listen((ProximityEvent event) async {
        if (event.getValue()) {
          switchToHeadphones();
        } else {
          if (playbackDevice == AudioDevice.earPiece) {
            switchToHeadphones();
          } else {
            switchToSpeaker();
          }
        }
      }),
    );

    await _player.setSubscriptionDuration(const Duration(milliseconds: 30));
    _startPlayer(
      onFinish: onFinish,
      onProgress: onProgress,
      onPlayerStateChanged: onPlayerStateChanged,
    );
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
  }) async {
    try {

      final user = await objectMgr.userMgr
          .loadUserById2(currentMessage?.send_id ?? 0);
      String newDisplayName = objectMgr.userMgr.getUserTitle(user);
      currentUsrName = newDisplayName;

      await _player.startPlayer(
          fromURI: currentPlayingFile,
          codec: Codec.pcm16WAV,
          whenFinished: () {
            stopPlayer();
            resetPlayer();
            //结束播放
            onFinish();
            onAudioFinish?.call();
          });

      await setAudioSession(device: playbackDevice);

      if (getPlaybackDuration(currentPlayingFileName) >= 0.0) {
        await seekTo(getPlaybackDuration(currentPlayingFileName).toInt());
      }

      _playerStateController.sink.add(_player.isPlaying);

      ////此处有内存泄露
      await _subscribeToProgressStream(onProgress);

      Future.delayed(const Duration(milliseconds: 10), () {
        onPlayerStateChanged?.call();
        onAudioPlayerStateChanged?.call();
      });
    } catch (err) {
      mypdebug('_startPlayer【播放错误】: $err');
    }
  }

  StreamSubscription<PlaybackDisposition>? _progressSubscription;
  Future<void> _subscribeToProgressStream(Function(PlaybackDisposition)? onProgress) async {
    // 取消旧的订阅（如果存在）
    _progressSubscription?.cancel();

    // 创建新的订阅
    _progressSubscription = _player.onProgress!.listen((PlaybackDisposition event) {
      // print("播放进度：${event.position.inMilliseconds}");
      playbackDuration[currentPlayingFileName] = event.position.inMilliseconds.toDouble();
      _playerDurationController.sink.add(event.position.inMilliseconds.toDouble());
      if (onProgress != null) {
        onProgress(event);
      }
      onAudioProgress?.call(event);
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
      mypdebug('stopPlayer====> 错误：$err');
    }
  }

  void resetPlayer() {
    isShowAudioPin.value = false;
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
    await _player.resumePlayer();
    _playerStateController.sink.add(_player.isPlaying);
  }

  Future<void> pausePlayer() async {
    await _player.pausePlayer();
    _playerStateController.sink.add(_player.isPlaying);
    event(this, keyVolumePlayerStatus, data: VolumePlayerServiceType.pause);
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
      mypdebug(e);
    }
  }

  Future<void> setAudioSession({
    AudioDevice device = AudioDevice.speaker,
  }) async {
    // playbackDevice = device;

    final session = await audioSession.AudioSession.instance;
    final audioDevices = await session.getDevices();
    bool isBluetooth = false;
    audioDevices.forEach((element) {
      if (element.type == audioSession.AudioDeviceType.bluetoothA2dp ||
          element.type == audioSession.AudioDeviceType.bluetoothSco ||
          element.type == audioSession.AudioDeviceType.bluetoothLe) {
        isBluetooth = true;
      }
    });

    if (isBluetooth && (device != AudioDevice.speaker)) {
      await switchToBluetooth();
    } else if (!isBluetooth && (device != AudioDevice.speaker)) {
      await switchToHeadphones();
    } else {
      await switchToSpeaker();
    }
  }

  resetState() {
    playbackDuration.clear();
    currentPlayingFileName = '';
    currentPlayingFile = '';
  }

  Future<bool> switchToSpeaker() async {
    if (Platform.isAndroid) {
      final audioManager = audioSession.AndroidAudioManager();
      await audioManager.setMode(audioSession.AndroidAudioHardwareMode.normal);
      await audioManager.stopBluetoothSco();
      await audioManager.setBluetoothScoOn(false);
      await audioManager.setSpeakerphoneOn(true);
    } else if (Platform.isIOS) {
      final audioManager = audioSession.AVAudioSession();
      await audioManager
          .setCategory(audioSession.AVAudioSessionCategory.playAndRecord);
      await audioManager.overrideOutputAudioPort(
        audioSession.AVAudioSessionPortOverride.speaker,
      );
    }
    return true;
  }

  Future<bool> switchToReceiver() async {
    if (Platform.isAndroid) {
      final audioManager = audioSession.AndroidAudioManager();
      audioManager
          .setMode(audioSession.AndroidAudioHardwareMode.inCommunication);
      audioManager.stopBluetoothSco();
      audioManager.setBluetoothScoOn(false);
      audioManager.setSpeakerphoneOn(false);
      return true;
    } else if (Platform.isIOS) {
      return await _switchToAnyIosPortIn({
        audioSession.AVAudioSessionPort.builtInReceiver,
        audioSession.AVAudioSessionPort.builtInMic,
      });
    }
    return false;
  }

  Future<bool> switchToHeadphones() async {
    if (Platform.isAndroid) {
      final audioManager = audioSession.AndroidAudioManager();
      await audioManager.setMode(audioSession.AndroidAudioHardwareMode.inCommunication);
      await audioManager.stopBluetoothSco();
      await audioManager.setBluetoothScoOn(false);
      await audioManager.setSpeakerphoneOn(false);
      return true;
    } else if (Platform.isIOS) {
      try {
        final audioManager = audioSession.AVAudioSession();
        await audioManager.setCategory(audioSession.AVAudioSessionCategory.playAndRecord);
        await audioManager.overrideOutputAudioPort(audioSession.AVAudioSessionPortOverride.none);
        await audioManager.setActive(true);

      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> switchToBluetooth() async {
    if (Platform.isAndroid) {
      final audioManager = audioSession.AndroidAudioManager();
      await audioManager
          .setMode(audioSession.AndroidAudioHardwareMode.inCommunication);
      await audioManager.startBluetoothSco();
      await audioManager.setBluetoothScoOn(true);
      return true;
    } else if (Platform.isIOS) {
      return await _switchToAnyIosPortIn({
        audioSession.AVAudioSessionPort.bluetoothLe,
        audioSession.AVAudioSessionPort.bluetoothHfp,
        audioSession.AVAudioSessionPort.bluetoothA2dp,
      });
    }
    return false;
  }

  Future<bool> _switchToAnyIosPortIn(
      Set<audioSession.AVAudioSessionPort> ports) async {
    final audioManager = audioSession.AVAudioSession();
    final description = await audioManager.currentRoute;
    description.outputs.forEach((element) {
      pdebug('check av description element: ${element.portName}');
    });
    if ((await audioManager.currentRoute)
        .outputs
        .any((r) => ports.contains(r.portType))) {
      return true;
    }
    for (var input in await audioManager.availableInputs) {
      if (ports.contains(input.portType)) {
        await audioManager.setPreferredInput(input);
      }
    }
    return false;
  }
}
