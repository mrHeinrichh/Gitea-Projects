import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';

import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    Key? key,
    required this.textEditingController,
    this.trailingWidget = const SizedBox(),
    this.focusNode,
    this.onChanged,
  }) : super(key: key);

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
      cursorColor: accentColor,
      controller: textEditingController,
      textAlignVertical: TextAlignVertical.center,
      style: jxTextStyle.textStyle16(),
      decoration: InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: localized(loginEmailHint),
        hintStyle: jxTextStyle.textStyle16(color: JXColors.supportingTextBlack),
        suffixIcon: trailingWidget,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
