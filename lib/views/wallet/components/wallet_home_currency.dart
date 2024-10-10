import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_item.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';

class WalletHomeCurrency extends GetView<WalletController> {
  const WalletHomeCurrency({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Column(
          children: [
            RemainAmount(
              amount: controller.totalCryptoMoney.toString().cFormat(),
              currency: controller.cryptoCurrencyList.isNotEmpty
                  ? (controller.cryptoCurrencyList[0].currencyType).toString()
                  : 'USD',
            ),
            WalletHomeItem(
              title: localized(walletFlexibleAccess),
              leftTxt: localized(withdrawAvailableAmount),
              leftTxtColor: colorRedPacketLucky,
              leftAmount: controller.cryptoAvailCurrency != null &&
                      controller.cryptoAvailCurrency?.amount != 0
                  ? '${controller.cryptoAvailCurrency?.amount?.toString().cFormat()}'
                  : '0.00',
              rightTxt: localized(walletYesterdayProfits),
              rightAmount: controller.cryptoAvailCurrency != null
                  ? ((double.tryParse(
                              controller.cryptoAvailCurrency!.lastDayIn!) ??
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
                              controller.cryptoBoxCurrency!.lastDayIn!) ??
                          0)
                      .toString()
                      .cFormat())
                  : '0.00',
            ),
            ImGap.vGap16,
            PrimaryButton(
              fontSize: 16,
              bgColor: themeColor,
              title: localized(walletFundTransfer),
              width: double.infinity,
              onPressed: () {
                Get.toNamed(
                  RouteName.fundTransferView,
                  arguments: {
                    'currencyType': controller.cryptoCurrencyList.isNotEmpty
                        ? (controller.cryptoCurrencyList[0].currencyType)
                            .toString()
                        : 'USD',
                  },
                )?.then((value) {
                  controller.initWallet();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
