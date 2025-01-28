import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_complete_controller.dart';

class DeleteAccountCompleteView
    extends GetView<DeleteAccountCompleteController> {
  const DeleteAccountCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: const PrimaryAppBar(
        bgColor: Colors.transparent,
        title: "",
        leading: SizedBox(),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            bottom: 12,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/delete_account_image.svg',
                      width: 148,
                      height: 148,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localized(accountDeleted),
                      style: jxTextStyle.textStyleBold16(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localized(yourAccountHasBeenDeletedPermanently),
                      style: jxTextStyle.textStyle14(
                        color: colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: localized(buttonOk),
                isBold: false,
                callBack: () {
                  controller.clearData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
