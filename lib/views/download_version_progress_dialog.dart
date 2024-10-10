import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:lottie/lottie.dart';

import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class DownloadVersionProgressDialog extends GetView<HomeController> {
  const DownloadVersionProgressDialog({
    super.key,
    this.downloadPackageCallback,
  });

  final Function()? downloadPackageCallback;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            child: Obx(
              () => Column(
                children: [
                  Lottie.asset(
                    'assets/lottie/updating.json',
                    width: 150,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: controller.apkDownloadProgress.value,
                      color: themeColor,
                      backgroundColor: colorBackground,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${controller.fileSize.value ~/ (1024 * 1024)}MB/${controller.totalFileSize.value ~/ (1024 * 1024)}MB (${((controller.apkDownloadProgress.value * 100).toInt())}%)",
                      style: jxTextStyle.textStyle12(
                        color: colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Visibility(
                    visible: !Platform.isIOS && controller.countdown.value == 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          Text(
                            localized(facingTroubleWhileUpdating),
                            style: jxTextStyle.textStyleBold12(
                              color: colorTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: localized(downloadThePackage),
                              style: jxTextStyle
                                  .textStyle12(color: themeColor)
                                  .copyWith(fontFamily: appFontfamily),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.back();
                                  downloadPackageCallback?.call();
                                },
                              children: [
                                TextSpan(
                                  text: localized(andUpdateManually),
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const CustomDivider(),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.doCancel(),
            child: OverlayEffect(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                ),
                child: Text(
                  localized(buttonCancel),
                  textAlign: TextAlign.center,
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
