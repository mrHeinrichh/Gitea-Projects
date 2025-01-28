import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/utils/color.dart';

import '../../../home/component/custom_divider.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../utils/utility.dart';


class AddressCard extends StatelessWidget {
  const AddressCard({
    Key? key,
    required this.address,
    this.isShowQR = true,
    this.showInfo = true,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);
  final AddressModel address;
  final bool isShowQR;
  final bool showInfo;
  final GestureTapCallback? onDelete;
  final GestureTapCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
      decoration: BoxDecoration(
        border: customBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('${address.addrName}',
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),

              GestureDetector(
                onTap: () => copyToClipboard(address.address),
                child: const Icon(
                  Icons.content_copy_rounded,
                  color: JXColors.indigo,
                ),
              ),
              // const SizedBox(width: 20),
              // GestureDetector(
              //   onTap: onEdit,
              //   child: Icon(Icons.edit, color: JXColors.indigo, size: 24.w),
              // ),
              const SizedBox(width: 10),
              // if (isShowQR)
              //   GestureDetector(
              //     onTap: () {
              //       Get.to(() => WalletQRView(
              //             address: address,
              //           ));
              //     },
              //     child: const Icon(
              //       Icons.qr_code_outlined,
              //       color: JXColors.indigo,
              //     ),
              //   ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            '${address.address}',
            style: TextStyle(fontSize: 14.sp, fontWeight: MFontWeight.bold5.value),
          ),
          if (showInfo) ...{
            const SizedBox(height: 15),
            Row(
              children: [
                Visibility(
                  visible: address.rechargeNum >= 6,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(
                      Icons.info,
                      color: JXColors.red,
                      size: 20,
                    ),
                  ),
                ),
                Text(
                  'This address has received incoming transactions ${address.rechargeNum} times,\nwith a total incoming amount of ${address.rechargeAmt} ${address.currencyType}',
                  style:
                      TextStyle(fontSize: 10.sp, fontWeight:MFontWeight.bold4.value),
                ),
              ],
            )
          }
        ],
      ),
    );
  }
}
