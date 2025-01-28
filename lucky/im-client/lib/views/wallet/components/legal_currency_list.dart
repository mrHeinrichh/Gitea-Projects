import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../../utils/toast.dart';
import 'currency_tile.dart';

class LegalCurrencyList extends GetWidget<WalletController> {
  const LegalCurrencyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
        init: controller,
        builder: (_) {
          return Container(
            child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: controller.legalCurrencyList.length,
              itemBuilder: (BuildContext context, int index) {
                final CurrencyModel currency =
                    controller.legalCurrencyList[index];
                return CurrencyTile(
                  currency: currency,
                  onTap: () {
                    if (currency.enableFlag) {
                      // Get.toNamed(RouteName.cryptoView);
                      //跳轉到法幣貨幣列表
                      imMiniAppManager.goToCurrencyDetailsPage(
                        context,
                        currencyType: currency.currencyType,
                      );
                    } else {
                      Toast.showToast(localized(homeToBeContinue));
                    }
                  },
                );
              },
            ),
          );
        });
  }
}
