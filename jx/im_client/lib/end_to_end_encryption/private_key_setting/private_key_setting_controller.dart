import 'package:get/get.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';

class PrivateKeySettingController extends GetxController {
  RxString hasEncryptedPrivateKey = ''.obs;

  @override
  void onInit() {
    super.onInit();
    objectMgr.encryptionMgr
        .on(EncryptionMgr.eventResetPrivateKeyPW, _updatePassword);
    objectMgr.encryptionMgr.on(EncryptionMgr.eventResetPairKey, _resetPairKey);
    hasEncryptedPrivateKey.value =
        objectMgr.encryptionMgr.hasEncryptedPrivateKey;
  }

  @override
  void onClose() {
    objectMgr.encryptionMgr
        .off(EncryptionMgr.eventResetPrivateKeyPW, _updatePassword);
    objectMgr.encryptionMgr.off(EncryptionMgr.eventResetPairKey, _resetPairKey);
    super.onClose();
  }

  void _updatePassword(sender, type, data) {
    if (data is String) {
      hasEncryptedPrivateKey.value = data;
    }
  }

  void _resetPairKey(sender, type, data) {
    hasEncryptedPrivateKey.value =
        objectMgr.encryptionMgr.hasEncryptedPrivateKey;
  }

  void getPrivateKeyQrCode() {
    Get.toNamed(RouteName.encryptionQrCodePage);
  }

  void changeOrSetupPassword() {
    if (hasEncryptedPrivateKey.value == '') {
      Get.toNamed(RouteName.encryptionPreSetupPage);
    } else {
      objectMgr.encryptionMgr
          .navigateEncryptionPasswordPage(isFromChangePw: true);
    }
  }

  void resetPassword() {
    objectMgr.encryptionMgr.resetPrivateKey();
    // Get.toNamed(RouteName.encryptionForgetPwPage);
  }
}
