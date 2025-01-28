import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/controller/add_address_controller.dart';

import '../../utils/theme/text_styles.dart';

class AddAddressSelectCryptoView extends GetView<AddAddressController> {
  const AddAddressSelectCryptoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PrimaryAppBar(
          title: localized(walletCryptocurrency),
        ),
        body: Container(
          child: ListView.builder(
            itemCount: controller.cryptoCurrencyList.length,
            itemBuilder: (BuildContext context, int index) {
              final CurrencyModel model = controller.cryptoCurrencyList[index];
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  controller.selectNewCurrencyModel(model);
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Image.network(model.iconPath!, width: 32.0, height: 32.0),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                                color: JXColors.lightGrey,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                model.currencyType!,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                              ),
                              Text(
                                model.currencyName!,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ));
  }
}
