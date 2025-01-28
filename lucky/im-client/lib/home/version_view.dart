import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class VersionView extends GetView<HomeController> {
  HomeController? _homeController;

  VersionView({super.key}) {
    _homeController = Get.find<HomeController>();
  }

  @override
  Widget build(BuildContext context) {
    /// 版本号更新提示
    return Obx(
      () => Visibility(
        visible: controller.showVersionBar(),
        child: Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom,
          child: Container(
            height: 48,
            margin:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xD1121212).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8), // Set border radius here
            ),
            child: Row(
              children: [
                leadingIcon(),
                titleWidget(),
                updateButton(context),
                dismissButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget leadingIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 10.0),
      child:SvgPicture.asset(
        'assets/svgs/install-icon.svg',
        width: 24,
        height: 24,
        color: Colors.white,
      ),
      // child: _homeController!.apkDownloadProgress.value == 0.0 ||
      //         _homeController!.apkDownloadProgress.value == 1
      //     ? SvgPicture.asset(
      //         'assets/svgs/install-icon.svg',
      //         width: 24,
      //         height: 24,
      //         color: Colors.white,
      //       )
      //     : const DotLoadingView(size: 12),
    );
  }

  Widget titleWidget() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _progressNumView(),
          Visibility(
            visible: controller.isRecommendUninstall.value,
            child: ImText(
              localized(highlyRecommendToUninstall),
              color: JXColors.secondaryTextWhite,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget updateButton(BuildContext context) {
    return Visibility(
      // visible: _homeController!.apkDownloadProgress.value == 0.0 ||
      //     _homeController!.apkDownloadProgress.value == 1,
      visible: true,
      child: GestureDetector(
        onTap: () {
          controller.showUpdateAlert(context);
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
          child: ImText(
            localized(updates),
            color: JXColors.toastButtonColor,
          ),
        ),
      ),
    );
  }

  Widget dismissButton() {
    return Visibility(
      // visible: _homeController!.apkDownloadProgress.value == 0.0 ||
      //     _homeController!.apkDownloadProgress.value == 1,
      visible: true,
      child: GestureDetector(
        onTap: () {
          controller.disableSoftUpdateNotification();
        },
        behavior: HitTestBehavior.translucent,
        child: const Padding(
          padding: const EdgeInsets.only(
              top: 12.0, bottom: 12.0, left: 6.0, right: 12.0),
          child: const Icon(
            Icons.close,
            size: 24.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _progressNumView() {
    final progress = _homeController!.apkDownloadProgress.value * 100;
    return ImText(
      // progress > 0 && progress < 100
      //     ? localized(appUpdating, params: ["${progress.toInt()}"])
      //     : localized(newVersionIsAvailableNow),
      localized(newVersionIsAvailableNow),
      color: ImColor.white,
    );
  }
}
