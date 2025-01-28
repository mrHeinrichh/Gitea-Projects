

// class RecipientAddressList extends GetWidget<AddressBookController> {
//   const RecipientAddressList({
//     Key? key,
//     this.onDone,
//     this.onCancel,
//     this.onDelete,
//     this.onEdit,
//     this.isShowQR = true,
//   }) : super(key: key);
//   final Function? onDone;
//   final Function? onCancel;
//   final Function? onDelete;
//   final Function? onEdit;
//   final bool isShowQR;
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<AddressBookController>(
//         init: controller,
//         builder: (_) {
//           return controller.recipientAddressList.length == 0
//               ? SliverToBoxAdapter(
//                   child: AddAddressCard(
//                     onTap: () async {
//                       controller.recipientNameController.clear();
//                       controller.recipientAddressController.clear();
//                       final bool result = await showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (BuildContext context) =>
//                             AddRecipientAddressDialog(),
//                       );
//                       if (result) {
//                         controller.addRecipientAddress(
//                             currencyType:
//                                 controller.selectedCurrency.currencyType!,
//                             netType: controller.selectedCurrency.netType!,
//                             addrName: controller.recipientNameController.text,
//                             address:
//                                 controller.recipientAddressController.text);
//                       } else {}
//                     },
//                   ),
//                 )
//               : SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                     (BuildContext _, int index) {
//                       final AddressModel address =
//                           controller.recipientAddressList[index];
//                       return Column(
//                         children: [
//                           AddressCard(
//                             address: address,
//                             isShowQR: false,
//                             showInfo: false,
//                             onDelete: () {
//                               controller.showDeleteActionSheet(context,
//                                   addrID: address.addrID);
//                             },
//                             onEdit: () {
//                               controller.showEditModalPopup(context,
//                                   address: address, index: index);
//                             },
//                           ),
//                           if (index ==
//                               controller.recipientAddressList.length - 1) ...{
//                             AddAddressCard(
//                               onTap: () async {
//                                 controller.recipientNameController.clear();
//                                 controller.recipientAddressController.clear();
//                                 final bool result = await showDialog(
//                                   context: context,
//                                   barrierDismissible: false,
//                                   builder: (BuildContext context) =>
//                                       AddRecipientAddressDialog(),
//                                 );
//                                 if (result) {
//                                   controller.addRecipientAddress(
//                                       currencyType: address.currencyType,
//                                       netType: address.netType,
//                                       addrName: controller
//                                           .recipientNameController.text,
//                                       address: controller
//                                           .recipientAddressController.text);
//                                 } else {}
//                               },
//                             ),
//                           }
//                         ],
//                       );
//                     },
//                     childCount: controller.recipientAddressList.length,
//                   ),
//                 );
//         });
//   }
// }
