import 'package:flutter/material.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';

class TimeItem extends StatelessWidget {
  const TimeItem({
    super.key,
    required this.createTime,
    required this.showDay,
  });
  final int createTime;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: jxDimension.systemMessageMargin(context),
        padding: jxDimension.systemMessagePadding(),
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          color: colorTextSupporting,
        ),
        child: Text(
          FormatTime.chartTime(
            createTime,
            showDay,
            dateStyle: DateStyle.YYYYMMDD,
          ),
          style: jxTextStyle.textStyleBold12(color: colorWhite),
        ),
      ),
    );
  }
}
