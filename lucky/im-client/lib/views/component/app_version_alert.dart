import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';

import '../../home/component/custom_divider.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import 'click_effect_button.dart';

class AppVersionAlert extends StatelessWidget {
  const AppVersionAlert({
    Key? key,
    required this.isForce,
    required this.version,
    required this.description,
    this.installCallback,
    this.downloadPackageCallback,
  }) : super(key: key);

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
          horizontal: MediaQuery.of(context).size.width * 0.15),
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
                Text(
                  localized(versionUpdates),
                  style: jxTextStyle
                      .textStyleBold17(fontWeight: MFontWeight.bold6.value)
                      .copyWith(letterSpacing: -0.4),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    localized(newVersionReleasedInstallNow, params: [version]),
                    style: jxTextStyle.textStyle12(),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                              color: JXColors.secondaryTextBlack),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Text(
                              description,
                              style: jxTextStyle.textStyle12(
                                color: JXColors.secondaryTextBlack,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: !Platform.isIOS,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: localized(userCanAlso),
                        style: jxTextStyle
                            .textStyle12(color: JXColors.secondaryTextBlack)
                            .copyWith(fontFamily: appFontfamily),
                        children: [
                          TextSpan(
                            text: localized(downloadThePackage),
                            style: jxTextStyle.textStyle12(color: accentColor),
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
                          style: jxTextStyle.textStyle17(color: accentColor),
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
                  color: JXColors.outlineColor, // Adjust the color as needed
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
                            color: accentColor,
                            fontWeight: MFontWeight.bold6.value),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
