import 'package:get/get.dart';
import 'package:jxim_client/utils/format_time.dart';

class PasscodeBlockController extends GetxController {
  String expiryTime = "";

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      if (Get.arguments['expiryTime'] != null) {
        int expiryTimeStamp = Get.arguments['expiryTime'] ?? 0;
        getExpiryTime(expiryTimeStamp);
      }
    }
  }

  void getExpiryTime(int expiryTimeStamp) {
    expiryTime = FormatTime.chartTime(
      expiryTimeStamp,
      false,
      todayShowTime: false,
    );
  }
}
