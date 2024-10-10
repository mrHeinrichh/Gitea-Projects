import 'package:get/get.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';

class GeneralSettingsController extends GetxController {
  ///镜像前置摄像头
  final RxBool isMirrorFrontCamera = true.obs;

  @override
  void onInit() {
    super.onInit();
    initMirrorSetting();
  }

  initMirrorSetting() async {
    isMirrorFrontCamera.value = objectMgr.localStorageMgr
            .globalRead<bool>(LocalStorageMgr.MIRROR_FRONT_CAMERA) ??
        true;
  }

  onTapMirrorFrontCamera() async {
    isMirrorFrontCamera.value = !isMirrorFrontCamera.value;
    await objectMgr.localStorageMgr.globalWrite(
      LocalStorageMgr.MIRROR_FRONT_CAMERA,
      isMirrorFrontCamera.value,
    );
    pdebug(
      "current value is ${objectMgr.localStorageMgr.globalRead<bool>(LocalStorageMgr.MIRROR_FRONT_CAMERA)}",
    );
  }
}
