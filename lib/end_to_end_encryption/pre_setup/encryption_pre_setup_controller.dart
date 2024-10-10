import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';

class EncryptionPreSetupController extends GetxController{

  void navigateToEncryptionSetupPage() {
    // Get.ar
    Map<String, dynamic> args = {
      'type': EncryptionPasswordType.setup,
    };

    if (Get.arguments != null) {
      Map<dynamic, dynamic> cArgs = Get.arguments;
      if (cArgs['successCallback'] != null) {
        args['successCallback'] = cArgs['successCallback'];
      }
    }

    Get.toNamed(RouteName.encryptionSetupPage, arguments: args);
  }
}