import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/qr_code/encryption_qr_code_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code.dart';

class EncryptionQrCodeView extends GetView<EncryptionQrCodeController> {
  const EncryptionQrCodeView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(chatEncryptionPageTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                      ),
                      padding: const EdgeInsets.only(
                        top: 48,
                        bottom: 16,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
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
                          if (controller.user.username.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                "@${controller.user.username}",
                                style: jxTextStyle.textStyleBold24(
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          qrCodeCard(),
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
                        headMin: Config().messageMin,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: (MediaQuery.of(context).viewPadding.bottom != 0)
                  ? MediaQuery.of(context).viewPadding.bottom
                  : 16,
            ),
            child: CustomButton(
              text: localized(addressSaveImage),
              isBold: false,
              callBack: () => controller.downloadQrCode(getQRScreenShot()),
            ),
          ),
        ],
      ),
    );
  }

  Widget getQRScreenShot() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          child: Container(
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
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
                if (controller.user.username.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorTextPrimary.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: CustomAvatar.user(
                          controller.user,
                          size: 60,
                          headMin: Config().messageMin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "@${controller.user.username}",
                        style: jxTextStyle.textStyleBold24(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                qrCodeCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget qrCodeCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        QRCode(
          qrData: controller.qrCodeData.value,
          qrSize: MediaQuery.of(Get.context!).size.width,
          roundEdges: false,
          color: colorQrCode,
        ),
        Image.asset(
          'assets/images/qr_code_logo.png',
          width: 74,
          height: 74,
        ),
      ],
    );
  }
}
