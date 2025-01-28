import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:permission_handler/permission_handler.dart';

class EncryptionVerificationController extends GetxController {
  RxString encPrivateKey = ''.obs;
  RxBool hasBack = true.obs;
  Function()? successCallback;

  @override
  void onInit() {
    super.onInit();
    objectMgr.encryptionMgr.on(EncryptionMgr.eventResetPairKey, _resetPairKey);

    if (Get.arguments != null) {
      hasBack.value = Get.arguments["hasBack"] ?? true;
      successCallback = Get.arguments["successCallback"];
    }

    encPrivateKey.value = objectMgr.encryptionMgr.hasEncryptedPrivateKey;
    if (encPrivateKey.value.isEmpty) {
      getCipherKeyByRemote();
    }
  }

  @override
  void onClose() {
    objectMgr.encryptionMgr.off(EncryptionMgr.eventResetPairKey, _resetPairKey);
    super.onClose();
  }

  Future<void> getCipherKeyByRemote() async {
    try {
      CipherKey data = await getCipherMyKey();
      if (data != null) {
        encPrivateKey.value = data.encPrivate ?? '';
        objectMgr.encryptionMgr.hasEncryptedPrivateKey = data.encPrivate ?? '';
        objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.BE_ENCRYPTED_KEY, encPrivateKey.value);
      }
    } catch (e) {
      String? bePrivateKey =
          objectMgr.localStorageMgr.read(LocalStorageMgr.BE_ENCRYPTED_KEY);
      if (notBlank(bePrivateKey)) {
        encPrivateKey.value = bePrivateKey!;
      } else {
        encPrivateKey.value = objectMgr.encryptionMgr.hasEncryptedPrivateKey;
      }
    }
  }

  void _resetPairKey(sender, type, data) {
    encPrivateKey.value = objectMgr.encryptionMgr.encryptionPrivateKey;
    Get.close(1);
  }

  void navigateToPasswordPage() {
    if (encPrivateKey.value != '') {
      objectMgr.encryptionMgr.navigateEncryptionPasswordPage(
          isFromChangePw: false, successCallback: successCallback);
    }
  }

  void forgetPassword() {
    Get.toNamed(RouteName.encryptionForgetPwPage);
  }

  Future<void> scanQrCode() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;

    Map<String, dynamic> args = {'type': ScanQrCodeType.encryption};
    if (successCallback != null) args['successCallback'] = successCallback;
    Get.toNamed(RouteName.qrCodeScanner, arguments: args);
  }

  void onClickSkip() {
    showCustomBottomAlertDialog(
      Get.context!,
      subtitle: localized(areYouSureYouWantToSkipKeyVerification),
      items: [
        CustomBottomAlertItem(
          text: localized(buttonConfirm),
          textColor: colorRed,
          onClick: () {
            objectMgr.encryptionMgr.updateSkipRecover();
            Get.close(1);
          },
        ),
      ],
    );
  }

  void resetPrivateKey() {
    objectMgr.encryptionMgr.resetPrivateKey();
  }
}
