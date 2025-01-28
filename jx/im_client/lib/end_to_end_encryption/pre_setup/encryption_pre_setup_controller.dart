import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';

class EncryptionPreSetupController extends GetxController {
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

  void navigateToEncryptionSetupPage() {
    Map<String, dynamic> args = {};
    args['type'] = type ?? EncryptionPasswordType.setup;

    if (successCallback != null) {
      args['successCallback'] = successCallback;
    }

    Get.toNamed(RouteName.encryptionSetupPage, arguments: args);
  }
}
