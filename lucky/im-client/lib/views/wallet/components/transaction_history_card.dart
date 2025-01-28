import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/views/wallet/transaction_details_view.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../../home/component/custom_divider.dart';
import '../../../object/wallet/transaction_model.dart';
import '../../../utils/color.dart';
import 'package:get/get.dart';
import '../../../../object/wallet/currency_model.dart';
import '../../../utils/theme/text_styles.dart';

class TransactionHistoryCard extends GetView<WalletController> {
  const TransactionHistoryCard({Key? key, required this.transactionDetail})
      : super(key: key);
  final TransactionModel transactionDetail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Get.to(() => TransactionDetailsView(
              transaction: transactionDetail,
              isAfterWithdraw: false,
            ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
        decoration: BoxDecoration(
          color: JXColors.white,
          border: customBorder,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transactionDetail.displayTitle}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:MFontWeight.bold4.value,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transactionDetail.txTime}',
                    style: TextStyle(
                        fontSize: 14,
                        color: JXColors.darkGrey,
                        fontWeight:MFontWeight.bold4.value),
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
                            ? JXColors.red
                            : JXColors.green,
                        fontWeight: MFontWeight.bold5.value),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transactionDetail.txType?.getWalletType()}',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: JXColors.darkGrey,
                        fontWeight:MFontWeight.bold4.value),
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
