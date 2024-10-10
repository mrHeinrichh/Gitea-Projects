
import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/managers/interface.dart';

class VideoVolumeManager extends EventDispatcher implements MgrInterface {
  VideoVolumeManager._() {
    init();
  }

  static VideoVolumeManager get _instance => VideoVolumeManager._();
  static VideoVolumeManager get instance => _instance;

  limitVideoVolume() async {
    return; 
    // double volume = await VolumeController().getVolume();
    // print("test volume - " + volume.toString());
    // if (volume > 0.7) {
    //   print("abcde");
    //   VolumeController().setVolume(0.7);
    // }

  }

  @override
  Future<void> init() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> register() async {}

  @override
  Future<void> reloadData() async {}
}
