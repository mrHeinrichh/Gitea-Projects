import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/email_text_field.dart';

class AddEmailPage extends GetView<UserBioController> {
  const AddEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserBioController>();
    controller.phoneController.clear();

    return Scaffold(
      backgroundColor: ImColor.systemBg,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(emailAddress),
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
        trailing: [
          Obx(
            () => Visibility(
              visible: !controller.invalidEmail.value,
              child: GestureDetector(
                onTap: () async {
                  await controller.addEmailRequestOTP();
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  child: Text(
                    localized(buttonDone),
                    style: TextStyle(
                      fontWeight: MFontWeight.bold4.value,
                      fontSize: 17,
                      inherit: true,
                      height: 1.25,
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// phone prefix
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// phone number
                Container(
                  decoration: const BoxDecoration(
                    color: colorSurface,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: EmailTextField(
                      textEditingController: controller.emailController,
                      onChanged: (email) => controller.verifyEmail(email),
                    ),
                  ),
                ),
              ],
            ),

            /// error text
            Obx(
              () => Visibility(
                visible: controller.existingEmail.value,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    localized(homeEmailUsed),
                    style: jxTextStyle.normalSmallText(color: colorRed),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                localized(otpSentEmail),
                style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
