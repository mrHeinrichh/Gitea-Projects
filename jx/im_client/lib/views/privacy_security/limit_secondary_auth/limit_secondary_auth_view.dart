import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_controller.dart';

class LimitSecondaryAuthView extends GetView<LimitSecondaryAuthController> {
  const LimitSecondaryAuthView({super.key});

  Widget subtitle({required String title, double pBottom = 0.0}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: pBottom).w,
      child: Text(title,
          style: jxTextStyle.normalSmallText(
            color: colorTextLevelTwo,
          )),
    );
  }

  Widget dailyLimitWidget(String limit, String cap) {
    ///add parameter for cny usdt amount
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SettingItem(
            paddingVerticalMobile: 8,
            withEffect: false,
            title: localized(dailyTransferLimit),
            withArrow: false,
            rightTitle: limit,
          ),
          SettingItem(
            paddingVerticalMobile: 8,
            withEffect: false,
            title: localized(dailyUsed),
            withArrow: false,
            withBorder: false,
            rightTitle: cap,
          ),
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
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        title: localized(limitSecondaryAuth),
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 24,
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
            CustomButton(
              text: localized(modificationLimit),
              callBack: () {
                if (objectMgr.loginMgr.isDesktop) {
                  Get.toNamed(RouteName.modifyLimitView, id: 3);
                } else {
                  Get.toNamed(RouteName.modifyLimitView);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
