import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/wallet/components/currency_tile.dart';

class RedPacketCurrencyModalBottomSheet extends GetWidget<RedPacketController> {
  const RedPacketCurrencyModalBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RedPacketController>(
      init: controller,
      builder: (_) {
        return SizedBox(
          height: 400 + MediaQuery.of(context).viewInsets.bottom,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          localized(buttonCancel),
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        localized(withdrawSelectCryptoCurrency),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: MFontWeight.bold5.value,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: themeColor,
                          unselectedLabelColor: colorTextSecondary,
                          tabs: [
                            Tab(
                              text: localized(walletCryptoCurrency),
                            ),
                            Tab(
                              text: localized(walletLegalCurrency),
                            ),
                          ],
                        ),
                        Flexible(
                          child: TabBarView(
                            physics: const BouncingScrollPhysics(),
                            dragStartBehavior: DragStartBehavior.down,
                            children: [
                              ListView.builder(
                                itemCount:
                                    controller.filterCryptoCurrencyList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final CurrencyModel data = controller
                                      .filterCryptoCurrencyList[index];
                                  if (controller.configMap
                                      .containsKey(data.currencyType)) {
                                    return GestureDetector(
                                      onTap: () {
                                        if (data.enableFlag) {
                                          Navigator.pop(context, data);
                                        } else {
                                          Toast.showToast(
                                            '暂不支持 ${data.currencyName} 币种',
                                          );
                                        }
                                      },
                                      child: CurrencyTile(
                                        currency: data,
                                        needBackIcon: false,
                                        isSelected: controller.selectedCurrency
                                                .value.currencyType ==
                                            data.currencyType,
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                              ListView.builder(
                                itemCount: controller.legalCurrencyList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final CurrencyModel currency =
                                      controller.legalCurrencyList[index];
                                  return CurrencyTile(
                                    currency: currency,
                                    onTap: () {
                                      Toast.showToast(
                                        localized(homeToBeContinue),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
