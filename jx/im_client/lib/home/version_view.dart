import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

const int VERSION = 1;
const int ENC_BACK_UP = 2;

class VersionView extends GetView<HomeController> {
  const VersionView({super.key});

  @override
  Widget build(BuildContext context) {
    /// 版本号更新提示

    return Obx(() {
      if (controller.checkIsSearchMode()) {
        return const SizedBox();
      } else if (controller.encryptionToastType.value !=
          EncryptionPanelType.none) {
        return Visibility(
          visible:
              controller.pageIndex.value == HomePageTabIndex.chatView.value,
          child: barContainer(
            child: encryptionBackupBar(ENC_BACK_UP),
          ),
        );
      } else {
        return Visibility(
          visible: controller.showVersionBar(),
          child: barContainer(
            child: versionBar(context, VERSION),
          ),
        );
      }
    });
  }

  Widget barContainer({required Widget child}) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorOverlay82,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }

  Widget encryptionBackupBar(int type) {
    String title = '';
    String buttonText = '';
    if (controller.encryptionToastType.value == EncryptionPanelType.backup) {
      title = localized(keyIsNotBackup);
      buttonText = localized(chatToggleSetNow);
    } else if (controller.encryptionToastType.value ==
        EncryptionPanelType.recover) {
      title = localized(keyIsNotRecovery);
      buttonText = localized(chatRecoverNow);
    } else if (controller.encryptionToastType.value ==
        EncryptionPanelType.recoverKick) {
      title = localized(keyExpiredForRecovery);
      buttonText = localized(chatRecoverNow);
    }

    return Row(
      children: [
        leadingIcon(type),
        Expanded(
          child: Text(
            title,
            style: jxTextStyle.normalText(color: colorWhite),
          ),
        ),
        CustomTextButton(
          buttonText,
          color: themeSecondaryColor,
          fontSize: MFontSize.size14.value,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          onClick: () => objectMgr.encryptionMgr
              .toastNavigatePage(controller.encryptionToastType.value),
        ),
      ],
    );
  }

  Widget versionBar(BuildContext context, int type) {
    return Row(
      children: [
        leadingIcon(type),
        titleWidget(),
        updateButton(context),
        dismissButton(),
      ],
    );
  }

  Widget leadingIcon(int type) {
    String icon = 'assets/svgs/informationIcon.svg';

    switch (type) {
      case VERSION:
        icon = 'assets/svgs/install-icon.svg';
        break;

      case ENC_BACK_UP:
        icon = 'assets/svgs/informationIcon.svg';
        break;
    }

    return CustomImage(
      icon,
      size: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: colorWhite,
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
      style: jxTextStyle.normalText(color: colorWhite),
    );
  }
}
