import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/wallet/transaction_details_view.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/wallet/transaction_model.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TransactionHistoryCard extends GetView<WalletController> {
  const TransactionHistoryCard({super.key, required this.transactionDetail});
  final TransactionModel transactionDetail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Get.to(
          () => TransactionDetailsView(
            transaction: transactionDetail,
            isAfterWithdraw: false,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
        decoration: BoxDecoration(
          color: colorWhite,
          border: customBorder,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionDetail.displayTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transactionDetail.txTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorTextSecondary,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transactionDetail.txFlag == TxFlag.CREDIT ? '-' : '+'}${double.parse(transactionDetail.amount!).toDoubleFloor(transactionDetail.currencyType!.getDecimalPoint)} ${transactionDetail.currencyType}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: transactionDetail.txFlag == TxFlag.CREDIT
                          ? colorRed
                          : colorGreen,
                      fontWeight: MFontWeight.bold5.value,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transactionDetail.txType?.getWalletType()}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorTextSecondary,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
