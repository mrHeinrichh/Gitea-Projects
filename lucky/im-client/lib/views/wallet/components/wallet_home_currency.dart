import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_item.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../../routes.dart';
import '../../../utils/color.dart';
import '../../../utils/config.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/theme/text_styles.dart';

class WalletHomeCurrency extends GetView<WalletController> {
  WalletHomeCurrency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Column(
          children: [
            RemainAmount(
                amount: controller.totalLegalMoney.toString().cFormat(),
                currency: controller.legalCurrencyList.isNotEmpty
                    ? (controller.legalCurrencyList[0].currencyType).toString() : 'CNY',
            ),
            WalletHomeItem(
                title: localized(walletFlexibleAccess),
                leftTxt: localized(withdrawAvailableAmount),
                leftTxtColor: JXColors.orange,
                leftAmount: controller.legalAvailCurrency != null && controller.legalAvailCurrency?.amount != 0
                    ? '${controller.legalAvailCurrency?.amount?.toString().cFormat()}': '0.00',
                rightTxt: localized(walletYesterdayProfits),
                rightAmount: controller.legalAvailCurrency != null
                    ? ((double.tryParse(controller.legalAvailCurrency!.lastDayIn!) ?? 0).toString().cFormat()) : '0.00',),
            WalletHomeItem(
                title: localized(walletSecureProtection),
                leftTxt: localized(walletSafeDepositBoxBalance),
                leftTxtColor: accentColor,
                leftAmount: controller.legalBoxCurrency != null && controller.legalBoxCurrency?.amount != 0
                    ? '${controller.legalBoxCurrency?.amount?.toString().cFormat()}' : '0.00',
                rightTxt: localized(walletYesterdayIncomingTransfer),
                rightAmount: controller.legalBoxCurrency != null
                    ? ((double.tryParse(controller.legalBoxCurrency!.lastDayIn!) ?? 0).toString().cFormat()) : '0.00',),
            if (Config().isGameEnv) getBobi(context),
            ImGap.vGap16,
            PrimaryButton(
              fontSize: 16,
              bgColor: accentColor,
              title: localized(walletFundTransfer),
              width: double.infinity,
              onPressed: () {
                Get.toNamed(RouteName.fundTransferView, arguments: {
                  'currencyType': controller.legalCurrencyList.isNotEmpty
                      ? (controller.legalCurrencyList[0].currencyType)
                          .toString()
                      : 'CNY',
                })?.then((value) {
                  controller.initWallet();
                });
              },
            ),
          ],
        );
      },
    );
  }

  getBobi(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: JXColors.black20, width: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      commonLocalized(walletExpressWithdrawal),
                      style:
                          jxTextStyle.textStyleBold14(color: JXColors.black48),
                    ),
                    ImGap.hGap(2),
                    // GestureDetector(
                    //   onTap: () {
                    //     Get.toNamed(RouteName.webView, arguments: {
                    //       'title': "货币钱包说明",
                    //       'url': controller.bobiAssetModel!.bobNoticeUrl,
                    //     });
                    //   },
                    //   child: SvgPicture.asset(
                    //     'assets/svgs/wallet/wallet_question_icon.svg',
                    //     width: 19,
                    //     height: 19,
                    //   ),
                    // ),
                  ],
                ),
                controller.bobiAssetModel != null
                    ? Text(
                        '${commonLocalized(commonLastUpdate)} ${controller.getSpecificUpdateTime(controller.bobiAssetModel!.updateTime ?? 0)}',
                        style: jxTextStyle.textStyle12(color: JXColors.black24),
                      )
                    : const SizedBox(),
              ],
            ),
            ImGap.vGap12,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commonLocalized(walletBobiBalance),
                      style: jxTextStyle.textStyle14(color: JXColors.green),
                    ),
                    Row(
                      children: [
                        Text(
                          controller.bobiAssetModel != null &&
                                  (double.tryParse(controller
                                              .bobiAssetModel!.amount!) ??
                                          0) !=
                                      0
                              ? '${double.tryParse(controller.bobiAssetModel!.amount!)?.toStringAsFixed(2).cFormat()}'
                              : '0.00',
                          style: jxTextStyle.textStyleBold16(
                              fontWeight: FontWeight.w600),
                        ),
                        ImGap.hGap4,
                        RotateRefreshWidget(
                          child: SvgPicture.asset(
                            'assets/svgs/wallet/wallet_refresh_icon.svg',
                            width: 19,
                            height: 19,
                          ),
                          onClick: () {
                            //餘額刷新
                            controller.getBobiAmount();
                          },
                        ),
                      ],
                    )
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    //開啟web view
                    String appId = "bobi_shop";
                    imMiniAppManager.initMiniApp(
                      appId,
                      controller.bobiShopUrl,
                    );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                getBobiWebView(appId)));
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      color: JXColors.green,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Center(
                      child: Text(
                        commonLocalized(walletEnterShop),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily_pingfang,
                            height: 1.2),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ));
  }

  //取得波幣商城的web
  getBobiWebView(String appId) {
    return controller.bobiShopView ??= imMiniAppManager.startMiniApp(appId);
  }
}
