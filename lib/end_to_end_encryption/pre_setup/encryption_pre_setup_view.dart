import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/pre_setup/encryption_pre_setup_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class EncryptionPreSetupView extends GetView<EncryptionPreSetupController> {
  const EncryptionPreSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(privateKeyPassword),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/encryption_setup_icon.png',
                width: 88,
                height: 88,
              ),
              const SizedBox(height: 20),
              Text(
                localized(backUpKeyPassword),
                style:
                    jxTextStyle.titleText(fontWeight: MFontWeight.bold5.value),
              ),
              const SizedBox(height: 8),
              Text(
                localized(encPreSetupContent1),
                style: jxTextStyle.headerText(color: colorTextSecondary),
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: localized(setPrivateKeyPassword),
                isBold: true,
                callBack: () => controller.navigateToEncryptionSetupPage(),
              ),
              const SizedBox(height: 36),
              Text(
                localized(encPreSetupContent2),
                style: jxTextStyle.headerText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
