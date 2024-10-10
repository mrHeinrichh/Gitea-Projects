import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';

class PasscodeIntroView extends StatelessWidget {
  late final PasscodeController controller;

  PasscodeIntroView({super.key}) {
    controller = Get.find<PasscodeController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(security),
        isBackButton: false,
        leading: CustomLeadingIcon(
          buttonOnPressed: () {
            if (objectMgr.loginMgr.isDesktop) {
              Get.back(id: 3);
            } else {
              Get.back();
            }
          },
          // childIcon: 'assets/svgs/close_icon.svg',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(
          top: 40,
          bottom: 28,
          left: 20,
          right: 20,
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/security_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localized(walletPasscodeText),
                    style: jxTextStyle.textStyleBold16(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localized(securityPasscodeSubContent),
                    style: jxTextStyle.textStyle14(color: colorTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(
                                Icons.circle,
                                color: colorTextSecondary,
                                size: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localized(securityPasscodeSubContent1),
                                style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(
                                Icons.circle,
                                color: colorTextSecondary,
                                size: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localized(securityPasscodeSubContent2),
                                style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(
                                Icons.circle,
                                color: colorTextSecondary,
                                size: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localized(securityPasscodeSubContent3),
                                style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              localized(byClickingContinue),
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: localized(buttonOk),
              callBack: () {
                if (connectivityMgr.connectivityResult ==
                    ConnectivityResult.none) {
                  showWarningToast(
                    localized(connectionFailedPleaseCheckTheNetwork),
                  );
                } else {
                  /// close current view
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    SystemNavigator.pop();
                  }
                  controller.navigateToSetupPasscodeView();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
