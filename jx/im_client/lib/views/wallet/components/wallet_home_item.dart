import 'package:flutter/material.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class WalletHomeItem extends StatelessWidget {
  const WalletHomeItem({
    required this.title,
    required this.leftAmount,
    required this.rightAmount,
    required this.leftTxt,
    required this.rightTxt,
    required this.leftTxtColor,
    super.key,
  });

  final String title;
  final String leftAmount;
  final String rightAmount;
  final String leftTxt;
  final String rightTxt;
  final Color leftTxtColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: jxTextStyle.textStyleBold14(
              color: colorTextSecondary,
            ),
          ),
          ImGap.vGap12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leftTxt,
                    style: jxTextStyle.textStyle14(color: leftTxtColor),
                  ),
                  Text(
                    leftAmount,
                    style: jxTextStyle.textStyleBold17(
                      fontWeight: MFontWeight.bold6.value,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rightTxt,
                    style: jxTextStyle.textStyle14(
                      color: colorTextSecondary,
                    ),
                  ),
                  Text(
                    rightAmount,
                    style: jxTextStyle.textStyleBold17(
                      fontWeight: MFontWeight.bold6.value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RemainAmount extends StatelessWidget {
  const RemainAmount({required this.amount, required this.currency, super.key});

  final String amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${localized(total)}: ',
            style: jxTextStyle.textStyleBold17(
              fontWeight: MFontWeight.bold6.value,
              color: colorTextSecondary,
            ),
          ),
          Text(
            amount,
            style: jxTextStyle.textStyleBold17(
              fontWeight: MFontWeight.bold6.value,
              color: themeColor,
            ),
          ),
          Text(
            ' $currency',
            style: jxTextStyle.textStyleBold17(
              fontWeight: MFontWeight.bold6.value,
              color: Colors.black.withOpacity(0.24),
            ),
          ),
        ],
      ),
    );
  }
}
