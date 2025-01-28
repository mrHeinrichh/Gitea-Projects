// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
// import 'package:jxim_client/im/custom_input/opera_bag_widget/red%20packet/red_packet_controller.dart';
// import 'package:jxim_client/main.dart';
//
// import '../../../../utils/color.dart';
// import '../../../../views/wallet/components/fullscreen_width_button.dart';
// import '../../../../views/wallet/components/selector_with_label.dart';
// import 'red_packet_currency_modal_bottom_sheet.dart';
//
// class LuckyRedPacket extends GetWidget<RedPacketController> {
//   const LuckyRedPacket({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder(
//         init: controller,
//         builder: (_) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: JXColors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//             ),
//             child: SingleChildScrollView(
//               // reverse:
//               //     MediaQuery.of(context).viewInsets.bottom > 0 ? true : false,
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(20.0),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         bottom:
//                             BorderSide(width: 1, color: Colors.grey.shade200),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           flex: 1,
//                           child: GestureDetector(
//                             onTap: () {
//                               // controller.pageController.jumpToPage(0);
//                             },
//                             child: const Text('Cancel'),
//                           ),
//                         ),
//                         const Expanded(
//                           flex: 2,
//                           child: Text(
//                             'Lucky Red Packet',
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                         Expanded(
//                           flex: 1,
//                           child: Container(),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(20.0),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                                 width: 1, color: Colors.grey.shade200),
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(2),
//                                   decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border:
//                                           Border.all(color: JXColors.darkGrey)),
//                                   child: const Icon(
//                                     Icons.question_mark,
//                                     size: 12,
//                                     color: JXColors.darkGrey,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Flexible(
//                                   child: Text(
//                                     'Random amount distributed among the total quantity '
//                                     'indicated. All red packets should be claimed within '
//                                     '24 hours. Unclaimed amount will be refunded back to '
//                                     'your account',
//                                     style: TextStyle(
//                                       fontSize: 10.sp,
//                                       color: JXColors.darkGrey,
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: SelectorWithLabel(
//                                     label: 'Select Currency',
//                                     selectedItem: Row(
//                                       children: [
//                                         if (controller.selectedCurrency.value
//                                                 .iconPath !=
//                                             null) ...{
//                                           Padding(
//                                             padding: const EdgeInsets.all(5),
//                                             child: Image.network(controller
//                                                 .selectedCurrency
//                                                 .value
//                                                 .iconPath!),
//                                           ),
//                                           SizedBox(
//                                             width: 5.w,
//                                           ),
//                                           Text(
//                                               '${controller.selectedCurrency.value.currencyName}')
//                                         }
//                                       ],
//                                     ),
//                                     onTap: () async {
//                                       final data = await showModalBottomSheet(
//                                         shape: const RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.only(
//                                             topLeft: Radius.circular(20),
//                                             topRight: Radius.circular(20),
//                                           ),
//                                         ),
//                                         context: context,
//                                         builder: (context) {
//                                           return const RedPacketCurrencyModalBottomSheet();
//                                         },
//                                       );
//
//                                       if (data != null)
//                                         controller.selectSelectedCurrency(data);
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 20),
//                                 Expanded(
//                                   child: SelectorWithLabel(
//                                     isShowIcon: false,
//                                     label: 'Quantity',
//                                     selectedItem: Expanded(
//                                       child: TextField(
//                                         controller:
//                                             controller.quantityController,
//                                         keyboardType: const TextInputType
//                                             .numberWithOptions(),
//                                         textInputAction: TextInputAction.done,
//                                         // controller: controller.amountController,
//                                         style: TextStyle(fontSize: 15.sp),
//                                         decoration: const InputDecoration(
//                                           isDense: true,
//                                           hintText: '0',
//                                           border: InputBorder.none,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 20),
//                             Text(
//                               'Total Amount',
//                               style: TextStyle(
//                                 fontSize: 16.sp,
//                                 fontWeight:MFontWeight.bold4.value,
//                                 color: JXColors.darkGrey,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   flex: 2,
//                                   child: TextField(
//                                     keyboardType:
//                                         const TextInputType.numberWithOptions(
//                                       decimal: true,
//                                     ),
//                                     textInputAction: TextInputAction.done,
//                                     controller: controller.amountController,
//                                     style: TextStyle(fontSize: 15.sp),
//                                     onChanged: controller.calculateGasFee,
//
//                                     // readOnly: controller.isEnableAmountTextField(),
//                                     decoration: InputDecoration(
//                                       constraints:
//                                           const BoxConstraints(maxHeight: 40),
//                                       contentPadding:
//                                           const EdgeInsets.symmetric(
//                                               horizontal: 20, vertical: 0),
//                                       isDense: true,
//                                       hintText: '0',
//                                       suffixIcon: Container(
//                                         width: 20.w,
//                                         alignment: Alignment.centerRight,
//                                         padding:
//                                             const EdgeInsets.only(right: 10),
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             // controller.makeMaxAmount();
//                                           },
//                                           child: const Text(
//                                             'MAX',
//                                             style: TextStyle(
//                                                 color: JXColors.indigo),
//                                           ),
//                                         ),
//                                       ),
//                                       // fillColor: Color(0xFFFCFCFC),
//                                       border: const OutlineInputBorder(
//                                         borderSide: BorderSide(
//                                             color: JXColors.lightGrey),
//                                         borderRadius: BorderRadius.all(
//                                           Radius.circular(10),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const Padding(
//                                   padding:
//                                       EdgeInsets.symmetric(horizontal: 20.0),
//                                   child: Text('='),
//                                 ),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Approximately',
//                                         style: TextStyle(
//                                           fontSize: 10.sp,
//                                           fontWeight:MFontWeight.bold4.value,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                       Text(
//                                         'CNY ${controller.approximatelyAmount.toStringAsFixed(2)}',
//                                         style: TextStyle(
//                                           fontSize: 16.sp,
//                                           fontWeight: MFontWeight.bold5.value,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               'Maximum Transfer: ${controller.maxTransfer.toStringAsFixed(4)}',
//                               style: TextStyle(
//                                 fontSize: 10.sp,
//                                 fontWeight:MFontWeight.bold4.value,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0, vertical: 10),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                                 width: 4, color: Colors.grey.shade200),
//                           ),
//                         ),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 'Total Transfer',
//                                 style: TextStyle(
//                                   fontSize: 16.sp,
//                                   fontWeight:MFontWeight.bold4.value,
//                                   color: JXColors.indigo,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       if (controller.selectedCurrency.value
//                                               .iconPath !=
//                                           null)
//                                         Image.network(
//                                           controller
//                                               .selectedCurrency.value.iconPath!,
//                                           width: 25.w,
//                                         ),
//                                       const SizedBox(width: 10),
//                                       Flexible(
//                                         child: Text(
//                                           '${controller.totalTransferCrypto.toStringAsFixed(5)}',
//                                           style: TextStyle(
//                                             fontSize: 16.sp,
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Text(
//                                     '',
//                                     style: TextStyle(
//                                       fontSize: 16.sp,
//                                       fontWeight: MFontWeight.bold5.value,
//                                     ),
//                                   ),
//                                   Text(
//                                     'Approximately',
//                                     style: TextStyle(
//                                       fontSize: 10.sp,
//                                       fontWeight:MFontWeight.bold4.value,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0, vertical: 10),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                                 width: 4, color: Colors.grey.shade200),
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Wishes',
//                               style: TextStyle(
//                                 fontSize: 16.sp,
//                                 fontWeight:MFontWeight.bold4.value,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             TextField(
//                               controller: controller.commentController,
//                               maxLines: null,
//                               decoration: const InputDecoration(
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(10),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       FullScreenWidthButton(
//                         title: 'Transfer',
//                         onTap: () {
//                           controller.navigateToConfirm();
//                         },
//                       ),
//                       SizedBox(
//                         height: MediaQuery.of(context).viewInsets.bottom,
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           );
//         });
//   }
// }
