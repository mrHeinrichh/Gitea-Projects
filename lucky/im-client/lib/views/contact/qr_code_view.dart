import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/components/download_qr_name_card.dart';
import 'package:jxim_client/views/contact/components/name_card_qr.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../home/setting/setting_controller.dart';
import '../../managers/call_mgr.dart';
import '../../utils/color.dart';
import '../../utils/toast.dart';
import '../component/new_appbar.dart';

class QRCodeView extends GetView<QRCodeViewController> {
  const QRCodeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : const PrimaryAppBar(
              bgColor: Colors.transparent,
              elevation: 0.0,
            ),
      body: Obx(
        () => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: controller.isShowNameCard.value
                  ? [const Color(0xFFF6FCFF), const Color(0xFFC1E8F9)]
                  : [const Color(0xFFB9FFF5), const Color(0xFF91C2F3)],
            ),
            image: const DecorationImage(
              image: const AssetImage('assets/images/qr_code_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              desktopAppBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).viewPadding.top +
                          kToolbarHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              child: Container(
                                width:MediaQuery.of(context).size.width *
                                    (objectMgr.loginMgr.isDesktop ? 0.4 : 0.8),
                                padding: const EdgeInsets.only(
                                  top: 48,
                                  bottom: 24,
                                  left: 24,
                                  right: 24,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: JXColors.bgTertiaryColor,
                                    // Border color
                                    width: 1.0, // Border width
                                  ),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (controller
                                        .user.username.isNotEmpty) ...[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16.0),
                                        child: Text(
                                          "@${controller.user.username}",
                                          style: jxTextStyle.textStyleBold24(
                                              fontWeight: MFontWeight.bold5.value),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    controller.isShowNameCard.value
                                        ? NameCardQr(
                                            data: controller.nameCardData.value)
                                        : qrCodeCard(context),
                                    const SizedBox(height: 24),
                                    Text(
                                      textAlign: TextAlign.center,
                                      controller.isShowNameCard.value
                                          ? localized(shareContactCard)
                                          : localized(addFriendInstantly),
                                      style: jxTextStyle.textStyleBold16(
                                          fontWeight: MFontWeight.bold6.value),
                                    ),
                                    Text(
                                      textAlign: TextAlign.center,
                                      controller.isShowNameCard.value
                                          ? localized(scanTheQrCodeToFindMe)
                                          : localized(
                                              makeNewFriendWithQuickScan),
                                      style: jxTextStyle.textStyle16(
                                          color: JXColors.secondaryTextBlack),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () => controller.switchQrCode(),
                                      child: OpacityEffect(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.swap_horiz_sharp,
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              localized(switchText),
                                              style:
                                                  jxTextStyle.textStyleBold16(
                                                      color: accentColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -40,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: JXColors.bgTertiaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: CustomAvatar(
                                  size: 80,
                                  uid: controller.user.uid,
                                  headMin: Config().messageMin,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Visibility(
                              visible: !objectMgr.loginMgr.isDesktop,
                              child: GestureDetector(
                                onTap: () {
                                  if (objectMgr.callMgr.getCurrentState() ==
                                      CallState.Idle) {
                                    controller.routeToScanner();
                                  } else {
                                    Toast.showToast(
                                        localized(toastEndCallFirst));
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: OverlayEffect(
                                    overlayColor: JXColors.primaryTextBlack
                                        .withOpacity(0.4),
                                    radius: const BorderRadius.vertical(
                                      top: Radius.circular(100),
                                      bottom: Radius.circular(100),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/svgs/scan_button_icon.svg',
                                      width: 56,
                                      height: 56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.isShowNameCard.value,
                              child: GestureDetector(
                                onTap: () => controller.downloadQR(
                                  DownloadQRNameCard(
                                      user: controller.user,
                                      data: controller.nameCardData.value),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: OverlayEffect(
                                    overlayColor: JXColors.primaryTextBlack
                                        .withOpacity(0.4),
                                    radius: const BorderRadius.vertical(
                                      top: Radius.circular(100),
                                      bottom: Radius.circular(100),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/svgs/download_button_icon.svg',
                                      width: 56,
                                      height: 56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.isShowNameCard.value &&
                                  !objectMgr.loginMgr.isDesktop,
                              child: GestureDetector(
                                onTap: () => controller.shareContact(
                                  DownloadQRNameCard(
                                    user: controller.user,
                                    data: controller.nameCardData.value,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: OverlayEffect(
                                    overlayColor: JXColors.primaryTextBlack
                                        .withOpacity(0.4),
                                    radius: const BorderRadius.vertical(
                                      top: Radius.circular(100),
                                      bottom: Radius.circular(100),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/svgs/share_button_icon.svg',
                                      width: 56,
                                      height: 56,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 桌面端Toolbar
  Widget desktopAppBar() {
    return Visibility(
      visible: objectMgr.loginMgr.isDesktop,
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            bottom: BorderSide(
              color: JXColors.outlineColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          /// 普通界面
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            OpacityEffect(
              child: GestureDetector(
                onTap: () {
                  Get.back(id: 3);
                  Get.find<SettingController>().desktopSettingCurrentRoute = '';
                  Get.find<SettingController>().selectedIndex.value = 101010;
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/svgs/Back.svg',
                        width: 18,
                        height: 18,
                        color: JXColors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localized(buttonBack),
                        style: const TextStyle(
                          fontSize: 13,
                          color: JXColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              localized(userQrcode),
              style: const TextStyle(
                fontSize: 16,
                color: JXColors.black,
              ),
            ),
            const SizedBox(),
          ],
        ),
      ),
    );
  }

  /// 二维码
  Widget qrCodeCard(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        QRCode(
          qrData: controller.qrCodeData.value,
          qrSize: 190,
          roundEdges: false,
          color: qrCodeColor,
        ),
        Visibility(
          visible: controller.isValidQrCode.value,
          child: GestureDetector(
            onTap: () => controller.showDurationOptionPopup(context),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: JXColors.bgTertiaryColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: (controller.durationText.value != '')
                    ? Text(
                        controller.durationText.value,
                        style: jxTextStyle.textStyle16(color: qrCodeColor),
                      )
                    : SvgPicture.asset(
                        'assets/svgs/infinity_icon.svg',
                        width: 24,
                        height: 24,
                      ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !controller.isValidQrCode.value,
          child: Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        Visibility(
          visible: !controller.isValidQrCode.value,
          child: GestureDetector(
            onTap: () => controller.generateQrData(),
            child: Column(
              children: [
                OverlayEffect(
                  overlayColor: JXColors.primaryTextBlack.withOpacity(0.4),
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(100),
                    bottom: Radius.circular(100),
                  ),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: JXColors.secondaryTextBlack,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: JXColors.bgTertiaryColor,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Text(
                  localized(clickToReload),
                  style: jxTextStyle.textStyle14(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
