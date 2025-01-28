import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../utils/toast.dart';

class AppearanceController extends GetxController {
  bool isDarkMode = false;

  void updateDarkMode(bool value) {
    // isDarkMode = value;
    // if (isDarkMode) {
    //   objectMgr.skinMgr.updateUserDefaultSkin(ThemeType.darkMode);
    //   // Get.changeTheme(ThemeData.dark());
    // } else {
    //   objectMgr.skinMgr.updateUserDefaultSkin(ThemeType.lightMode);
    //   // Get.changeTheme(ThemeData.light());
    // }
    // update();
    Toast.showToast(localized(homeToBeContinue));
  }
}
