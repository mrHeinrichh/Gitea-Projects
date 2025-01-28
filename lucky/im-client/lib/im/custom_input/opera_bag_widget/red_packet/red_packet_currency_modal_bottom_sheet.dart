import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../../../object/wallet/currency_model.dart';
import '../../../../utils/color.dart';
import '../../../../utils/theme/text_styles.dart';
import '../../../../utils/toast.dart';
import '../../../../views/wallet/components/currency_tile.dart';

class RedPacketCurrencyModalBottomSheet extends GetWidget<RedPacketController> {
  const RedPacketCurrencyModalBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RedPacketController>(
        init: controller,
        builder: (_) {
          return Container(
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
                // Container(
                //   margin: const EdgeInsets.symmetric(
                //     horizontal: 16.0,
                //     vertical: 10.0,
                //   ),
                //   height: 50,
                //   child: TextField(
                //     controller: controller.filterCryptoController,
                //     onChanged: controller.filterCrypto,
                //     onSubmitted: controller.submitCrypto,
                //     decoration: InputDecoration(
                //       hintText: localized(search),
                //       hintStyle: const TextStyle(
                //         color: JXColors.mutedDarkPurple,
                //         fontSize: 16,
                //       ),
                //       prefixIcon: const Icon(
                //         Icons.search,
                //         color: JXColors.mutedDarkPurple,
                //         size: 20,
                //       ),
                //       suffixIcon: GestureDetector(
                //         onTap: () {
                //           controller.submitCrypto('');
                //         },
                //         child: const Icon(
                //           Icons.close,
                //         ),
                //       ),
                //       contentPadding: const EdgeInsets.symmetric(
                //         horizontal: 20.0,
                //         vertical: 10.0,
                //       ),
                //       filled: true,
                //       fillColor: offWhite,
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(10.0),
                //         borderSide: const BorderSide(
                //           color: JXColors.lightGrey,
                //           width: 1.0,
                //         ),
                //       ),
                //       enabledBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(10.0),
                //         borderSide: const BorderSide(
                //           color: JXColors.lightGrey,
                //           width: 1.0,
                //         ),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(10.0),
                //         borderSide: const BorderSide(
                //           color: JXColors.lightGrey,
                //           width: 1.0,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                Obx(
                  () => Expanded(
                    child: DefaultTabController(
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: JXColors.indigo,
                            unselectedLabelColor: JXColors.darkGrey,
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
                                  itemCount: controller
                                      .filterCryptoCurrencyList.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
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
                                                '暂不支持 ${data.currencyName} 币种');
                                          }
                                        },
                                        child: CurrencyTile(
                                          currency: data,
                                          needBackIcon: false,
                                          isSelected: controller
                                                  .selectedCurrency
                                                  .value
                                                  .currencyType ==
                                              data.currencyType,
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                ),
                                ListView.builder(
                                  itemCount:
                                      controller.legalCurrencyList.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final CurrencyModel currency =
                                        controller.legalCurrencyList[index];
                                    return CurrencyTile(
                                      currency: currency,
                                      onTap: () {
                                        // Get.toNamed(RouteName.cryptoView);
                                        Toast.showToast(
                                            localized(homeToBeContinue));
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      length: 2,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
