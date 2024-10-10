import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:lottie/lottie.dart';

import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/no_record_state.dart';
import 'package:jxim_client/views/component/offline_state.dart';
import 'package:jxim_client/views/wallet/components/transaction_history_card.dart';
import 'package:jxim_client/views/wallet/controller/transaction_controller.dart';

class TransactionHistoryView extends GetView<TransactionController> {
  const TransactionHistoryView({super.key, this.currencyType});
  final String? currencyType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(walletTransactionHistory),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorBorder),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: controller.tabController,
              labelColor: themeColor,
              labelPadding: EdgeInsets.zero,
              unselectedLabelColor: colorTextSecondary,
              indicatorColor: themeColor,
              isScrollable: false,
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
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Flexible(
                    child: Obx(
                      () => controller.isLostNetwork.value
                          ? OfflineState(
                              onTap: controller.loadMoreData,
                            )
                          : controller.isLoading.value ||
                                  controller.formattedTransactionMap.isNotEmpty
                              ? controller.allTransactionList.isNotEmpty
                                  ? ListView.builder(
                                      itemCount: controller
                                              .formattedTransactionMap.length +
                                          1,
                                      controller:
                                          controller.allScrollController,
                                      itemBuilder:
                                          (BuildContext context, int mapIndex) {
                                        if (mapIndex ==
                                            controller.formattedTransactionMap
                                                .length) {
                                          return Obx(
                                            () => Visibility(
                                              visible: !controller
                                                      .isNoMoreData.value &&
                                                  controller.allTransactionList
                                                          .length >=
                                                      100,
                                              child: ListTile(
                                                title: Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
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
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 10.0,
                                                    horizontal: 20,
                                                  ),
                                                  width: double.infinity,
                                                  decoration:
                                                      const BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: colorBorder,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    color: colorWhite,
                                                  ),
                                                  child: Text(
                                                    controller.getDateTitle(
                                                      controller
                                                          .formattedTransactionMap
                                                          .keys
                                                          .elementAt(
                                                        mapIndex,
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: MFontWeight
                                                          .bold4.value,
                                                      color: colorTextSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
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
                                                              .elementAt(
                                                    mapIndex,
                                                  )]!
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
                                              const SizedBox(height: 10),
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
            ),
          ),
        ],
      ),
    );
  }
}
