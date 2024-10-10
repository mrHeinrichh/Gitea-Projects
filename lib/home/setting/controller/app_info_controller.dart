import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/home/component/custom_divider.dart';

class AppInfoController extends GetxController {
  RxString currentVersion = "0.0.0".obs;
  RxString latestVersion = "0.0.0".obs;
  RxBool isSoftUpdateAvailable = false.obs;
  RxBool isForceUpdateAvailable = false.obs;
  Rx<PlatformDetail?> platformDetail = PlatformDetail().obs;

  @override
  void onInit() {
    super.onInit();
    getAppDetail();
  }

  Future<void> getAppDetail() async {
    currentVersion.value = await PlatformUtils.getAppVersion();

    platformDetail.value =
        await appVersionUtils.getAppVersionByRemote() ?? PlatformDetail();

    latestVersion.value = (platformDetail.value?.version != "")
        ? platformDetail.value?.version
        : await objectMgr.localStorageMgr
            .read(LocalStorageMgr.LATEST_APP_VERSION);

    isSoftUpdateAvailable.value =
        await appVersionUtils.softUpdate(platformDetail: platformDetail.value);
  }

  Future<void> softUpdateVersionDialogPopUp(BuildContext context) async {
    isSoftUpdateAvailable.value = await appVersionUtils.softUpdate();

    if (isSoftUpdateAvailable.value) {
      appVersionUtils.enableDialog = true;
      if (Get.isRegistered<HomeController>()) {
        HomeController controller = Get.find<HomeController>();
        controller.showUpdateAlert(context);
      }
    } else {
      Toast.showToast(localized(yourAppVersionIsUpToDate));
    }
  }

  Future<void> redirectToUpdateLink(
      BuildContext context, PlatformDetail? data) async {
    appVersionUtils.openDownloadLink(context, data);
  }

  void test(BuildContext context) {}

  Future<void> getCurrentVersionDescription(BuildContext context) async {
    final data = await Version().getAppVersionInfo();

    Toast.showBottomSheet(
      context: context,
      container: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 28.0,
          horizontal: 24.0,
        ),
        decoration: const BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
        ),
        child: Wrap(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localized(current),
                  style: jxTextStyle.textStyle14(color: colorTextSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  localized(versionWithParam, params: [(currentVersion.value)]),
                  style: jxTextStyle.textStyle24(),
                ),
                const SizedBox(height: 16),
                const CustomDivider(),
                const SizedBox(height: 16),
                Text(
                  localized(releaseDate),
                  style: jxTextStyle.textStyle14(color: colorTextSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  FormatTime.getDDMMYYYY(data.createdAt, isShowYear: true),
                  style: jxTextStyle.textStyle16(),
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: data.description != "",
                  child: SizedBox(
                    height: 150.w,
                    child: SingleChildScrollView(
                      child: Text(
                        data.description,
                        style: jxTextStyle.textStyle12(
                          color: colorTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
