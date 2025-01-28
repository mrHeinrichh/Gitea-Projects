import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../../utils/color.dart';
import '../../../utils/im_toast/im_gap.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/theme/text_styles.dart';

class WalletHomeItem extends StatelessWidget {
  WalletHomeItem(
      {required this.title,
      required this.leftAmount,
      required this.rightAmount,
      required this.leftTxt,
      required this.rightTxt,
      required this.leftTxtColor,
      Key? key})
      : super(key: key);

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
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: JXColors.black20, width: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: jxTextStyle.textStyleBold14(
                color: JXColors.black48
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
                      style: jxTextStyle.textStyleBold16(
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rightTxt,
                      style: jxTextStyle.textStyle14(
                        color: JXColors.black48,
                      ),
                    ),
                    Text(
                      rightAmount,
                      style: jxTextStyle.textStyleBold16(
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    )
                  ],
                )
              ],
            )
          ],
        ));
  }
}

class RemainAmount extends StatelessWidget {
  RemainAmount({required this.amount, required this.currency, Key? key})
      : super(key: key);

  final String amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${localized(total)}: ',
            style: jxTextStyle.textStyleBold17(
              fontWeight: MFontWeight.bold6.value,
              color: JXColors.black48
            ),
          ),
          Text(
            amount,
            style: jxTextStyle.textStyleBold17(
                fontWeight: MFontWeight.bold6.value,
                color: accentColor
            ),
          ),
          Text(
            ' $currency',
            style: jxTextStyle.textStyleBold17(
                fontWeight: MFontWeight.bold6.value,
                color: JXColors.black24
            )
          )
        ],
      ),
    );
  }
}
