import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
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
      if (Get.arguments["encPrivateKey"] != null) {
        encPrivateKey.value = Get.arguments["encPrivateKey"];
      }
      hasBack.value = Get.arguments["hasBack"] ?? true;
      successCallback = Get.arguments["successCallback"];
    }
  }

  @override
  void onClose() {
    objectMgr.encryptionMgr.off(EncryptionMgr.eventResetPairKey, _resetPairKey);
    super.onClose();
  }

  void _resetPairKey(sender, type, data) {
    encPrivateKey.value = objectMgr.encryptionMgr.encryptionPrivateKey;
    Get.close(1);
  }

  void navigateToPasswordPage() {
    if (encPrivateKey.value != '') {
      objectMgr.encryptionMgr
          .navigateEncryptionPasswordPage(isFromChangePw: false, successCallback: successCallback);
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

    final PermissionStatus status = await Permission.camera.status;
    Map<String, dynamic> args = {
      'type': ScanQrCodeType.encryption,
    };

    if (successCallback != null) {
      args['successCallback'] = successCallback;
    }

    if (status.isGranted) {
      Get.toNamed(RouteName.qrCodeScanner, arguments: args);
    } else {
      final bool rationale = await Permission.camera.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied) {
        openSettingPopup(Permissions().getPermissionName(Permission.camera));
      } else {
        final PermissionStatus status = await Permission.camera.request();
        if (status.isGranted) {
          Get.toNamed(RouteName.qrCodeScanner, arguments: args);
        }
        if (status.isPermanentlyDenied) {
          openSettingPopup(Permissions().getPermissionName(Permission.camera));
        }
      }
    }
  }

  void onClickSkip() {
    showCustomBottomAlertDialog(
      Get.context!,
      subtitle: localized(areYouSureYouWantToSkipKeyVerification),
      items: [
        CustomBottomAlertItem(
          text: localized(buttonConfirm),
          textColor: colorRed,
          onClick: () => Get.close(1),
        ),
      ],
    );
  }

  void resetPrivateKey() {
    objectMgr.encryptionMgr.resetPrivateKey();
  }
}
