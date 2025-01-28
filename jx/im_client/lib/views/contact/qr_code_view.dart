import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/components/download_qr_name_card.dart';
import 'package:jxim_client/views/contact/components/name_card_qr.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/home/chat/desktop/desktop_alert_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class QRCodeView extends GetView<QRCodeViewController> {
  const QRCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: objectMgr.loginMgr.isDesktop
          ? PrimaryAppBar(
              title: localized(userQrcode),
              withBottomBorder: false,
              onPressedBackBtn: () {
                Get.back(id: 3);
                Get.find<SettingController>().desktopSettingCurrentRoute = '';
                Get.find<SettingController>().selectedIndex.value = 101010;
              },
            )
          : const PrimaryAppBar(bgColor: Colors.transparent),
      body: Obx(
        () => Container(
          decoration: objectMgr.loginMgr.isDesktop ? const BoxDecoration(
                  color: colorBackground,
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: controller.isShowNameCard.value
                        ? [const Color(0xFFF6FCFF), const Color(0xFFC1E8F9)]
                        : [const Color(0xFFB9FFF5), const Color(0xFF91C2F3)],
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/qr_code_background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                          bottom: 24,
                          top: MediaQuery.paddingOf(context).top +
                              kToolbarHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (objectMgr.loginMgr.isDesktop)
                            const SizedBox(height: 40),
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                child: Container(
                                  width: objectMgr.loginMgr.isDesktop
                                      ? 300
                                      : MediaQuery.sizeOf(context).width * 0.8,
                                  padding: const EdgeInsets.all(24)
                                      .copyWith(top: 48),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: colorTextPrimary.withOpacity(0.06),
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
                                          padding: const EdgeInsets.only(
                                              bottom: 16.0),
                                          child: Text(
                                            "@${controller.user.username}",
                                            style: jxTextStyle.titleSmallText(
                                                fontWeight:
                                                    MFontWeight.bold5.value),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      controller.isShowNameCard.value
                                          ? NameCardQr(
                                              data:
                                                  controller.nameCardData.value,
                                            )
                                          : qrCodeCard(context),
                                      const SizedBox(height: 24),
                                      Text(
                                        textAlign: TextAlign.center,
                                        controller.isShowNameCard.value
                                            ? localized(shareContactCard)
                                            : localized(addFriendInstantly),
                                        style: jxTextStyle.headerText(
                                          fontWeight: MFontWeight.bold5.value,
                                        ),
                                      ),
                                      Text(
                                        textAlign: TextAlign.center,
                                        controller.isShowNameCard.value
                                            ? localized(scanTheQrCodeToFindMe)
                                            : localized(
                                                makeNewFriendWithQuickScan,
                                              ),
                                        style: jxTextStyle.headerText(
                                          color: colorTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      GestureDetector(
                                        onTap: () => controller.switchQrCode(),
                                        child: OpacityEffect(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                      'assets/svgs/left_right_arrow.svg',
                                                      color: themeColor,
                                                    ),
                                              const SizedBox(width: 4),
                                              Text(
                                                controller.isShowNameCard.value
                                                    ? localized(
                                                        addFriendInstantly,
                                                      )
                                                    : localized(
                                                        shareContactCard),
                                                style: jxTextStyle.headerText(
                                                  color: themeColor,
                                                  fontWeight:
                                                      MFontWeight.bold5.value,
                                                ),
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
                                      color: colorTextPrimary.withOpacity(0.06),
                                      width: 1,
                                    ),
                                  ),
                                  child: CustomAvatar.user(
                                    controller.user,
                                    size: 80,
                                    headMin: Config().headMin,
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
                                        localized(toastEndCallFirst),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: OpacityEffect(
                                      opacity: 0.4,
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
                                visible: controller.isShowNameCard.value ||
                                    objectMgr.loginMgr.isDesktop,
                                child: GestureDetector(
                                  onTap: () => controller.downloadQR(
                                    DownloadQRNameCard(
                                      user: controller.user,
                                      data: controller.nameCardData.value,
                                    ),
                                    controller.user.uid,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: OpacityEffect(
                                      opacity: 0.4,
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
                                  onTap: () => controller.downloadQR(
                                    DownloadQRNameCard(
                                        user: controller.user,
                                        data: controller.nameCardData.value),
                                    controller.user.uid,
                                    isShare: true,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: OpacityEffect(
                                      opacity: 0.4,
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
              ),
            ],
          ),
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
          color: colorQrCode,
        ),
        Visibility(
          visible: controller.isValidQrCode.value,
          child: GestureDetector(
            onTapUp: (details) {
              if (objectMgr.loginMgr.isDesktop) {
                desktopGeneralDialog(context,
                    color: Colors.transparent,
                    widgetChild:
                        DesktopQrAlertDialog(offset: details.globalPosition));
              } else {
                controller.showDurationOptionPopup(context);
              }
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorTextPrimary.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: (controller.durationText.value != '')
                        ? Text(
                            controller.durationText.value,
                            style: objectMgr.loginMgr.isDesktop
                                ? const TextStyle(
                                    fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: colorQrCode,
                          ) : jxTextStyle.headerText(color: colorQrCode),
                        )
                        : SvgPicture.asset(
                      'assets/svgs/infinity_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                    SvgPicture.asset(
                      'assets/svgs/arrow_down_icon.svg',
                      color: colorQrCode,
                      width: 12,
                      height: 12,
                    )
                ],
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
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        Visibility(
          visible: controller.durationText.value == '00:00' && !controller.isValidQrCode.value,
          child: GestureDetector(
            onTap: () => controller.generateQrData(),
            child: Column(
              children: [
                OverlayEffect(
                  overlayColor: colorTextPrimary.withOpacity(0.4),
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(100),
                    bottom: Radius.circular(100),
                  ),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: im.ImColor.black60,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CustomImage(
                        'assets/svgs/resend_arrow_only.svg',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
