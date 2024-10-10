import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/api/sound.dart';
import 'package:jxim_client/data/db_sound.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:logger/logger.dart' show Level;
import 'package:audio_session/audio_session.dart' as audio_session;

class SoundMgr {
  late SharedRemoteDB _sharedDB;
  List<SoundData> soundTrackList = [];
  SoundData? incomingCallSound;
  SoundData? outgoingCallSound;
  SoundData? notificationSound;
  SoundData? sendMessageSound;
  SoundData? groupNotificationSound;
  FlutterSoundPlayer player = FlutterSoundPlayer(logLevel: Level.nothing);

  Future<void> init() async {
    _sharedDB = objectMgr.sharedRemoteDB;

    await getSoundTrackList();
  }

  Future<void> getSoundTrackList() async {
    final data = await objectMgr.localDB.loadSoundTrackList();
    soundTrackList = data?.map((e) => SoundData.fromJson(e)).toList() ?? [];

    if (soundTrackList.isEmpty) {
      await getSoundTrackListRemote();
    } else {
      setSoundTrack(soundTrackList);
    }
  }

  Future<void> getSoundTrackListRemote() async {
    try {
      List<SoundData> res = await getSoundList();
      List<SoundData> soundList = [];

      /// 1.后端返回声音列表：
      if (res.isNotEmpty) {
        soundTrackList = res;

        Map<int, String?> map = {};

        /// 2.下载声音文件：
        for (final item in res) {
          map[item.id!] = await _downloadSoundFile(
            item.filePath ?? "",
          );
        }

        /// 3.确保Document里存了声音文件：
        map.forEach((key, value) {
          if (value != null) {
            final SoundData? model =
                res.firstWhereOrNull((element) => element.id == key);
            if (model != null) {
              soundList.add(model);
            }
          }
        });
      }

      /// 4.把声音存进database：
      if (soundList.isNotEmpty) {
        await objectMgr.localDB.clearSoundTable();

        _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBSound.tableName,
            soundList.map((e) => e.toJson()).toList(),
          ),
          save: true,
          notify: false,
        );
      }

