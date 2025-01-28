import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/backup_key/encryption_backup_key_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class EncryptionBackupKeyView extends GetView<EncryptionBackupKeyController> {
  const EncryptionBackupKeyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(keyPasswordBackUp),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                localized(backupByPasscode),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                onTap: () => controller.navigateToPreSetupPage(),
                title: localized(privateKeyPassword),
                withBorder: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                localized(afterSettingTheKey),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                localized(viaFileBackup),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                onTap: () => controller.getPrivateKeyQrCode(),
                title: localized(keyQrCode),
                withBorder: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                localized(saveKeyQrInLocal),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
