import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        elevation: 0.0,
        titleWidget: Text(
          localized(deleteAccount),
          style: jxTextStyle.appTitleStyle(),
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
              child: Container(
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
                                padding: const EdgeInsets.only(top: 6.0),
                                child: const Icon(
                                  Icons.circle,
                                  color: JXColors.secondaryTextBlack,
                                  size: 4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localized(deletingAnAccountIsAnIrreversibleAction),
                                  style: jxTextStyle.textStyle14(
                                      color: JXColors.secondaryTextBlack),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: const Icon(
                                  Icons.circle,
                                  color: JXColors.secondaryTextBlack,
                                  size: 4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localized(allTheDataAssociatedWithThisAccountWillBeLostForever),
                                  style: jxTextStyle.textStyle14(
                                      color: JXColors.secondaryTextBlack),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Text(
              localized(byClickingBelowDeleteAccount),
              style:
              jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: localized(deletePermanently),
              color: errorColor,
              isBold:false,
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
