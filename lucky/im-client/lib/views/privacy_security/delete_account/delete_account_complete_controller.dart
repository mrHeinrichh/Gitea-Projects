import 'package:get/get.dart';
import 'package:jxim_client/main.dart';

class DeleteAccountCompleteController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void clearData() {
    objectMgr.sharedRemoteDB.removeDB(objectMgr.userMgr.mainUser.uid);
    objectMgr.logoutClearData(true);
  }
}
