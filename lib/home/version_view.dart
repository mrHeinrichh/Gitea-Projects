import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class VersionView extends GetView<HomeController> {
  const VersionView({super.key});

  @override
  Widget build(BuildContext context) {
    /// 版本号更新提示
    return Obx(
      () => Visibility(
        visible: controller.showVersionBar(),
        child: Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorTextPrimary.withOpacity(0.82),
              borderRadius: BorderRadius.circular(8),
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
    return const CustomImage(
      'assets/svgs/install-icon.svg',
      size: 24,
      padding: EdgeInsets.symmetric(horizontal: 12),
      color: colorWhite,
    );
    // _homeController!.apkDownloadProgress.value == 0.0 ||
    //         _homeController!.apkDownloadProgress.value == 1
    //     ? SvgPicture.asset(
    //         'assets/svgs/install-icon.svg',
    //         width: 24,
    //         height: 24,
    //         color: Colors.white,
    //       )
    //     : const DotLoadingView(size: 12),
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
            child: Text(
              localized(highlyRecommendToUninstall),
              style:
                  jxTextStyle.textStyle14(color: colorWhite.withOpacity(0.6)),
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
      child: CustomTextButton(
        localized(updates),
        color: themeSecondaryColor,
        fontSize: MFontSize.size14.value,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        onClick: () async => await controller.showUpdateAlert(context),
      ),
    );
  }

  Widget dismissButton() {
    return Visibility(
      // visible: _homeController!.apkDownloadProgress.value == 0.0 ||
      //     _homeController!.apkDownloadProgress.value == 1,
      visible: true,
      child: CustomImage(
        'assets/svgs/close_icon.svg',
        size: 24,
        color: colorWhite,
        padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
        onClick: controller.disableSoftUpdateNotification,
      ),
    );
  }

  Widget _progressNumView() {
    return Text(
      localized(newVersionIsAvailableNow),
      style: jxTextStyle.textStyle14(color: colorWhite),
    );
  }
}
