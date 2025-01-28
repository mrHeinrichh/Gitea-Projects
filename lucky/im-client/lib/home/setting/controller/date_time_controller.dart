import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_date_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class DateTimeController extends GetxController {
  static const timeType = 1;
  static const dateType = 2;
  int currentDateTime = 0;
  RxString timeFormat = "".obs;
  RxString dateFormat = "".obs;
  String timeFormatFromLs = "";
  String dateFormatFromLs = "";

  @override
  void onInit() {
    super.onInit();
    currentDateTime = DateTime.now().millisecondsSinceEpoch;

    if (objectMgr.localStorageMgr.read(LocalStorageMgr.TIME_FORMAT) == null) {
      timeFormat.value = DateTimeStyle.twentyFourFormat.value;
      changeFormat(type: timeType);
    } else {
      timeFormat.value = objectMgr.localStorageMgr.read(LocalStorageMgr.TIME_FORMAT);
    }

    if (objectMgr.localStorageMgr.read(LocalStorageMgr.DATE_FORMAT) == null) {
      dateFormat.value = DateTimeStyle.ddmmyyyySlash.value;
      changeFormat(type: dateType);
    } else {
      dateFormat.value = objectMgr.localStorageMgr.read(LocalStorageMgr.DATE_FORMAT);
    }

    timeFormatFromLs = timeFormat.value;
    dateFormatFromLs = dateFormat.value;
  }

  @override
  void onClose() {
    super.onClose();
  }

  setTimeFormat(String format) {
    timeFormat.value = format;
  }

  setDateFormat(String format) {
    dateFormat.value = format;
  }

  changeFormat({int? type}){
    if (type == timeType){
      objectMgr.localStorageMgr.write(LocalStorageMgr.TIME_FORMAT, timeFormat.value);
    } else if (type == dateType){
      objectMgr.localStorageMgr.write(LocalStorageMgr.DATE_FORMAT, dateFormat.value);
    } else {
      objectMgr.localStorageMgr.write(LocalStorageMgr.TIME_FORMAT, timeFormat.value);
      objectMgr.localStorageMgr.write(LocalStorageMgr.DATE_FORMAT, dateFormat.value);
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(dateAndTimeFormatUpdated), icon: ImBottomNotifType.success);
      Get.close(1);
    }
  }
}
