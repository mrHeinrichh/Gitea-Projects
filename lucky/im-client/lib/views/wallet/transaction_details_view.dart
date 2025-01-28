import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import '../../object/wallet/transaction_model.dart';
import '../../routes.dart';
import '../../utils/color.dart';

import 'package:get/get.dart';

import '../../utils/theme/text_styles.dart';
import 'confirm_withdraw_view.dart';

class TransactionDetailsView extends StatelessWidget {
  const TransactionDetailsView({
    Key? key,
    required this.transaction,
    this.isAfterWithdraw = true,
  }) : super(key: key);
  final TransactionModel transaction;
  final bool isAfterWithdraw;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (isAfterWithdraw) {
          Get.until((route) => Get.currentRoute == RouteName.cryptoView);
          return Future.value(true);
        }
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          title: localized(transactionDetails),
          onPressedBackBtn: () {
            if (isAfterWithdraw) {
              Get.until((route) => Get.currentRoute == RouteName.cryptoView);
            } else {
              Get.back();
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SvgPicture.asset(
                    'assets/svgs/wallet/${transaction.txStatus == 'SUCCEEDED' ? 'confirm_check' : 'pending_status'}.svg',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${transaction.txType?.getWalletType(isFull: true)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:MFontWeight.bold4.value,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transaction.txFlag == TxFlag.CREDIT ? '-' : ''}${(double.parse(transaction.amount!).toDoubleFloor(transaction.currencyType!.getDecimalPoint))}',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: MFontWeight.bold5.value,
                      color: transaction.txFlag == TxFlag.CREDIT
                          ? JXColors.black
                          : JXColors.green),
                ),
                const SizedBox(height: 4),

                /// TODO::Status
                Text(
                  '${transaction.status}',
                  style: TextStyle(
                    color: transaction.txStatus == 'SUCCEEDED'
                        ? JXColors.green
                        : JXColors.brightOrange,
                    fontSize: 14,
                    fontWeight:MFontWeight.bold4.value,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: JXColors.white,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        SummaryRow(
                          label: localized(time),
                          originalValue: '${transaction.txTime}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            thickness: 1,
                          ),
                        ),
                        // SummaryRow(
                        //   label: 'Complete Time',
                        //   originalValue: '${transaction.txTime}',
                        // ),
                        // const Padding(
                        //   padding: EdgeInsets.symmetric(horizontal: 16),
                        //   child: Divider(
                        //     thickness: 1,
                        //   ),
                        // ),
                        SummaryRow(
                          label: localized(type),
                          originalValue:
                              '${transaction.txType?.getWalletType()}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            thickness: 1,
                          ),
                        ),
                        SummaryRow(
                          label: localized(transactionNumber),
                          originalValue: '${transaction.txID}',
                          showCopy: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: JXColors.white,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        SummaryRow(
                          label: transaction.senderDetailTitle,
                          originalValue: '${transaction.senderDetail}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            thickness: 1,
                          ),
                        ),
                        SummaryRow(
                          label: transaction.recipientDetailTitle,
                          originalValue: '${transaction.recipientDetail}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            thickness: 1,
                          ),
                        ),
                        SummaryRow(
                          label: localized(comments),
                          originalValue:
                              '${transaction.isRefund ? transaction.desc : transaction.remark}',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: JXColors.white,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        if (transaction.fee != '0') ...{
                          SummaryRow(
                            label: localized(amountTransfer),
                            originalValue:
                                '${(double.parse(transaction.amount!) - double.parse(transaction.fee!)).toDoubleFloor(transaction.currencyType!.getDecimalPoint)}',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              thickness: 1,
                            ),
                          ),
                          SummaryRow(
                            label: localized(estimatedGasFee),
                            originalValue:
                                '${double.parse(transaction.fee!).toDoubleFloor(transaction.currencyType!.getDecimalPoint)}',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              thickness: 1,
                            ),
                          ),
                        },
                        SummaryRow(
                          label: localized(totalWithParam, params: [""]),
                          originalValue:
                              '${double.parse(transaction.amount!).toDoubleFloor(transaction.currencyType!.getDecimalPoint)} ',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Container(
                //   width: double.infinity,
                //   padding:
                //       const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                //   child: Container(
                //     decoration: BoxDecoration(
                //       color: JXColors.white,
                //       borderRadius: BorderRadius.circular(
                //         12,
                //       ),
                //     ),
                //     child: const Padding(
                //       padding: EdgeInsets.all(16.0),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           Text(
                //             'Need help with your order?',
                //             style: TextStyle(
                //               color: JXColors.darkGrey,
                //               fontSize: 12,
                //             ),
                //           ),
                //           SizedBox(width: 4),
                //           Text(
                //             'Customer Service',
                //             style: TextStyle(
                //               color: JXColors.indigo,
                //               fontSize: 12,
                //             ),
                //           ),
                //           Icon(
                //             Icons.arrow_forward_ios,
                //             size: 16,
                //             color: JXColors.black,
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                // Visibility(
                //   visible: isAfterWithdraw,
                //   child: FullScreenWidthButton(
                //     title: localized(anotherTransfer),
                //     onTap: () {
                //       Get.until(
                //           (route) => Get.currentRoute == RouteName.walletView);
                //     },
                //   ),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
