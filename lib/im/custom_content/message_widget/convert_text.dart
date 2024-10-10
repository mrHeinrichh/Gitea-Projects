import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

import 'package:jxim_client/views/component/dot_loading_view.dart';

class ConvertTextItem extends StatelessWidget {
  final String convertText;
  final bool? isConverting;
  final double minWidth;
  final bool isSender;
  final GroupTextMessageReadType type;
  final double extraWidth;

  const ConvertTextItem({
    super.key,
    required this.convertText,
    this.isConverting,
    required this.minWidth,
    required this.isSender,
    required this.type,
    required this.extraWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: BoxConstraints(
        maxWidth: minWidth,
        minWidth: minWidth,
      ),
      child: isConverting == true
          ? const SizedBox(
              height: 20,
              width: 20,
              child: DotLoadingView(
                size: 8,
                dotColor: colorTextPrimary,
              ),
            )
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: convertText,
                    style: jxTextStyle.textStyle17(
                      color: colorTextPrimary,
                    ),
                  ),
                  if (type == GroupTextMessageReadType.inlineType)
                    WidgetSpan(child: SizedBox(width: extraWidth))
                ],
              ),
            ),
    );
  }
}
