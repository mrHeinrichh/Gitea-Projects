import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../../utils/toast.dart';
import '../../../object/wallet/currency_model.dart';
import 'currency_tile.dart';

class CryptoCurrencyList extends GetWidget<WalletController> {
  const CryptoCurrencyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
        init: controller,
        builder: (_) {
          return ListView.builder(
            itemCount: controller.cryptoCurrencyList.length,
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final CurrencyModel currency =
                  controller.cryptoCurrencyList[index];
              return CurrencyTile(
                currency: currency,
                onTap: () {
                  if (currency.enableFlag) {
                    controller.navigateCryptoDetails(index);
                  } else {
                    Toast.showToast('暂不支持 ${currency.currencyName} 币种');
                  }
                },
              );
            },
          );
        });
  }
}
