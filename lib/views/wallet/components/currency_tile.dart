import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    super.key,
    required this.currency,
    this.needBackIcon = true,
    this.onTap,
    this.isSelected = false,
  });

  final CurrencyModel currency;
  final bool needBackIcon;
  final GestureTapCallback? onTap;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          // border: customBorder,
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              currency.iconPath!,
              width: 30,
              height: 25,
              fit: BoxFit.contain,
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
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: colorBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currency.currencyType}',
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 14,
                            color: colorTextPrimary,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${currency.currencyName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${NumberFormat('#,###.#########').format(double.parse(currency.amount!.toDoubleFloor(currency.getDecimalPoint)))}  ${currency.currencyType}',
                            style: TextStyle(
                              color: colorTextPrimary,
                              fontSize: 14,
                              fontWeight: MFontWeight.bold5.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${NumberFormat('#,###.##').format(currency.convertAmt)} ${currency.convertAmtCurrencyType}',
                            style: const TextStyle(
                              color: colorTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (needBackIcon) ...{
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SvgPicture.asset(
                          'assets/svgs/wallet/arrow_right.svg',
                          width: 20,
                          height: 20,
                          color: Colors.black,
                        ),
                      ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