      await setSoundTrack(soundList);
    } catch (e) {
      final data = await objectMgr.localDB.loadSoundTrackList();
      soundTrackList = data?.map((e) => SoundData.fromJson(e)).toList() ?? [];
      await setSoundTrack(soundTrackList);
    }
  }

  Future<List<SoundData>> getSoundTrackListLocalByType(int typ) async {
    if (soundTrackList.isEmpty) {
      await getSoundTrackList();
    }

    if (typ == SoundTrackType.SoundTypeOutgoingCall.value) {
      typ = SoundTrackType.SoundTypeIncomingCall.value;
    } else if (typ == SoundTrackType.SoundTypeGroupNotification.value) {
      typ = SoundTrackType.SoundTypeNotification.value;
    }

    List<SoundData> dataList = [];
    if (soundTrackList.isNotEmpty) {
      dataList = soundTrackList.where((element) => element.typ == typ).toList();
    } else {
      final data = await objectMgr.localDB.loadSoundTrackList();
      soundTrackList = data?.map((e) => SoundData.fromJson(e)).toList() ?? [];
      dataList = soundTrackList.where((element) => element.typ == typ).toList();
    }

    setSoundTrack(soundTrackList);
    return dataList;
  }

  Future<String?> _downloadSoundFile(
    String downloadUrl, {
    Duration timeout = const Duration(seconds: 60),
    int priority = 2, // 任务优先级
  }) {
    return downloadMgr.downloadFile(
      downloadUrl,
      timeout: timeout,
      priority: priority,
    );
  }

  Future<void> setSoundTrack(List<SoundData> soundList) async {
    User? user = objectMgr.userMgr.getUserById(objectMgr.userMgr.mainUser.uid);

    /// 1. 后端返回im/user声音设置
    if (connectivityMgr.connectivityResult != ConnectivityResult.none) {
      try {
        NotificationSetting? data =
            await SettingServices().getNotificationSetting();
        user?.incomingSoundId = data.incomingSoundId;
        user?.outgoingSoundId = data.outgoingSoundId;
        user?.notificationSoundId = data.notificationSoundId;
        user?.sendMessageSoundId = data.sendMessageSoundId;
        user?.groupNotificationSoundId = data.groupNotificationSoundId;
      } catch (e) {
        pdebug(e.toString());
      }
    }

    if (user != null) {
      incomingCallSound = getSoundData(
        SoundTrackType.SoundTypeIncomingCall.value,
        user.incomingSoundId,
      );
      outgoingCallSound = getSoundData(
        SoundTrackType.SoundTypeOutgoingCall.value,
        user.outgoingSoundId,
      );
      notificationSound = getSoundData(
        SoundTrackType.SoundTypeNotification.value,
        user.notificationSoundId,
      );
      sendMessageSound = getSoundData(
        SoundTrackType.SoundTypeSendMessage.value,
        user.sendMessageSoundId,
      );
      groupNotificationSound = getSoundData(
        SoundTrackType.SoundTypeGroupNotification.value,
        user.groupNotificationSoundId,
      );
      objectMgr.userMgr.onUserChanged([user], notify: false);
    }
  }

  SoundData? getSoundData(int type, int id) {
    SoundData? soundData;
    if (id == 0) {
      if (type == SoundTrackType.SoundTypeIncomingCall.value) {
        soundData = soundTrackList.firstWhereOrNull(
          (element) =>
              element.typ == SoundTrackType.SoundTypeIncomingCall.value &&
              element.isDefault == 1,
        );
      } else if (type == SoundTrackType.SoundTypeOutgoingCall.value) {
        soundData = soundTrackList.firstWhereOrNull(
          (element) =>
              element.typ == SoundTrackType.SoundTypeIncomingCall.value &&
              element.isDefault == 1,
        );
      } else if (type == SoundTrackType.SoundTypeNotification.value) {
        soundData = soundTrackList.firstWhereOrNull(
          (element) =>
              element.typ == SoundTrackType.SoundTypeNotification.value &&
              element.isDefault == 1,
        );
      } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
        soundData = soundTrackList.firstWhereOrNull(
          (element) =>
              element.typ == SoundTrackType.SoundTypeSendMessage.value &&
              element.isDefault == 1,
        );
      } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
        soundData = soundTrackList.firstWhereOrNull(
          (element) =>
              element.typ == SoundTrackType.SoundTypeNotification.value &&
              element.isDefault == 1,
        );
      }
    } else {
      soundData =
          soundTrackList.firstWhereOrNull((element) => element.id == id);
      soundData ??= soundTrackList.firstWhereOrNull(
        (element) => element.typ == type && element.isDefault == 1,
      );
    }
    return soundData;
  }

  Future<void> saveSoundData(int type, int soundId) async {
    NotificationSetting data = await SettingServices().getNotificationSetting();
    User? user = objectMgr.userMgr.getUserById(data.id);
    user?.incomingSoundId = data.incomingSoundId;
    user?.outgoingSoundId = data.outgoingSoundId;
    user?.notificationSoundId = data.notificationSoundId;
    user?.sendMessageSoundId = data.sendMessageSoundId;
    user?.groupNotificationSoundId = data.groupNotificationSoundId;

    if (user != null) {
      objectMgr.userMgr.onUserChanged([user], notify: false);

      if (type == SoundTrackType.SoundTypeIncomingCall.value) {
        incomingCallSound = getSoundData(type, data.incomingSoundId);
      } else if (type == SoundTrackType.SoundTypeOutgoingCall.value) {
        outgoingCallSound = getSoundData(type, data.outgoingSoundId);
      } else if (type == SoundTrackType.SoundTypeNotification.value) {
        notificationSound = getSoundData(type, data.notificationSoundId);
      } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
        sendMessageSound = getSoundData(type, data.sendMessageSoundId);
      } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
        groupNotificationSound =
            getSoundData(type, data.groupNotificationSoundId);
      }
    }
  }

  /// 播放最终音效
  Future<void> playSound(int type) async {
    if (objectMgr.tencentVideoMgr.isAnyControllerPlaying()) {
      return;
    }
    String soundPath = "";
    if (type == SoundTrackType.SoundTypeIncomingCall.value) {
      /// to do
    } else if (type == SoundTrackType.SoundTypeOutgoingCall.value) {
      /// to do
    } else if (type == SoundTrackType.SoundTypeNotification.value) {
      soundPath =
          "${downloadMgr.appDocumentRootPath}/${notificationSound?.filePath}";
    } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
      soundPath =
          "${downloadMgr.appDocumentRootPath}/${sendMessageSound?.filePath}";
    } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
      soundPath =
          "${downloadMgr.appDocumentRootPath}/${groupNotificationSound?.filePath}";
    }
    playAudioPlayer(soundPath);
  }

  /// 播放音效
  Future<void> playSelectedSound(SoundData soundData) async {
    String soundPath =
        "${downloadMgr.appDocumentRootPath}/${soundData.filePath}";
    playAudioPlayer(soundPath);
  }

  Future<void> playAudioPlayer(String soundPath) async {
    bool fileExists = await File(soundPath).exists();

    if (fileExists) {
      await player.openAudioSession(
        focus: AudioFocus.requestFocusAndDuckOthers,
        category: SessionCategory.ambient,
        mode: SessionMode.modeDefault,
      );

      if (Platform.isIOS) {
        try {
          final audioManager = audio_session.AVAudioSession();
          if (await audio_session.AVAudioSession().category !=
              audio_session.AVAudioSessionCategory.ambient) {
            await audioManager
                .setCategory(audio_session.AVAudioSessionCategory.ambient);
            audioManager.setActive(true);
          }
        } catch (e) {
          rethrow;
        }
      }

      await player.startPlayer(
        fromURI: soundPath,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          // stopAndReleasePlayer();
        },
      );
    } else {
      // Toast.showToast("无法播放声音");
    }
  }

  // Future<void> playFromAssets(String sound) async {
  //   // Load the sound asset
  //   ByteData bytes = await rootBundle.load('assets/sound/$sound.mp3');
  //   Uint8List soundData = bytes.buffer.asUint8List();
  //
  //   // Play the sound
  //   await player?.startPlayer(
  //     fromDataBuffer: soundData,
  //     codec: Codec.mp3, // or appropriate codec
  //     whenFinished: () {
  //       pdebug('Playback finished');
  //     },
  //   );
  // }
}
