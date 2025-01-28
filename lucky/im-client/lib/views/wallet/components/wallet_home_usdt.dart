import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_item.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../../routes.dart';
import '../../../utils/color.dart';
import '../../../utils/im_toast/im_gap.dart';
import '../../../utils/lang_util.dart';

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
              leftTxtColor: JXColors.orange,
              leftAmount: controller.cryptoAvailCurrency != null &&
                      controller.cryptoAvailCurrency?.amount != 0
                  ? '${controller.cryptoAvailCurrency?.amount?.toString().cFormat()}'
                  : '0.00',
              rightTxt: localized(walletYesterdayProfits),
              rightAmount: controller.cryptoAvailCurrency != null
                  ? ((double.tryParse(
                              controller.cryptoAvailCurrency!.lastDayIn!) ??
                          0)
                  .toString().cFormat())
                  : '0.00',
            ),
            WalletHomeItem(
              title: localized(walletSecureProtection),
              leftTxt: localized(walletSafeDepositBoxBalance),
              leftTxtColor: accentColor,
              leftAmount: controller.cryptoBoxCurrency != null &&
                      controller.cryptoBoxCurrency?.amount != 0
                  ? '${controller.cryptoBoxCurrency?.amount?.toString().cFormat()}'
                  : '0.00',
              rightTxt: localized(walletYesterdayIncomingTransfer),
              rightAmount: controller.cryptoBoxCurrency != null
                  ? ((double.tryParse(
                              controller.cryptoBoxCurrency!.lastDayIn!) ??
                          0)
                      .toString().cFormat())
                  : '0.00',
            ),
            ImGap.vGap16,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                getButton(
                  color: JXColors.orange,
                  txt: localized(receivePayment),
                  onTap: () {
                    Get.toNamed(RouteName.myAddressView);
                  },
                ),
                ImGap.hGap8,
                getButton(
                  color: JXColors.red,
                  txt: localized(walletPayment),
                  onTap: () {
                    Get.toNamed(RouteName.withdrawView,
                        arguments: {'data': 'USDT'});
                  },
                ),
                ImGap.hGap8,
                getButton(
                  color: accentColor,
                  txt: localized(walletFundTransfer),
                  onTap: () {
                    Get.toNamed(RouteName.fundTransferView, arguments: {
                      'currencyType': controller.cryptoCurrencyList.isNotEmpty
                          ? (controller.cryptoCurrencyList[0].currencyType)
                              .toString()
                          : 'USDT',
                    })?.then((value) {
                      controller.initWallet();
                    });
                  },
                ),
              ],
            ),
            chargeBtn(context, rechargeSuccessEvent: () {
              controller.initWallet();
            }),
          ],
        );
      },
    );
  }

  getButton({txt, color, onTap}) {
    return Expanded(
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
              const Size(0, 44)), // 設置按鈕1的最小大小（寬度0，高度50）
        ),
        child: Text(
          txt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            height: 1
          ),
          strutStyle: const StrutStyle(fontSize: 16, height: 1),
        ),
      ),
    );
  }
}
