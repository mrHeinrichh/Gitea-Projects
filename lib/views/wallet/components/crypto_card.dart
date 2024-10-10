import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class CryptoCard extends StatelessWidget {
  const CryptoCard({super.key, required this.data, this.showHistory = true});
  final CurrencyModel data;
  final bool showHistory;
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
        decoration: BoxDecoration(
          color: colorBackground,
          border: Border(
            bottom: BorderSide(width: 1, color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          children: [
            Image.network(
              data.iconPath!,
              width: 60.w,
              height: 60.h,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(
                      0xffF6F6F6,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              '${data.amount?.toStringAsFixed(2)} ${data.currencyType}',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: MFontWeight.bold5.value,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '≈ ${data.convertAmt?.toStringAsFixed(2)} ${data.convertAmtCurrencyType}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: MFontWeight.bold4.value,
                color: Colors.grey,
              ),
            ),
          ],
        ));
  }
}
