import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:lottie/lottie.dart';

import '../../utils/color.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../utils/theme/text_styles.dart';
import '../component/new_appbar.dart';
import '../component/no_record_state.dart';
import '../component/offline_state.dart';
import 'components/transaction_history_card.dart';
import 'controller/transaction_controller.dart';

class TransactionHistoryView extends GetView<TransactionController> {
  const TransactionHistoryView({Key? key, this.currencyType}) : super(key: key);
  final String? currencyType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          title: localized(walletTransactionHistory),
        ),
        body: Column(
          children: [
            // Container(
            //   margin: const EdgeInsets.all(16.0),
            //   height: 40.0,
            //   child: Obx(
            //     () => ListView(
            //         padding: EdgeInsets.zero,
            //         scrollDirection: Axis.horizontal,
            //         children: [
            //           GestureDetector(
            //             onTap: () {
            //               controller.selectedTType.value = 'Cryptocurrency';
            //             },
            //             child: Container(
            //               margin: const EdgeInsets.only(right: 8.0),
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 16.0,
            //                 vertical: 12.0,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: controller.selectedTType.value ==
            //                         'Cryptocurrency'
            //                     ? accentColor
            //                     : backgroundColor,
            //                 borderRadius: BorderRadius.circular(1000000),
            //               ),
            //               alignment: Alignment.center,
            //               child: Text(
            //                 'Cryptocurrency',
            //                 style: TextStyle(
            //                   color:
            //                       controller.selectedTType == 'Cryptocurrency'
            //                           ? JXColors.white
            //                           : JXColors.supportingTextBlack,
            //                 ),
            //               ),
            //             ),
            //           ),
            //           GestureDetector(
            //             onTap: () {
            //               controller.selectedTType.value = 'Legal Currency';
            //             },
            //             child: Container(
            //               margin: const EdgeInsets.only(right: 8.0),
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 16.0,
            //                 vertical: 12.0,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: controller.selectedTType.value ==
            //                         'Legal Currency'
            //                     ? accentColor
            //                     : backgroundColor,
            //                 borderRadius: BorderRadius.circular(1000000),
            //               ),
            //               alignment: Alignment.center,
            //               child: Text(
            //                 'Legal Currency',
            //                 style: TextStyle(
            //                   color:
            //                       controller.selectedTType == 'Legal Currency'
            //                           ? JXColors.white
            //                           : JXColors.supportingTextBlack,
            //                 ),
            //               ),
            //             ),
            //           ),
            //           GestureDetector(
            //             onTap: () {
            //               controller.selectedTType.value = 'Red Packet';
            //             },
            //             child: Container(
            //               margin: const EdgeInsets.only(right: 8.0),
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 16.0,
            //                 vertical: 12.0,
            //               ),
            //               decoration: BoxDecoration(
            //                 color:
            //                     controller.selectedTType.value == 'Red Packet'
            //                         ? accentColor
            //                         : backgroundColor,
            //                 borderRadius: BorderRadius.circular(1000000),
            //               ),
            //               alignment: Alignment.center,
            //               child: Text(
            //                 'Red Packet',
            //                 style: TextStyle(
            //                   color: controller.selectedTType == 'Red Packet'
            //                       ? JXColors.white
            //                       : JXColors.supportingTextBlack,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ]),
            //   ),
            // ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: JXColors.lightGrey),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: controller.tabController,
                labelColor: accentColor,
                labelPadding: EdgeInsets.zero,
                unselectedLabelColor: JXColors.darkGrey,
                indicatorColor: JXColors.indigo,
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: accentColor),
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
                      child: Obx(() => controller.isLostNetwork.value
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
                                          // Display loading tile
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
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          // Display transaction history card
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10.0,
                                                      horizontal: 20),
                                                  width: double.infinity,
                                                  decoration:
                                                      const BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: JXColors
                                                            .outlineColor,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    color: JXColors.white,
                                                  ),
                                                  child: Text(
                                                    '${controller.getDateTitle(controller.formattedTransactionMap.keys.elementAt(mapIndex))}',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          MFontWeight.bold4.value,
                                                      color: JXColors.darkGrey,
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
                                                                  mapIndex)]!
                                                      .length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return TransactionHistoryCard(
                                                      transactionDetail: controller
                                                              .formattedTransactionMap[
                                                          controller
                                                              .formattedTransactionMap
                                                              .keys
                                                              .elementAt(
                                                                  mapIndex)]![index],
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
                                              color: accentColor,
                                              ballType: BallType.solid,
                                              borderWidth: 5,
                                              borderColor: accentColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                              : const NoRecordState()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
