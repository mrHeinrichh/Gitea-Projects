import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';


class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    Key? key,
    required this.textEditingController,
    this.onChanged,
    this.trailingWidget = const SizedBox(),
    this.focusNode,
    this.hintText,
  }) : super(key: key);
  final TextEditingController textEditingController;
  final Function(String)? onChanged;
  final Widget? trailingWidget;
  final FocusNode? focusNode;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      contextMenuBuilder: textMenuBar,
      focusNode: focusNode,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        PhoneNumberInputFormatter(),
      ],
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(),
      cursorColor: accentColor,
      controller: textEditingController,
      textAlignVertical: TextAlignVertical.center,
      style:jxTextStyle.textStyle16(),
      // style: TextStyle(
      //   fontSize: 16.sp,
      //   fontWeight:MFontWeight.bold4.value,
      // ),
      decoration: InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: hintText ?? localized(loginPhoneHint),
        hintStyle: jxTextStyle.textStyle16(color: JXColors.supportingTextBlack),
        suffixIcon: trailingWidget,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    int baseOffset = 0;

    String enteredData = newValue.text;
    if ((Platform.isAndroid && oldValue.selection.baseOffset % 5 == 0 ||
            Platform.isIOS && oldValue.selection.baseOffset + 1 % 5 == 0) &&
        newValue.selection.baseOffset % 4 == 0) {
      final removedIndex = newValue.selection.baseOffset;
      final List<String> charList = enteredData.split('');
      charList.removeAt(removedIndex - 1);
      enteredData = charList.join('');
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 4 == 0 && enteredData.length != index) {
        buffer.write(" ");
      }
    }

    baseOffset =
        newValue.selection.baseOffset + (newValue.selection.baseOffset ~/ 4);
    if (newValue.selection.baseOffset % 4 == 0 && baseOffset != 0) {
      baseOffset -= 1;
      if (Platform.isAndroid && oldValue.selection.baseOffset % 5 == 0 ||
          Platform.isIOS && oldValue.selection.baseOffset + 1 % 5 == 0)
        baseOffset -= 1;
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: baseOffset),
    );
  }
}
