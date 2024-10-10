import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.originalValue,
    this.convertedValue,
    this.originalValueColor = colorTextPrimary,
    this.showCopy = false,
  });
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
                label,
                style: const TextStyle(
                  color: colorTextSecondary,
                  fontSize: 14,
                ),
              ),
              Expanded(
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
                            originalValue,
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
                  ],
                ),
              ),
            ],
          ),
          if (convertedValue != null) ...{
            const SizedBox(height: 5),
            Text(
              '$convertedValue',
              style: const TextStyle(
                color: colorTextSecondary,
                fontSize: 14,
              ),
            ),
          },
        ],
      ),
    );
  }
}
