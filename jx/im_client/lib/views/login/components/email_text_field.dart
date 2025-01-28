import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    super.key,
    required this.textEditingController,
    this.trailingWidget,
    this.focusNode,
    this.style,
    this.hintStyle,
    this.onChanged,
  });

  final TextEditingController textEditingController;
  final Widget? trailingWidget;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      contextMenuBuilder: im.textMenuBar,
      focusNode: focusNode,
      autofocus: true,
      cursorColor: themeColor,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1),
      controller: textEditingController,
      style: style ?? jxTextStyle.headerText(),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: localized(loginEmailHint),
        hintStyle:
            hintStyle ?? jxTextStyle.headerText(color: colorTextPlaceholder),
        suffixIcon: trailingWidget,
      ),
      onChanged: onChanged,
    );
  }
}
