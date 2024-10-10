import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/verification/encryption_verification_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/home/setting/setting_item.dart';

class EncryptionVerificationView
    extends GetView<EncryptionVerificationController> {
  const EncryptionVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(keyVerification),
        isBackButton: controller.hasBack.value,
        trailing: [
          if (!controller.hasBack.value)
          GestureDetector(
            onTap: () => controller.onClickSkip(),
            child: OpacityEffect(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(bindSkip),
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                localized(recoverKeyTitle),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SettingItem(
                    onTap: () => controller.scanQrCode(),
                    title: localized(scanQRCodeTitle),
                  ),
                  Obx(
                    () => SettingItem(
                      onTap: () => controller.navigateToPasswordPage(),
                      title: localized(privateKeyPassword),
                      titleColor: controller.encPrivateKey.value == ''
                          ? colorTextSupporting
                          : colorTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
              localized(unableToVerify),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SettingItem(
                    onTap: () => controller.resetPrivateKey(),
                    title: localized(encryptionResetKey),
                    withBorder: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
