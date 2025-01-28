import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/recipient_address_tile.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import '../../../utils/color.dart';

class RecipientBottomModal extends GetWidget<WithdrawController> {
  const RecipientBottomModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: MediaQuery.of(context).size.height *
                controller.recipientHeight.value /
                16 +
            MediaQuery.of(context).viewInsets.bottom +
            100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: JXColors.lightGrey),
                ),
              ),
              padding: const EdgeInsets.only(
                  top: 40.0, bottom: 20, left: 20, right: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(localized(buttonCancel)),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Select Address',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: JXColors.lightGrey),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                height: 50,
                child: TextField(
                  contextMenuBuilder: textMenuBar,
                  controller: controller.filterRecipientController,
                  onChanged: controller.filterRecipient,
                  onSubmitted: controller.submitRecipient,
                  decoration: InputDecoration(
                    hintText: localized(hintSearch),
                    hintStyle: const TextStyle(
                      color: JXColors.mutedDarkPurple,
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: JXColors.mutedDarkPurple,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    filled: true,
                    fillColor: offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: dividerColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                  future: controller.getRecipientAddressList(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: controller.filterRecipientAddressList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return RecipientAddressTile(
                            address:
                                controller.filterRecipientAddressList[index],
                            isSelected: controller.withdrawModel.addrID ==
                                controller
                                    .filterRecipientAddressList[index].addrID,
                          );
                        },
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
            ),
            // Expanded(
            //   child: ListView.builder(
            //     padding: EdgeInsets.symmetric(horizontal: 20),
            //     itemCount: controller.cryptoCurrencyList.length,
            //     itemBuilder: (BuildContext context, int index) {
            //       final data = controller.cryptoCurrencyList[index];
            //       return GestureDetector(
            //         onTap: () {
            //           Navigator.pop(context, data);
            //         },
            //         child: CurrencyTile(
            //           url: data.iconPath!,
            //           currency: data.currencyName!,
            //           currencyCode: data.currencyType!,
            //           currencyRate:
            //           '${data.amount?.toStringAsFixed(2)} ${data.currencyType}',
            //           usdRate:
            //           '${data.convertAmt?.toStringAsFixed(2)} ${data.convertAmtCurrencyType}',
            //           needBackIcon: false,
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
