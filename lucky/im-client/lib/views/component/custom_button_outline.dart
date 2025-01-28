import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CustomButtonOutline extends StatelessWidget {
  CustomButtonOutline({
    Key? key,
    required this.text,
    required this.callBack,
    this.textColor,
    this.borderColor,
  }) : super(key: key);
  final String text;
  final Function() callBack;
  Color? textColor;
  Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        callBack();
      },
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 0.0,
        ),
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: borderColor ?? accentColor,
            )),
        child: Text(
          text,
          style: jxTextStyle.textStyle14(
            color: textColor ?? accentColor,
          ),
        ),
      ),
    );
  }
}
