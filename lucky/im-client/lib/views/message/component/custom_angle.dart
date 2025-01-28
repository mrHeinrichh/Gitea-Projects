import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/color.dart';

class CustomAngle extends StatelessWidget {
  final int value;
  final Color bgColor;
  final double fontSize;
  final double height;
  final double borderWidth;
  final Color borderColor;

  const CustomAngle({
    Key? key,
    required this.value,
    this.bgColor = JXColors.red,
    this.fontSize = 12,
    this.height = 18,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Border border = Border.all(
      width: borderWidth,
      color: borderColor,
    );

    try {
      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: border,
        ),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: height),
        child: Text(
          value > 999 ? '999+' : numf(value.toString()),
          style: TextStyle(
            color: JXColors.primaryTextWhite,
            fontSize: fontSize,
          ),
        ),
      );
    } catch (e) {
      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.w),
          border: border,
        ),
        constraints: BoxConstraints(minWidth: 18.w, maxHeight: height.w),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Text(
          value.toString(),
          style: TextStyle(
            color: JXColors.primaryTextWhite,
            fontSize: fontSize,
          ),
        ),
      );
    }
  }
}

/// add , to every thousand
String numf(String n) {
  var numArr = n.split('');
  String revStr = "";
  int thousands = 0;

  for (var i = numArr.length - 1; i >= 0; i--) {
    if (numArr[i].toString() == ".") {
      thousands = 0;
    } else {
      thousands++;
    }

    revStr = revStr + numArr[i].toString();
    if (thousands == 3 && i > 0) {
      thousands = 0;
      revStr = revStr + ',';
    }
  }

  return revStr.split('').reversed.join('');
}
