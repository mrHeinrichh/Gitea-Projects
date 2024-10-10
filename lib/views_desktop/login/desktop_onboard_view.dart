import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/login/onboarding_controller.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/login/components/company_logo.dart';

class DesktopOnboardView extends StatelessWidget {
  DesktopOnboardView({super.key});
  final OnBoardingController controller = Get.find<OnBoardingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Center(
                child: CompanyLogo(
                  width: 120,
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              Text(
                "Welcome to ${Config().appName}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: MFontWeight.bold5.value,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(
                height: 48,
              ),
              Obx(
                () => controller.isLoading.value
                    ? SizedBox(
                        width: 50,
                        height: 50,
                        child: BallCircleLoading(
                          radius: 20,
                          ballStyle: BallStyle(
                            size: 4,
                            color: themeColor,
                            ballType: BallType.solid,
                            borderWidth: 2,
                            borderColor: themeColor,
                          ),
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => controller.generateDesktopQR(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/svgs/arrow_right_2.svg',
                                width: 20,
                                height: 20,
                                fit: BoxFit.fill,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                localized(homeLetsBegin),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
