import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:logger/logger.dart' show Level;
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart' as audio_session;

class VolumeRecordService {
  factory VolumeRecordService() => _getInstance();

  static VolumeRecordService get sharedInstance => _getInstance();

  static VolumeRecordService? _instance;

  VolumeRecordService._internal();

  static VolumeRecordService _getInstance() {
    _instance ??= VolumeRecordService._internal();
    return _instance!;
  }

  remove() {
    _instance = null;
  }

  StreamSubscription? _recordSubscription;
  final FlutterSoundRecorder _recorderModule =
      FlutterSoundRecorder(logLevel: Level.nothing);

  bool get isRecording => _recorderModule.isRecording;

  String recordPath = '';

  int maxLength = 60000;

  double getRandomDoubleInRange(double start, double end) {
    final random = Random();
    return start + (random.nextDouble() * (end - start));
  }

  //开始录音
  startRecorder({
    required Function(int recordSeconds, double? decibels) onStartCallBack,
    Function()? onTimeout,
  }) async {
    if (await Permission.microphone.isGranted) {
      if (_recorderModule.isRecording) {
        var stopSuccess = await stopRecord();
        if (!stopSuccess) {
          return;
        }
      }

      await _recorderModule.openAudioSession(
        focus: AudioFocus.requestFocusTransient,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeSpokenAudio,
        device: AudioDevice.speaker,
      );
      await _recorderModule.setSubscriptionDuration(
        const Duration(milliseconds: 50),
      ); //decibel faster.
      final appCacheRootPath = AppPath.appCacheRootPath;
      var time = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      recordPath = '$appCacheRootPath/record-$time${ext[Codec.pcm16WAV.index]}';
      await _recorderModule.startRecorder(
        toFile: recordPath,
        codec: Codec.pcm16WAV,
      );
      _recordSubscription = _recorderModule.onProgress!.listen(
        (event) async {
          var decibel = event.decibels ?? 0;
          if (Platform.isAndroid && decibel >= 40) {
            // to make android decibel more realistic
            decibel = (decibel - 40) * (110 / 30);
          }

          decibel = getRandomDoubleInRange(decibel - 15, decibel + 15);
          if (decibel < 10 || decibel.isNegative) {
            decibel = getRandomDoubleInRange(2, 10);
          }

          onStartCallBack(event.duration.inMilliseconds, decibel);
          if (event.duration.inMilliseconds >= maxLength) {
            await stopRecord();
            //停止录音
            if (onTimeout != null) {
              onTimeout();
            }
          }
        },
      );
    } else {
      Permission.microphone.request();
    }
  }

  //结束录音
  Future<bool> stopRecord() async {
    try {
      await _recorderModule.stopRecorder();
      cancelRecorderSubscriptions();
      releaseAudio();
      if (Platform.isIOS) {
        final audioManager = audio_session.AVAudioSession();
        await audioManager
            .setCategory(audio_session.AVAudioSessionCategory.ambient);
        audioManager.setActive(true);
      }
      return true;
    } catch (err) {
      releaseAudio();
      return false;
    }
  }

  Future<bool> notifyOthersDeactivation() async {
    final audioManager = audio_session.AVAudioSession();
    return await audioManager.setActive(false,
        avOptions: audio_session
            .AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation);
  }

  //取消录音
  cancelRecorderSubscriptions() {
    if (_recordSubscription != null) {
      _recordSubscription!.cancel();
      _recordSubscription = null;
    }
  }

  /// ================================= UTIL ===================================
  void pauseRecorder() async => await _recorderModule.pauseRecorder();

  void resumeRecorder() async => await _recorderModule.resumeRecorder();

  //释放播放器
  releaseAudio() async {
    try {
      await _recorderModule.closeAudioSession();
    } catch (e) {
      pdebug(e);
    }
  }
}
