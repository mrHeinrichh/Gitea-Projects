import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../utils/config.dart';
import '../component/click_effect_button.dart';
import 'components/download_qr_name_card.dart';
import 'components/name_card_qr.dart';
import 'qr_code_without_scan_button_view_controller.dart';

class QRCodeWithoutScanButtonView
    extends GetView<QRCodeWithoutScanButtonViewController> {
  const QRCodeWithoutScanButtonView({Key? key}) : super(key: key);

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF6FCFF), const Color(0xFFC1E8F9)]),
          image: const DecorationImage(
            image: const AssetImage('assets/images/qr_code_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).viewPadding.top + kToolbarHeight,
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
                              padding: const EdgeInsets.only(
                                top: 48,
                                bottom: 48,
                                left: 48,
                                right: 48,
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
                                  if (controller.user.username.isNotEmpty) ...[
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
                                  NameCardQr(data: controller.qrData),
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
                          GestureDetector(
                            onTap: () => controller.downloadQR(
                              DownloadQRNameCard(
                                user: controller.user,
                                data: controller.qrData,
                              ),
                              context,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: OverlayEffect(
                                overlayColor:
                                    JXColors.primaryTextBlack.withOpacity(0.4),
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
    );
  }
}
