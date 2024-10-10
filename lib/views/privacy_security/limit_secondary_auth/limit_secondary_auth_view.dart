import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class LimitSecondaryAuthView extends GetView<LimitSecondaryAuthController> {
  const LimitSecondaryAuthView({super.key});

  Widget subtitle({required String title, double pBottom = 0.0}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: pBottom).w,
      child: Text(
        title,
        style: jxTextStyle.textStyle13(
          color: colorTextSecondary,
        ),
      ),
    );
  }

  Widget dailyLimitWidget(String limit, String cap) {
    ///add parameter for cny usdt amount

    Widget dailyDetails(title, subtitle, {bool withBorder = false}) =>
        Container(
          height: 44.w,
          decoration: BoxDecoration(
            border: withBorder ? customBorder : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: jxTextStyle.textStyle16(),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: jxTextStyle.textStyle16(
                  color: colorTextSecondary,
                ),
              ),
              ImGap.hGap16,
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.only(left: 16.w),
      child: Column(
        children: [
          dailyDetails(localized(dailyTransferLimit), limit, withBorder: true),
          dailyDetails(localized(dailyUsed), cap),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(limitSecondaryAuth),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 0.0,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ImGap.vGap24,
            // subtitle(
            //   title: '说明：24小时内转出额度超出该限额将进行二次验证，此二次验证额度作为一项安全设定，不会影响您的转出额度。',
            //   pBottom: 24
            // ),
            // subtitle(
            //     title: 'CNY每日限额',
            //     pBottom: 8
            // ),
            // Obx(()=>dailyLimitWidget('${controller.dailyLimitLegal.value.toString().cFormat()} CNY', '${controller.dailyCapLegal.value.toString().cFormat()} CNY')),
            ImGap.vGap24,
            subtitle(
              title: 'USDT ${localized(dailyLimit)}',
              pBottom: 8,
            ),
            Obx(
              () => dailyLimitWidget(
                '${controller.dailyLimitCrypto.value.toString().cFormat()} USDT',
                '${controller.dailyCapCrypto.value.toString().cFormat()} USDT',
              ),
            ),
            ImGap.vGap24,
            PrimaryButton(
              title: localized(modificationLimit),
              bgColor: themeColor,
              onPressed: () {
                Get.toNamed(RouteName.modifyLimitView);
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
