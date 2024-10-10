import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import 'package:jxim_client/utils/toast.dart';

class AppearanceController extends GetxController {
  bool isDarkMode = false;

  void updateDarkMode(bool value) {
    Toast.showToast(localized(homeToBeContinue));
  }
}
