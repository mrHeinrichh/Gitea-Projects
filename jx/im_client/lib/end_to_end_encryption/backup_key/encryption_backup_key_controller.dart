import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';

class EncryptionBackupKeyController extends GetxController {
  EncryptionPasswordType? type;
  Function()? successCallback;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      if (Get.arguments["type"] != null) {
        type = Get.arguments["type"];
      }
      if (Get.arguments["successCallback"] != null) {
        successCallback = Get.arguments["successCallback"];
      }
    }
  }

  void navigateToPreSetupPage() {
    Map<String, dynamic> args = {};
    if (successCallback != null) {
      args['type'] = type;
    }
    if (successCallback != null) {
      args['successCallback'] = successCallback;
    }

    Get.toNamed(RouteName.encryptionPreSetupPage, arguments: args);
  }

  void getPrivateKeyQrCode() {
    Get.toNamed(RouteName.encryptionQrCodePage);
  }
}
