import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/login/components/company_logo.dart';
import 'package:jxim_client/views/login/onboarding_controller.dart';

class OnBoardingView extends StatelessWidget {
  OnBoardingView({super.key});

  final OnBoardingController controller = Get.find<OnBoardingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 113,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: CompanyLogo(
                width: 150,
                radius: 32,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                Config().appName,
                textAlign: TextAlign.center,
                style: jxTextStyle.titleLargeText(
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ),
            Text(
              localized(getReadyToChat),
              textAlign: TextAlign.center,
              style: jxTextStyle.titleSmallText(),
            ),
            const Spacer(),
            Obx(
              () => CustomButton(
                height: 48,
                isLoading: controller.isLoading.value,
                text: localized(homeLetsBegin),
                callBack: () => Get.toNamed(RouteName.login),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
