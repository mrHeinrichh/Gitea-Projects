import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class AppVersionAlert extends StatelessWidget {
  const AppVersionAlert({
    super.key,
    required this.isForce,
    required this.version,
    required this.description,
    this.installCallback,
    this.downloadPackageCallback,
  });

  final bool isForce;
  final String version;
  final String description;
  final Function()? installCallback;
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
      elevation: 1,
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
            child: Column(
              children: [
                //title
                Text(
                  localized(versionUpdates),
                  style: jxTextStyle
                      .textStyleBold17(fontWeight: MFontWeight.bold6.value)
                      .copyWith(letterSpacing: -0.4),
                  textAlign: TextAlign.center,
                ),
                //更新版本
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    localized(newVersionReleasedInstallNow, params: [version]),
                    style: jxTextStyle.textStyle12(),
                    textAlign: TextAlign.center,
                  ),
                ),
                //更新內容
                Visibility(
                  visible: notBlank(description),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "${localized(updateSubtitle)}:",
                          style: jxTextStyle.textStyle12(
                            color: colorTextSecondary,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Text(
                              description,
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                //手動安裝提案
                Visibility(
                  visible: !Platform.isIOS,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: localized(userCanAlso),
                        style: jxTextStyle
                            .textStyle12(color: colorTextSecondary)
                            .copyWith(fontFamily: appFontfamily),
                        children: [
                          TextSpan(
                            text: localized(downloadThePackage),
                            style: jxTextStyle.textStyle12(color: themeColor),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.back();
                                downloadPackageCallback?.call();
                              },
                          ),
                          TextSpan(
                            text: localized(uninstallTheCurrentVersion),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),
          Row(
            children: [
              Visibility(
                visible: !isForce,
                child: Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Navigator.of(context).pop(),
                    child: OverlayEffect(
                      child: Padding(
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
                ),
              ),
              Visibility(
                visible: !isForce,
                child: Container(
                  height: 44,
                  width: 0.5, // Width to make a vertical line
                  color: colorBorder, // Adjust the color as needed
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Get.back();
                    installCallback?.call();
                  },
                  child: OverlayEffect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                      child: Text(
                        localized(install),
                        textAlign: TextAlign.center,
                        style: jxTextStyle.textStyleBold17(
                          color: themeColor,
                          fontWeight: MFontWeight.bold6.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
