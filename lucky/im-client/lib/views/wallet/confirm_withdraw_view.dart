import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import '../../utils/utility.dart';

//
// class ConfirmWithdrawView extends GetView<WithdrawController> {
//   const ConfirmWithdrawView({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PrimaryAppBar(
//         title: localized(confirmWithdrawal),
//         leading: CustomLeadingIcon(
//           buttonOnPressed: () => Get.back(),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                 child: Text(
//                   localized(transferSummary),
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: MFontWeight.bold5.value,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: JXColors.accentPurple),
//                     borderRadius: BorderRadius.circular(
//                       20,
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       SummaryRow(
//                         label: localized(amount),
//                         originalValue:
//                             '${controller.withdrawModel.amount.toDoubleFloor(controller.withdrawModel.selectedCurrency!.getDecimalPoint)} ${controller.withdrawModel.selectedCurrency?.currencyType}',
//                         convertedValue:
//                             '${controller.cryptoAmountInFiat.value.toDoubleFloor()} USD',
//                       ),
//                       SummaryRow(
//                         label: localized(estimatedGasFee),
//                         originalValue:
//                             '${controller.withdrawModel.gasFee.toDoubleFloor(controller.withdrawModel.selectedCurrency!.getDecimalPoint)} ${controller.withdrawModel.selectedCurrency?.currencyType}',
//                         convertedValue:
//                             '${controller.gasFeeInFiat.toDoubleFloor()} USD',
//                       ),
//                       const Divider(
//                         thickness: 2,
//                         color: JXColors.lightGrey,
//                       ),
//                       SummaryRow(
//                         label: localized(totalTransfer),
//                         originalValue:
//                             '${(controller.withdrawModel.amount + controller.withdrawModel.gasFee).toDoubleFloor(controller.withdrawModel.selectedCurrency!.getDecimalPoint)} ${controller.withdrawModel.selectedCurrency?.currencyType}',
//                         convertedValue:
//                             '${(controller.cryptoAmountInFiat.value + controller.gasFeeInFiat).toDoubleFloor()} USD',
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(width: 4, color: Colors.grey.shade200),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       localized(recipientAddress),
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${controller.withdrawModel.toAddr}',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       '${controller.getAddressOwnerName()}',
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(width: 4, color: Colors.grey.shade200),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       localized(chain),
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${controller.withdrawModel.selectedCurrency?.netType}',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(width: 1, color: Colors.grey.shade200),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       localized(comments),
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${controller.withdrawModel.remark}',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(width: 1, color: Colors.grey.shade200),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       localized(notes),
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       localized(doMakeSureThatTheSelectedChainIsCorrect),
//                       textAlign: TextAlign.justify,
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight:MFontWeight.bold4.value,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               FullScreenWidthButton(
//                 title: localized(buttonConfirm),
//                 onTap: () {
//                   // Get.toNamed(RouteName.passcodeView);
//                   controller.showPasscode(context);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    Key? key,
    required this.label,
    required this.originalValue,
    this.convertedValue,
    this.originalValueColor = JXColors.black,
    this.showCopy = false,
  }) : super(key: key);
  final String label;
  final String originalValue;
  final Color originalValueColor;
  final String? convertedValue;
  final bool showCopy;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label',
                style: const TextStyle(
                  color: JXColors.darkGrey,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 20),
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onLongPress: () {
                              if (showCopy) {
                                copyToClipboard(originalValue);
                              }
                            },
                            child: Text(
                              '${originalValue}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: originalValueColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: showCopy ? 4 : 0),
                      // showCopy
                      //     ? GestureDetector(
                      //         onTap: () {
                      //           Clipboard.setData(
                      //               ClipboardData(text: originalValue));
                      //           Toast.showToast(localized(toastCopySuccess));
                      //         },
                      //         child: SvgPicture.asset(
                      //           'assets/svgs/wallet/Copy.svg',
                      //           width: 20,
                      //           height: 20,
                      //           color: JXColors.black,
                      //         ),
                      //       )
                      //     : const SizedBox(),
                    ],
                  ),
                ),
              )
            ],
          ),
          if (convertedValue != null) ...{
            const SizedBox(height: 5),
            Text(
              '${convertedValue}',
              style: const TextStyle(
                color: JXColors.darkGrey,
                fontSize: 14,
              ),
            )
          }
        ],
      ),
    );
  }
}
