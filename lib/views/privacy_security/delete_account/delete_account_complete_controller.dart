import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class DeleteAccountCompleteController extends GetxController {


  void clearData() {
    objectMgr.sharedRemoteDB.removeDB(objectMgr.userMgr.mainUser.uid);
    objectMgr.logoutClearData(true);
  }
}
