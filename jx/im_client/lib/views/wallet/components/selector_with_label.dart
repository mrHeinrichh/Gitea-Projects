import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class SelectorWithLabel extends StatelessWidget {
  const SelectorWithLabel({
    super.key,
    required this.label,
    required this.selectedItem,
    this.isShowIcon = true,
    this.onTap,
  });

  final String label;
  final Widget selectedItem;
  final GestureTapCallback? onTap;
  final bool isShowIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: MFontWeight.bold4.value,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40.h,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colorWhite,
              border: Border.all(color: colorBackground6),
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                selectedItem,
                if (isShowIcon) ...{
                  const Spacer(),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: colorTextSecondary,
                  ),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }
}
