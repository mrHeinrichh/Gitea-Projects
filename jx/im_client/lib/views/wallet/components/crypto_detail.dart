import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/no_record_state.dart';
import 'package:jxim_client/views/component/offline_state.dart';
import 'package:jxim_client/views/wallet/components/crypto_card.dart';
import 'package:jxim_client/views/wallet/components/transaction_history_card.dart';
import 'package:jxim_client/views/wallet/controller/transaction_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:lottie/lottie.dart';

class CryptoDetail extends GetView<WalletController> {
  const CryptoDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: colorBackground,
                border: Border(
                  bottom: BorderSide(color: colorBackground6),
                ),
              ),
              child: TabBar(
                controller: controller.tabController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: themeColor,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                unselectedLabelColor: colorTextSecondary,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: themeColor),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                isScrollable: true,
                tabs: controller.cryptoCurrencyList
                    .map(
                      (CurrencyModel e) => Tab(
                        height: kToolbarHeight + 5,
                        child: Column(
                          children: [
                            Image.network(
                              '${e.iconPath}',
                              width: 30,
                              height: 30,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Color(
                                      0xffF6F6F6,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${e.currencyType}',
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onTap: (index) {},
              ),
            ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: CryptoCard(
                        data: controller.selectedTabCurrency,
                        showHistory: false,
                      ),
                    ),
                  ];
                },
                body: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: TransactionList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: colorBackground6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (connectivityMgr.connectivityResult ==
                            ConnectivityResult.none) {
                          Toast.showToast(
                            localized(
                              connectionFailedPleaseCheckTheNetwork,
                            ),
                          );
                        } else {
                          Get.toNamed(
                            RouteName.withdrawView,
                            arguments: {
                              'data':
                                  controller.selectedTabCurrency.currencyType,
                            },
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorWhite,
                          border: Border.all(color: colorBackground6),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        height: 48,
                        child: Center(
                          child: Text(
                            localized(walletWithdraw),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: MFontWeight.bold5.value,
                              color: colorTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (connectivityMgr.connectivityResult ==
                            ConnectivityResult.none) {
                          Toast.showToast(
                            localized(
                              connectionFailedPleaseCheckTheNetwork,
                            ),
                          );
                        } else {
                          Get.toNamed(RouteName.myAddressView);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: themeColor,
                          border: Border.all(color: colorBackground6),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        height: 48,
                        child: Center(
                          child: Text(
                            localized(walletReceive),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: MFontWeight.bold5.value,
                              color: colorWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class TransactionList extends GetView<TransactionController> {
  TransactionList({super.key}) {
    Get.put(
      TransactionController.create(
        Get.find<WalletController>().selectedTabCurrency.currencyType!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1, color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: controller.tabController,
              labelColor: themeColor,
              unselectedLabelColor: colorTextSecondary,
              indicatorColor: themeColor,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: themeColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              tabs: [
                Tab(
                  text: localized(walletAll),
                ),
                Tab(
                  text: localized(walletIncoming),
                ),
                Tab(
                  text: localized(walletOutgoing),
                ),
                Tab(
                  text: localized(walletPending),
                ),
              ],
            ),
          ),
          Flexible(
            child: Obx(
              () => controller.isLostNetwork.value
                  ? OfflineState(onTap: controller.loadMoreData)
                  : controller.isLoading.value ||
                          controller.formattedTransactionMap.isNotEmpty
                      ? controller.allTransactionList.isNotEmpty
                          ? ListView.builder(
                              itemCount:
                                  controller.formattedTransactionMap.length + 1,
                              controller: controller.allScrollController,
                              itemBuilder:
                                  (BuildContext context, int mapIndex) {
                                if (mapIndex ==
                                    controller.formattedTransactionMap.length) {
                                  // Display loading tile
                                  return Obx(
                                    () => Visibility(
                                      visible: !controller.isNoMoreData.value &&
                                          controller
                                                  .allTransactionList.length >=
                                              100,
                                      child: ListTile(
                                        title: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Text('加载中'),
                                              Lottie.asset(
                                                'assets/icons/loading_spinner_dots.json',
                                                height: 50,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Flexible(
                                      //   fit: FlexFit.loose,
                                      //   child: Container(
                                      //     padding: const EdgeInsets.symmetric(
                                      //         vertical: 10.0, horizontal: 20),
                                      //     width: double.infinity,
                                      //     decoration: BoxDecoration(
                                      //       border: customBorder,
                                      //       color: colorBorder,
                                      //     ),
                                      //     child: Text(
                                      //       '${controller.getDateTitle(controller.formattedTransactionMap.keys.elementAt(mapIndex))}',
                                      //       style: TextStyle(
                                      //         fontSize: 14.sp,
                                      //         fontWeight:MFontWeight.bold4.value,
                                      //         color: colorTextSecondary,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: controller
                                              .formattedTransactionMap[
                                                  controller
                                                      .formattedTransactionMap
                                                      .keys
                                                      .elementAt(mapIndex)]!
                                              .length,
                                          itemBuilder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            return TransactionHistoryCard(
                                              transactionDetail: controller
                                                      .formattedTransactionMap[
                                                  controller
                                                      .formattedTransactionMap
                                                      .keys
                                                      .elementAt(
                                                mapIndex,
                                              )]![index],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.all(21),
                              child: Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: BallCircleLoading(
                                    radius: 20,
                                    ballStyle: BallStyle(
                                      size: 4,
                                      color: themeColor,
                                      ballType: BallType.solid,
                                      borderWidth: 5,
                                      borderColor: themeColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                      : const NoRecordState(),
            ),
          ),
        ],
      ),
    );
  }
}
