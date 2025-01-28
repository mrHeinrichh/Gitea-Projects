
// import 'package:tencent_trtc_cloud/trtc_cloud.dart';
// import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';

const int FocusSoundID = 101; //关注
const int FollowMsgSoundID = 102; //特别关注消息
const int NomalMsgSoundID = 103; //普通聊天消息
const int LessMoneySoundID = 104; //余额不足
const int LoveSpaceSoundID = 105; //情侣空间
const int MatchSoundID = 106; //语音匹配
const int MatchSuccessSoundID = 107; //语音匹配成功

/// 声音播放
class SoundPlayer {
  ///////////////////////////////////////////////////////////////////////////////
  /// 使用trtc
  ///////////////////////////////////////////////////////////////////////////////
  // static Map<String, String> _cacheFiles = {};
  // static Future<ByteData> _fetchAsset(String path) async {
  //   return await rootBundle.load(path);
  // }
  //
  // static Future<File> _fetchToMemory(String path) async {
  //   String filePath = "${(await getTemporaryDirectory()).path}/${path}";
  //   final file = File(filePath);
  //   if (file.existsSync()) {
  //     return file;
  //   }
  //   await file.create(recursive: true);
  //   return await file
  //       .writeAsBytes((await _fetchAsset(path)).buffer.asUint8List());
  // }
  //
  // static Future<String?> assetToLocalPath(String path) async {
  //   if (!_cacheFiles.containsKey(path)) {
  //     _cacheFiles[path] = (await _fetchToMemory(path)).path;
  //   }
  //   return _cacheFiles[path];
  // }
  //
  // static void clearCacheFile(String? path) {
  //   if (path == null) {
  //     _cacheFiles.clear();
  //   } else {
  //     _cacheFiles.remove(path);
  //   }
  // }
  //
  // static Future<void> changeToSpeaker() async {
  //   var trtcCloud = await TRTCCloud.sharedInstance();
  //   if (trtcCloud != null) {
  //     await trtcCloud
  //         .getDeviceManager()
  //         .setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
  //   }
  // }
  //
  // static Future<void> changeToReceiver() async {
  //   var trtcCloud = await TRTCCloud.sharedInstance();
  //   if (trtcCloud != null) {
  //     await trtcCloud
  //         .getDeviceManager()
  //         .setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
  //   }
  // }
  //
  // /////////////////// 通话相关 /////////////////////////
  // ///
  // ///
  // static SoundPlayer _callSoundPlayer = SoundPlayer();
  //
  // static bool _waitSoundPlay = false;
  //
  // // 响铃
  // static AudioMusicParam? _waitMusic;
  // // 挂断
  // static AudioMusicParam? _stopMusic;
  //
  // //通用
  // static Future<void> playGeneralSound(int soundID, {int loopCount = 0}) async {
  //   String? path =
  //       await SoundPlayer.assetToLocalPath(getMusicSoundPathWithId(soundID));
  //   if (path == null) {
  //     return;
  //   }
  //   await stopGeneralSound(soundID);
  //   AudioMusicParam _param = AudioMusicParam(
  //       path: path, id: soundID, loopCount: loopCount, isShortFile: true);
  //   await _callSoundPlayer.play(_param, TRTCCloudDef.TRTCSystemVolumeTypeVOIP);
  // }
  //
  // static Future<void> stopGeneralSound(int soundID) async {
  //   await _callSoundPlayer.stop(soundID);
  // }
  //
  // // 播放等待音乐
  // static Future<void> playCallWaitSound() async {
  //   if (_waitMusic == null) {
  //     String? path =
  //         await SoundPlayer.assetToLocalPath("assets/sound/wxyy.mp3");
  //     if (path == null) {
  //       return;
  //     }
  //     _waitMusic = AudioMusicParam(
  //         id: 9998, path: path, loopCount: 10, isShortFile: true);
  //   }
  //   await stopCallWaitSound();
  //   await _callSoundPlayer.play(
  //       _waitMusic!, TRTCCloudDef.TRTCSystemVolumeTypeVOIP);
  //   _waitSoundPlay = true;
  // }
  //
  // // 停止等待音乐
  // static Future<void> stopCallWaitSound() async {
  //   if (_waitSoundPlay && _waitMusic != null) {
  //     await _callSoundPlayer.stop(_waitMusic!.id);
  //   }
  //   _waitSoundPlay = false;
  // }
  //
  // //拒绝或挂断
  // static void playCallStopSound() async {
  //   const int soundID = 9999;
  //   if (_stopMusic == null) {
  //     String? path =
  //         await SoundPlayer.assetToLocalPath("assets/sound/wxjs.mp3");
  //     if (path == null) {
  //       return;
  //     }
  //     _stopMusic = AudioMusicParam(id: soundID, path: path);
  //   }
  //   await stopCallWaitSound();
  //   await Future.delayed(const Duration(milliseconds: 1000));
  //   await _callSoundPlayer.play(
  //       _stopMusic!, TRTCCloudDef.TRTCSystemVolumeTypeVOIP);
  //   var trtcCloud = await TRTCCloud.sharedInstance();
  //   if (trtcCloud == null) {
  //     return;
  //   }
  //   await Future.delayed(const Duration(seconds: 3));
  //   await _callSoundPlayer.stop(soundID);
  //   await trtcCloud
  //       .getDeviceManager()
  //       .setSystemVolumeType(TRTCCloudDef.TRTCSystemVolumeTypeMedia);
  // }
  //
  // // 正在播放的声音
  // List<int> _musics = [];
  //
  // Future<bool> play(AudioMusicParam musicParam, int? systemVolumeType) async {
  //   var trtcCloud = await TRTCCloud.sharedInstance();
  //   if (trtcCloud == null) {
  //     return false;
  //   }
  //   if (systemVolumeType != null) {
  //     await trtcCloud.getDeviceManager().setSystemVolumeType(systemVolumeType);
  //   }
  //   var value =
  //       await trtcCloud.getAudioEffectManager().startPlayMusic(musicParam) ??
  //           false;
  //   if (value) {
  //     _musics.add(musicParam.id);
  //   }
  //   return value;
  // }
  //
  // Future<void> stop(int? id) async {
  //   var trtcCloud = await TRTCCloud.sharedInstance();
  //   if (trtcCloud == null) {
  //     return;
  //   }
  //   if (id != null) {
  //     await trtcCloud.getAudioEffectManager().stopPlayMusic(id);
  //     _musics.remove(id);
  //   } else {
  //     for (var element in _musics) {
  //       await trtcCloud.getAudioEffectManager().stopPlayMusic(element);
  //     }
  //     _musics.clear();
  //   }
  // }
  //
  // static String getMusicSoundPathWithId(int soundID) {
  //   switch (soundID) {
  //     case FocusSoundID:
  //       return 'assets/sound/focus.mp3';
  //     case FollowMsgSoundID:
  //       return 'assets/sound/followed_msg.mp3';
  //     case NomalMsgSoundID:
  //       return 'assets/sound/nomal_msg.mp3';
  //     case LessMoneySoundID:
  //       return 'assets/sound/less_money.mp3';
  //     case LoveSpaceSoundID:
  //       return 'assets/sound/love_space.mp3';
  //     case MatchSoundID:
  //       return 'assets/sound/match.mp3';
  //     case MatchSuccessSoundID:
  //       return 'assets/sound/match_success.mp3';
  //     default:
  //       return '';
  //   }
  // }
}
