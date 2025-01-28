import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/setting/network_diagnose/network_diagnose_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:lottie/lottie.dart';

class NetworkDiagnoseView extends GetView<NetworkDiagnoseController> {
  const NetworkDiagnoseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(networkDiagnose),
        onPressedBackBtn: () {
          if (objectMgr.loginMgr.isDesktop) {
            Get.back(id: 3);
            Get.find<SettingController>().desktopSettingCurrentRoute = '';
            Get.find<SettingController>().selectedIndex.value = 101010;
          } else {
            Get.back();
          }
        },
      ),
      body: Stack(
        children: [
          Obx(() {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: controller.diagnoseStatus.value > 0
                  ? 0
                  : MediaQuery.of(context).size.height / 6,
              left: 0,
              right: 0,
              bottom: 0,
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: _getNetworkStatusIcon(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getDiagnoseProcessTitle(),
                      style: jxTextStyle.titleText(
                        fontWeight: MFontWeight.bold5.value,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getDiagnoseProcessSubtitle(),
                      style: jxTextStyle.headerText(
                        color: colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  AnimatedSize(
                    curve: Curves.easeInOut,
                    alignment: Alignment.bottomCenter,
                    duration: const Duration(milliseconds: 300),
                    child: controller.diagnoseStatus.value == 3
                        ? _getDiagnoseFailDescription()
                        : const SizedBox(),
                  ),

                  Obx(() {
                    return Visibility(
                      visible: controller.diagnoseStatus.value != 0,
                      child: _getUserInfo(),
                    );
                  }),

                  if (controller.diagnoseStatus.value != 0)
                    _getDiagnoseProcessList(context),

                  if (controller.diagnoseStatus.value == 0)
                    _getDiagnoseButton(context),

                  /// Description
                  Visibility(
                    visible: controller.diagnoseStatus.value == 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        localized(diagnoseTips),
                        style: jxTextStyle.headerText(
                          color: colorTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              return Visibility(
                visible: controller.diagnoseStatus.value != 0,
                child: Container(
                    color: colorBackground,
                    padding: EdgeInsets.only(
                        top: 12,
                        bottom: MediaQuery.of(context).viewPadding.bottom + 16),
                    child: _getDiagnoseButton(context)),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _getNetworkStatusIcon() {
    switch (controller.diagnoseStatus.value) {
      case 0:
        return const Icon(
          Icons.network_check,
          size: 84,
        );
      case 1:
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            themeColor,
            BlendMode.srcIn,
          ),
          child: Lottie.asset(
            "assets/lottie/animate-loading-v2.json",
            height: 84,
            width: 84,
          ),
        );
      case 2:
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            colorGreen,
            BlendMode.srcIn,
          ),
          child: Lottie.asset(
            "assets/lottie/animate_success.json",
            height: 84,
            width: 84,
            repeat: false,
            controller: controller.successAnimationController,
          ),
        );
      case 3:
      case 4:
        controller.errorAnimationController.forward(from: 0);
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            colorOrange,
            BlendMode.srcIn,
          ),
          child: Lottie.asset(
            "assets/lottie/animate-error.json",
            height: 84,
            width: 84,
            repeat: false,
            controller: controller.errorAnimationController,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  String _getDiagnoseProcessTitle() {
    switch (controller.diagnoseStatus.value) {
      case 0:
        return localized(networkDiagnose);
      case 1:
        return localized(diagnosing);
      case 2:
        return localized(diagnoseComplete);
      case 3:
        return controller.networkWarningTitle.value;
      case 4:
      default:
        return localized(diagnoseStopped);
    }
  }

  String _getDiagnoseProcessSubtitle() {
    switch (controller.diagnoseStatus.value) {
      case 0:
        return localized(diagnoseNormalSubtitle);
      case 1:
        return localized(diagnosingSubtitle);
      case 2:
        return localized(diagnoseGoodSubtitle);
      case 3:
        return controller.networkWarningSubtitle.value;
      case 4:
      default:
        return localized(diagnoseStopSubtitle);
    }
  }

  Widget _getDiagnoseFailDescription() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(diagnoseRecommendation),
            style: jxTextStyle.headerText(
              color: colorOrange,
              fontWeight: MFontWeight.bold5.value,
            ),
          ),
          _getBulletRecommendation(),
        ],
      ),
    );
  }

  Column _getBulletRecommendation() {
    final List<String> recommendations = _getRecommendationList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map((recommendation) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: jxTextStyle.normalSmallText(),
            ),
            Expanded(
              child: Text(
                recommendation,
                style: jxTextStyle.normalSmallText(),
                softWrap: true,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<String> _getRecommendationList() {
    switch (controller.abnormalTask) {
      case ConnectionTask.connectNetwork:
        return [
          localized(diagnoseRecommendation1),
          localized(diagnoseRecommendation2),
          localized(diagnoseRecommendation3),
        ];
      case ConnectionTask.shieldConnectNetwork:
        return [
          localized(diagnoseRecommendation4),
          localized(diagnoseRecommendation5),
          localized(diagnoseRecommendation6),
        ];
      case ConnectionTask.connectServer:
        return [
          localized(diagnoseRecommendation7),
          localized(diagnoseRecommendation8),
          localized(diagnoseRecommendation9),
        ];
      case ConnectionTask.uploadSpeed:
        if (controller.networkWarningTitle.value ==
            localized(networkWarningTitle4)) {
          return [
            localized(diagnoseRecommendation10),
            localized(diagnoseRecommendation11),
            localized(diagnoseRecommendation12),
          ];
        } else {
          return [
            localized(diagnoseRecommendation13),
          ];
        }
      case ConnectionTask.downloadSpeed:
        if (controller.networkWarningTitle.value ==
            localized(networkWarningTitle6)) {
          return [
            localized(diagnoseRecommendation10),
            localized(diagnoseRecommendation14),
            localized(diagnoseRecommendation12),
          ];
        } else {
          return [
            localized(diagnoseRecommendation13),
          ];
        }
      case null:
        return [''];
    }
  }

  Widget _getUserInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(userInfo),
            style: jxTextStyle.headerText(
              fontWeight: MFontWeight.bold5.value,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: jxTextStyle.normalSmallText(),
              ),
              Expanded(
                child: Text(
                  "${objectMgr.userMgr.mainUser.nickname}, @${objectMgr.userMgr.mainUser.username}",
                  style: jxTextStyle.normalSmallText(),
                  softWrap: true,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: jxTextStyle.normalSmallText(),
              ),
              Expanded(
                child: Obx(() {
                  return Text(
                    "${controller.currentCountry.value}, ${controller.currentIP.value}",
                    style: jxTextStyle.normalSmallText(),
                    softWrap: true,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getDiagnoseProcessList(context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          16, 0, 16, (90 + MediaQuery.of(context).viewPadding.bottom + 16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorSurface,
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: controller.taskStatuses.length,
        itemBuilder: (context, index) {
          final task = controller.taskStatuses[index];
          return Container(
            constraints: const BoxConstraints(
              minHeight: 56,
            ),
            child: Center(
              child: Obx(() {
                return SettingItem(
                  titleWidget: Text(
                    task.name,
                    style: jxTextStyle.headerText(
                      fontWeight: MFontWeight.bold5.value,
                    ),
                  ),
                  subtitle: _taskResult(task),
                  subtitleStyle: jxTextStyle.normalSmallText(
                    color: colorTextSecondary,
                  ),
                  paddingVerticalMobile: 8,
                  rightWidget: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _taskResultIcon(task),
                  ),
                  withArrow: false,
                  withEffect: false,
                  withBorder: index != controller.taskStatuses.length - 1,
                );
              }),
            ),
          );
        },
      ),
    );
  }

  String? _taskResult(NetworkDiagnoseTask task) {
    switch (task.status.value) {
      case ConnectionTaskStatus.processing:
        if (controller.diagnoseStatus.value >= 3) {
          return null;
        }
        return localized(diagnoseTaskProcessing);
      case ConnectionTaskStatus.success:
      case ConnectionTaskStatus.failure:
      default:
        return task.description;
    }
  }

  Widget _taskResultIcon(NetworkDiagnoseTask task) {
    switch (task.status.value) {
      case ConnectionTaskStatus.processing:
        if (controller.diagnoseStatus.value >= 3) {
          return SvgPicture.asset(
            "assets/svgs/network_none.svg",
          );
        }
        return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: themeColor,
          ),
        );
      case ConnectionTaskStatus.success:
        return SvgPicture.asset(
          "assets/svgs/network_check.svg",
        );
      case ConnectionTaskStatus.failure:
        return SvgPicture.asset(
          "assets/svgs/network_error.svg",
        );
      default:
        return const SizedBox();
    }
  }

  Widget _getDiagnoseButton(context) {
    return Obx(() {
      final bool isDiagnosing = controller.isDiagnosing.value;
      final int diagnoseStatus = controller.diagnoseStatus.value;

      final String buttonText = diagnoseStatus == 0
          ? localized(startDiagnoseBtn)
          : isDiagnosing
              ? localized(stopDiagnoseBtn)
              : localized(restartDiagnoseBtn);

      final Color textColor = diagnoseStatus == 0
          ? themeColor
          : isDiagnosing
              ? colorRed
              : colorWhite;

      final Color buttonColor = diagnoseStatus == 0
          ? colorSurface
          : isDiagnosing
              ? colorSurface
              : themeColor;

      return Padding(
        padding: diagnoseStatus == 0
            ? const EdgeInsets.symmetric(vertical: 36, horizontal: 32)
            : const EdgeInsets.symmetric(horizontal: 16),
        child: CustomButton(
          text: buttonText,
          textColor: textColor,
          color: buttonColor,
          callBack: () {
            if (diagnoseStatus == 0) {
              controller.startDiagnose();
            } else if (isDiagnosing) {
              controller.stopDiagnose();
            } else {
              controller.restartDiagnose();
            }
          },
        ),
      );
    });
  }
}
