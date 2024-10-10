import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    super.key,
    required this.textEditingController,
    this.trailingWidget = const SizedBox(),
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController textEditingController;
  final Widget? trailingWidget;
  final FocusNode? focusNode;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      contextMenuBuilder: textMenuBar,
      focusNode: focusNode,
      autofocus: true,
      cursorColor: themeColor,
      controller: textEditingController,
      textAlignVertical: TextAlignVertical.center,
      style: jxTextStyle.textStyle16(),
      decoration: InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: localized(loginEmailHint),
        hintStyle: jxTextStyle.textStyle16(color: colorTextSupporting),
        suffixIcon: trailingWidget,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
