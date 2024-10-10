import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/views/login/components/company_logo.dart';
import 'package:jxim_client/views/login/onboarding_controller.dart';

class OnBoardingView extends StatelessWidget {
  OnBoardingView({super.key});

  final OnBoardingController controller = Get.find<OnBoardingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(
            right: 16,
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 260, bottom: 16),
                child: CompanyLogo(
                  width: 153,
                  radius: 64.0 / 256 * 153,
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      Config().appName,
                      textAlign: TextAlign.center,
                      style: jxTextStyle.textStyle28(),
                    ),
                  ),
                  Text(
                    localized(getReadyToChat),
                    textAlign: TextAlign.center,
                    style: jxTextStyle.textStyleBold16(),
                  ),
                ],
              ),
              const Spacer(),
              Obx(
                () => SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 50,
                            height: 50,
                            child: BallCircleLoading(
                              radius: 20,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 1,
                                borderColor: themeColor,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => Get.toNamed(RouteName.login),
                            child: ForegroundOverlayEffect(
                              radius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                                bottom: Radius.circular(12),
                              ),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      localized(homeLetsBegin),
                                      style: jxTextStyle.textStyleBold14(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    SvgPicture.asset(
                                      'assets/svgs/arrow_right_2.svg',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.fill,
                                    ),
                                  ],
                                ),
                              ),
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
}
