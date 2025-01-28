import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_item.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';

class WalletHomeUsdt extends GetView<WalletController> {
  const WalletHomeUsdt({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RemainAmount(
              amount: controller.totalCryptoMoney.toString().cFormat(),
              currency: controller.cryptoCurrencyList.isNotEmpty
                  ? (controller.cryptoCurrencyList[0].currencyType).toString()
                  : 'USDT',
            ),
            WalletHomeItem(
              title: localized(walletFlexibleAccess),
              leftTxt: localized(withdrawAvailableAmount),
              leftTxtColor: colorOrange,
              leftAmount: controller.cryptoAvailCurrency != null &&
                      controller.cryptoAvailCurrency?.amount != 0
                  ? '${controller.cryptoAvailCurrency?.amount?.toString().cFormat()}'
                  : '0.00',
              rightTxt: localized(walletYesterdayProfits),
              rightAmount: controller.cryptoAvailCurrency != null
                  ? ((double.tryParse(
                            controller.cryptoAvailCurrency!.lastDayIn!,
                          ) ??
                          0)
                      .toString()
                      .cFormat())
                  : '0.00',
            ),
            WalletHomeItem(
              title: localized(walletSecureProtection),
              leftTxt: localized(walletSafeDepositBoxBalance),
              leftTxtColor: themeColor,
              leftAmount: controller.cryptoBoxCurrency != null &&
                      controller.cryptoBoxCurrency?.amount != 0
                  ? '${controller.cryptoBoxCurrency?.amount?.toString().cFormat()}'
                  : '0.00',
              rightTxt: localized(walletYesterdayIncomingTransfer),
              rightAmount: controller.cryptoBoxCurrency != null
                  ? ((double.tryParse(
                            controller.cryptoBoxCurrency!.lastDayIn!,
                          ) ??
                          0)
                      .toString()
                      .cFormat())
                  : '0.00',
            ),
            ImGap.vGap(18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                getButton(
                  fontSize: localized(walletFundTransfer) == "Fund Transfer"
                      ? 12
                      : 14,
                  color: colorRedPacketLucky,
                  txt: localized(walletDeposit),
                  onTap: () {
                    Get.toNamed(RouteName.myAddressView);
                  },
                ),
                ImGap.hGap8,
                getButton(
                  fontSize: localized(walletFundTransfer) == "Fund Transfer"
                      ? 12
                      : 14,
                  color: colorRed,
                  txt: localized(walletWithdraw),
                  onTap: () {
                    Get.toNamed(
                      RouteName.withdrawView,
                      arguments: {'data': 'USDT'},
                    );
                  },
                ),
                ImGap.hGap8,
                getButton(
                  fontSize: localized(walletFundTransfer) == "Fund Transfer"
                      ? 12
                      : 14,
                  color: themeColor,
                  txt: localized(walletFundTransfer),
                  onTap: () {
                    Get.toNamed(
                      RouteName.fundTransferView,
                      arguments: {
                        'currencyType': controller.cryptoCurrencyList.isNotEmpty
                            ? (controller.cryptoCurrencyList[0].currencyType)
                                .toString()
                            : 'USDT',
                        'detailTitle': localized(walletFundTransferShort),
                      },
                    )?.then((value) {
                      controller.initWallet();
                    });
                  },
                ),
              ],
            ),
            // Container(
            //   color: Colors.yellow,
            //   height: 500,
            // )
          ],
        );
      },
    );
  }

  getButton({txt, color, onTap, double fontSize = 17}) {
    return Expanded(
      child: OpacityEffect(
        child: TextButton(
          onPressed: onTap,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(color),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 設置按鈕1的邊框半徑
              ),
            ),
            minimumSize: MaterialStateProperty.all<Size>(
              const Size(114, 48),
            ), // 設置按鈕1的最小大小（寬度0，高度50）
          ),
          child: Text(
            txt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
              height: 1,
            ),
            strutStyle: const StrutStyle(fontSize: 17, height: 1),
          ),
        ),
      ),
    );
  }
}
