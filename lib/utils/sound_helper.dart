import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class SoundHelper {

  static final SoundHelper _instance = SoundHelper._internal();
  factory SoundHelper() {
    return _instance;
  }

  SoundHelper._internal() {
    init();
  }

  init() async {

  }

  Future<bool> canPlaySendMessage() async {
    bool status = objectMgr.localStorageMgr.read(LocalStorageMgr.MESSAGE_SOUND_NOTIFICATION) ?? true;
    
    if(!status){
      return false;
    }

    if(objectMgr.callMgr.currentState.value != CallState.Idle){
      return false;
    }

    if(objectMgr.tencentVideoMgr.isAnyControllerPlaying()){
      return false;
    }

    if(VolumePlayerService.sharedInstance.isPlaying){
      return false;
    }

    final ringerStatus = await SoundMode.ringerModeStatus;
    final isMute = [RingerModeStatus.silent, RingerModeStatus.vibrate]
        .contains(ringerStatus);

    return isMute == false;
  }


}