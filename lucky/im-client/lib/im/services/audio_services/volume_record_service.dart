import 'dart:async';
import 'dart:io';

import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:logger/logger.dart' show Level;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VolumeRecordService {
  factory VolumeRecordService() => _getInstance();

  static VolumeRecordService get sharedInstance => _getInstance();

  static VolumeRecordService? _instance;

  VolumeRecordService._internal() {}

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

      _recorderModule.openAudioSession(
          focus: AudioFocus.requestFocusTransient,
          category: SessionCategory.playAndRecord,
          mode: SessionMode.modeSpokenAudio,
          device: AudioDevice.speaker);
      await _recorderModule
          .setSubscriptionDuration(const Duration(milliseconds: 275));

      Directory tempDir = await getTemporaryDirectory();
      var time = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      recordPath = '${tempDir.path}/record-$time${ext[Codec.pcm16WAV.index]}';
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
      return true;
    } catch (err) {
      return false;
    }
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
      mypdebug(e);
    }
  }
}
