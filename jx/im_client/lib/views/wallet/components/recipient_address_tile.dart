import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/wallet/address_model.dart';

class RecipientAddressTile extends GetView<WithdrawController> {
  const RecipientAddressTile({
    super.key,
    required this.address,
    this.isSelected = false,
  });

  // final String nickname;
  // final String address;
  final AddressModel address;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.selectRecipient(address);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        decoration: BoxDecoration(
          border: customBorder,
          color: isSelected ? Colors.purple.withOpacity(0.3) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.addrName),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(address.address)),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => copyToClipboard(address.address),
                  child: const Icon(Icons.content_copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
