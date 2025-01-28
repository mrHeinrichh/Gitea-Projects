import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        elevation: 0.0,
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        titleWidget: Text(
          localized(deleteAccount),
          style: jxTextStyle.appTitleStyle(),
        ),
        onPressedBackBtn: objectMgr.loginMgr.isDesktop ?
            ()=> Get.back(id: 3) : null,
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
                    'assets/svgs/delete_account_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    localized(whatYouShouldKnowBeforeDeletingAccount),
                    style: jxTextStyle.textStyleBold16(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                                localized(
                                  deletingAnAccountIsAnIrreversibleAction,
                                ),
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
                                localized(
                                  allTheDataAssociatedWithThisAccountWillBeLostForever,
                                ),
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
              localized(byClickingBelowDeleteAccount),
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: localized(deletePermanently),
              color: colorRed,
              isBold: false,
              callBack: () {
                controller.showDeleteAccountConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }
}
