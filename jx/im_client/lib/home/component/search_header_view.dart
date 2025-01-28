import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class SearchHeaderView extends StatelessWidget {
  final String title;

  const SearchHeaderView({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
      width: double.infinity,
      color: colorBackground,
      child: Text(
        title,
        style: jxTextStyle.normalSmallText(color: colorTextSecondary),
      ),
    );
  }
}
