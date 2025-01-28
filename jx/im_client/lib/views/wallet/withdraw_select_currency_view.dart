import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/components/currency_tile.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

class WithdrawSelectCurrencyView extends GetView<WithdrawController> {
  const WithdrawSelectCurrencyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(withdrawSelectCurrency),
      ),
      body: Column(
        children: [
          Container(
            color: colorBackground,
            child: TabBar(
              labelColor: themeColor,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 30),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: themeColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              unselectedLabelColor: colorTextSecondary,
              controller: controller.currencyTypeTabController,
              tabs: [
                Tab(
                  text: localized(walletCryptoCurrency),
                ),
                Tab(
                  text: localized(walletLegalCurrency),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: controller.currencyTypeTabController,
              children: [
                ListView.builder(
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
                        if (connectivityMgr.connectivityResult ==
                            ConnectivityResult.none) {
                          showWarningToast(localized(connectionFailedPleaseCheckTheNetwork));
                        } else {
                          controller.selectSelectedCurrency(currency);
                          Get.back();
                        }
                      },
                    );
                  },
                ),
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: controller.cryptoCurrencyList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CurrencyModel currency =
                        controller.cryptoCurrencyList[index];
                    return CurrencyTile(
                      currency: currency,
                      onTap: () {
                        if (currency.enableFlag) {
                          controller.selectSelectedCurrency(currency);
                        } else {
                          Toast.showToast(localized(homeToBeContinue));
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
