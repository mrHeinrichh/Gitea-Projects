import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/private_key_setting/private_key_setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class PrivateKeySettingView extends GetView<PrivateKeySettingController> {
  const PrivateKeySettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(managePrivateKeyTitle),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: Text(
                  localized(keyPasswordBackUp),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
                ),
              ),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(
                  () => SettingItem(
                    onTap: () => controller.changeOrSetupPassword(),
                    title: localized(privateKeyPassword),
                    rightTitle: controller.hasEncryptedPrivateKey.value != ''
                        ? localized(homeChange)
                        : localized(notSet),
                    withBorder: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  localized(afterSettingTheKey),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: Text(
                  localized(managePrivateKeyTitle),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
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
                      onTap: () => controller.getPrivateKeyQrCode(),
                      title: localized(viewPrivateKey),
                      withBorder: true,
                    ),
                    SettingItem(
                      onTap: () => controller.resetPassword(),
                      title: localized(encryptionResetKey),
                      withBorder: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  localized(keepSecureDontShare),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
                ),
              ),
            ],
          )),
    );
  }
}
